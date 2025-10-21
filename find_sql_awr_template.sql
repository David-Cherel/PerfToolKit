-- #############################################################################################################
-- Find SQL Query in AWR and displays KPI's 
-- Accept an extract of sql_text or SQL_ID as inputs
-- Display : sql_id, plan_hash_value, sql_text, avg_pio, avg_lio, avg_etime, execs, rows_proc
-- Allows to show performance KPI's for that SQL_ID and plan_hash_value 
-- #############################################################################################################


set long 32000
set lines 155
col sql_text format a50 
col node for 99999

select /* PTK */ distinct s.instance_number node, dbms_lob.substr(txt.sql_text,3999,1) sql_text,  s.sql_id, s.plan_hash_value
from DBA_HIST_SQLSTAT S,  dba_hist_sqltext txt
where s.sql_id=txt.sql_id
and upper(dbms_lob.substr(txt.sql_text,3999,1)) like upper('%'||'&sqltext'||'%')
and dbms_lob.substr(txt.sql_text,3999,1) not like '%/* PTK */%'
/
