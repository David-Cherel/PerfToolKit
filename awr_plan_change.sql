-- #############################################################################################################
-- Displays all plan hash values and performance kpi's for a SQL_ID 
-- It scans all history from AWR tables
-- Allows to detect performance changes for that SQL, and determine approximatively the time of change
-- #############################################################################################################
-- sql_id := &&1

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : awr_plan_change.sql cm1fyt76dwbkb 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



set lines 180

col execs for 999,999,999
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999
col begin_interval_time for a30
col node for 99999

spool awr_plan_change.log

define sql_id ='&1'


PROMPT ******************************************************************
PROMPT Search for various Exec Plan with the SQL_ID provided
PROMPT ******************************************************************

break on plan_hash_value on startup_time skip 1
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
