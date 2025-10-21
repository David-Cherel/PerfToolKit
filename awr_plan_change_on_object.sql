-- #############################################################################################################
-- Displays all plan hash values and performance kpi's for any queries related to a table  
-- It scans all history from AWR tables
-- Allows to detect performance changes for that SQL, and determine approximatively the time of change
-- #############################################################################################################
-- object_name := &&1

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : awr_plan_change_on_object.sql S_LOY_TXN 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



set lines 180
col execs for 999,999,999
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999
col begin_interval_time for a30
col node for 99999

spool awr_plan_change_on_object.log

define object_name ='&1'

break on plan_hash_value on startup_time skip 1
/* PTK */ select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value,
nvl(executions_delta,0) execs,
(elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime,
(buffer_gets_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_lio,
(disk_reads_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_pio,
(cpu_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_cpu_time
from CDB_HIST_SQLSTAT S, CDB_HIST_SNAPSHOT SS, V$DATABASE DB
where sql_id in (select distinct sql_id from cdb_hist_sql_plan sp , V$DATABASE DB where sp.object_name=upper('&object_name') and sp.CON_DBID=DB.CON_DBID)
and ss.snap_id = S.snap_id
and ss.instance_number = S.instance_number
and ss.DBID = S.DBID
and S.CON_DBID=DB.CON_DBID
order by 4,5;

spool off

exit;
