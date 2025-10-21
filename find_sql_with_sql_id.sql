-- #############################################################################################################
-- Find SQL Query in in Shared Pool (Library Cache) and displays KPI's 
-- Accept a sql_id as inputs (prompted)
-- Display : inst_id, SQL_ID, CHILD, IS_OBSOLETE, plan_hash, 	EXECS ,	AVG_ETIME ,	AVG_LIO , avg_cpu_time, SQL_TEXT
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


spool find_sql_with_sql_id.log


PROMPT ****************************************************************************************************************
PROMPT In Library Cache :
PROMPT ****************************************************************************************************************
/* PTK */ select inst_id, sql_id, child_number, IS_OBSOLETE, plan_hash_value plan_hash, executions execs,
(elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_etime,
disk_reads/decode(nvl(executions,0),0,1,executions) avg_pio,
buffer_gets/decode(nvl(executions,0),0,1,executions) avg_lio,
cpu_time/decode(nvl(executions,0),0,1,executions) avg_cpu_time,
sql_text from gv$sql s
where s.sql_id='&sql_id'
order by 1, 2, 3;
PROMPT ****************************************************************************************************************



spool off

exit;

