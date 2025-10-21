-- #############################################################################################################
-- Find SQL Query in Statspack Reports and displays KPI's 
-- Accept a sql_id as inputs (prompted)
-- Display : inst_id, SQL_ID, plan_hash_value , EXECS ,	AVG_ETIME ,	AVG_LIO , avg_cpu_time
-- Allows to show performance KPI's for that SQL_ID and plan_hash_value 
-- #############################################################################################################


--
define sql_id ='&1'
set lines 180

col obsolete format a9
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999

alter session set current_schema=PERFSTAT;

spool find_sql_with_sql_id_statspack.log


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

