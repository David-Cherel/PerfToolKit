-- #############################################################################################################
-- Find SQL Query in AWR Reports and displays KPI's 
-- Accept a sql_id as inputs (prompted)
-- Display : snap_id, inst_id, begin_interval_time, SQL_ID, plan_hash_value , EXECS ,	AVG_ETIME ,	AVG_LIO , avg_cpu_time
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


spool find_sql_with_sql_id_awr.log


PROMPT ****************************************************************************************************************
PROMPT In AWR Reports  :
PROMPT ****************************************************************************************************************
/* PTK */ select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value,
nvl(executions_delta,0) execs,
(elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime,
(buffer_gets_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_lio,
(disk_reads_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_pio,
(cpu_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_cpu_time
from CDB_HIST_SQLSTAT S, CDB_HIST_SNAPSHOT SS
where sql_id = '&sql_id'
and ss.snap_id = S.snap_id
and ss.DBID = S.DBID
and ss.instance_number = S.instance_number
order by 1, 2, 3;
PROMPT ****************************************************************************************************************



spool off

exit;

