-- #############################################################################################################
-- Find SQL Query in Statspack snapshot 
-- Accept an extract of sql_text
-- Display : sql_id, plan_hash_value, sql_text, avg_pio, avg_lio, avg_etime, execs, rows_proc
-- Allows to show performance KPI's for that SQL_ID and plan_hash_value 
-- #############################################################################################################



set lines 180
col INSTANCE_NUMBER for 99999
col exact_matching_signature format 999999999999999999999999 
col force_matching_signature format 999999999999999999999999 

select /* PTK */ distinct sqpu.INSTANCE_NUMBER,sqltext.SQL_TEXT,  sqpu.sql_id, sqpu.plan_hash_value, summary.EXACT_MATCHING_SIGNATURE , 
summary.FORCE_MATCHING_SIGNATURE 
from stats$sql_plan_usage sqpu,  STATS$SQLTEXT sqltext, STATS$SQL_SUMMARY summary
where sqpu.SQL_ID=sqltext.SQL_ID
and summary.SQL_ID=sqpu.SQL_ID
and upper(sqltext.SQL_TEXT) like upper('%'||'&mysqltext'||'%')
and sqltext.SQL_TEXT not like '%/* PTK */%';

exit;


