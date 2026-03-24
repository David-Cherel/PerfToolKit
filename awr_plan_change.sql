
-- #############################################################################################################
-- FILE: awr_plan_change.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Analyzes AWR history for a SQL_ID to identify plan hash changes and performance evolution over time, and lists other SQL_IDs sharing the same force matching signature.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze in AWR history (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
--
-- OUTPUT DESCRIPTION:
-- Three result sets: (1) snapshot-level plan performance history, (2) summary by PLAN_HASH_VALUE (first/last seen, executions, elapsed-time spread), (3) SQL statements with same FORCE_MATCHING_SIGNATURE and their performance metrics.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which plan hash values were used over time for this SQL_ID in AWR?
-- When did plan-related performance change for this SQL_ID?
-- Which plan hash value shows best or worst average elapsed time?
-- How variable is elapsed time per plan hash value?
-- Are there other SQL_IDs with the same force matching signature?
-- What is the performance profile of signature-related SQL statements?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : awr_plan_change.sql cm1fyt76dwbkb
-- #############################################################################################################
--
spool awr_plan_change.log

set pages 9999
set lines 220
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define sql_id ='&1'

begin
  if '&&sql_id' is null then
    raise_application_error(-20001, 'Parameter SQL_ID is mandatory. Usage: @awr_plan_change.sql <SQL_ID>');
  end if;
  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20002, 'Invalid SQL_ID format: &&sql_id');
  end if;
end;
/

col execs for 999,999,999
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999
col begin_interval_time for a22
col node for 99999
col snap_count for 999999
col first_seen for a22
col last_seen for a22
col min_avg_etime for 999,999.99999
col max_avg_etime for 999,999.99999
col etime_spread_pct for 999,990.99



PROMPT ******************************************************************
PROMPT Search for various Exec Plan with the SQL_ID provided
PROMPT ******************************************************************

break on sql_id on plan_hash_value skip 1
/* PTK */ select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value,
nvl(executions_delta,0) execs,
(elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime,
(buffer_gets_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_lio,
(disk_reads_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_pio,
(cpu_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_cpu_time
from CDB_HIST_SQLSTAT S, CDB_HIST_SNAPSHOT SS, V$DATABASE DB
where sql_id = '&sql_id'
and ss.snap_id = S.snap_id
and ss.DBID = S.DBID
and S.CON_DBID=DB.CON_DBID
and ss.instance_number = S.instance_number
order by 1, 2, 3;

PROMPT ******************************************************************
PROMPT Summary by PLAN_HASH_VALUE
PROMPT ******************************************************************

with base as (
  select s.plan_hash_value,
         ss.begin_interval_time,
         nvl(s.executions_delta,0) execs,
         (s.elapsed_time_delta/decode(nvl(s.executions_delta,0),0,1,s.executions_delta))/1000000 avg_etime
  from cdb_hist_sqlstat s
       join cdb_hist_snapshot ss
         on ss.snap_id = s.snap_id
        and ss.dbid = s.dbid
        and ss.instance_number = s.instance_number
       join v$database db
         on s.con_dbid = db.con_dbid
  where s.sql_id = '&&sql_id'
)
select plan_hash_value,
       count(*) snap_count,
       to_char(min(begin_interval_time),'dd-mon-yyyy hh24:mi:ss') first_seen,
       to_char(max(begin_interval_time),'dd-mon-yyyy hh24:mi:ss') last_seen,
       sum(execs) total_execs,
       min(avg_etime) min_avg_etime,
       max(avg_etime) max_avg_etime,
       case when min(avg_etime)=0 then null else ((max(avg_etime)-min(avg_etime))/min(avg_etime))*100 end etime_spread_pct
from base
group by plan_hash_value
order by plan_hash_value;

PROMPT ******************************************************************
PROMPT Search for other SQL_ID with the same Force Matching Signature
PROMPT ******************************************************************

set pages 999
col force_matching_signature format 999999999999999999999999  

select distinct sn.snap_id, sn.instance_number node, sn.begin_interval_time,  sq.sql_id sql_id, sq.FORCE_MATCHING_SIGNATURE force_matching_signature,  sq.plan_hash_value plan_hash, sq.executions_delta execs, 
(sq.elapsed_time_delta/1000000)/decode(nvl(sq.executions_delta,0),0,1,sq.executions_delta) avg_etime,
sq.buffer_gets_delta/decode(nvl(sq.executions_delta,0),0,1,sq.executions_delta) avg_lio,
sq.disk_reads_delta/decode(nvl(sq.executions_delta,0),0,1,sq.executions_delta) avg_pio,
sq.cpu_time_delta/decode(nvl(sq.executions_delta,0),0,1,sq.executions_delta)/1000000 avg_cpu_time,
dbms_lob.substr(txt.sql_text,3999,1) sql_text
from CDB_HIST_SQLSTAT sq, CDB_HIST_SQLSTAT ss, DBA_HIST_SNAPSHOT sn, dba_hist_sqltext txt
where ss.sql_id='&sql_id'
and ss.FORCE_MATCHING_SIGNATURE=sq.FORCE_MATCHING_SIGNATURE
and sq.sql_id=txt.sql_id
and sn.snap_id = sq.snap_id
and sn.DBID = sq.DBID
and sn.instance_number = sq.instance_number
and sq.instance_number = ss.instance_number
order by 1, 2, 3;


spool off
exit;
