
-- #############################################################################################################
-- FILE: plan_change_statspack.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Analyzes Statspack history for a SQL_ID to display performance metrics by instance and plan hash value, helping identify plan-related performance differences.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze in Statspack data (e.g., 'cm1fyt76dwbkb').
--
-- OUTPUT DESCRIPTION:
-- One result set with INSTANCE_NUMBER, SQL_ID, PLAN_HASH_VALUE, executions, average elapsed time, logical I/O, physical I/O, and CPU time aggregated from Statspack tables; output spooled to find_sql_with_sql_id_statspack.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which plan hash values exist for this SQL_ID in Statspack?
-- How do elapsed time and I/O metrics compare across plans for this SQL_ID?
-- Is there evidence of plan-related performance variation in Statspack?
-- What is the execution volume per plan hash value for this SQL_ID?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : plan_change_statspack.sql cm1fyt76dwbkb
-- #############################################################################################################
--

spool plan_change_statspack.log

define sql_id ='&1'
set lines 180

col obsolete format a9
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999

alter session set current_schema=PERFSTAT;



PROMPT ****************************************************************************************************************
PROMPT In Statspack Reports  :
PROMPT ****************************************************************************************************************


/* PTK */ select  sqpu.INSTANCE_NUMBER, sqpu.sql_id, sqpu.plan_hash_value,
sum(nvl(summary.executions,0)) execs,
(sum(ELAPSED_TIME)/decode(sum(nvl(summary.executions,0)),0,1,sum(summary.executions)))/1000000 avg_etime,
(sum(BUFFER_GETS)/decode(sum(nvl(summary.executions,0)),0,1,sum(summary.executions))) avg_lio,
(sum(DISK_READS)/decode(sum(nvl(summary.executions,0)),0,1,sum(summary.executions))) avg_pio,
(sum(CPU_TIME)/decode(sum(nvl(summary.executions,0)),0,1,sum(summary.executions)))/1000000 avg_cpu_time
from STATS$SQL_SUMMARY summary, stats$sql_plan_usage sqpu , stats$snapshot snap
where sqpu.sql_id = '&sql_id'
and sqpu.sql_id = summary.sql_id
and snap.snap_id = summary.snap_id
and snap.snap_id = sqpu.snap_id
and snap.instance_number = summary.instance_number
and snap.instance_number = sqpu.instance_number
and ELAPSED_TIME > 0
group by sqpu.INSTANCE_NUMBER, sqpu.sql_id, sqpu.plan_hash_value;



PROMPT ****************************************************************************************************************




spool off
exit;
