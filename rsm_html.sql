----------------------------------------------------------------------------------------
--
-- File name:   rsm_html.sql
-- Purpose:     Execute DBMS_SQL_MONITOR.REPORT_SQL_MONITOR function in html mode.
---------------------------------------------------------------------------------------


set pagesize 0 echo off timing off linesize 1000 trimspool on trim on long 2000000 longchunksize 2000000 feedback off
col report for a400
-- accept sid  prompt "Enter value for sid: "
-- accept sql_id  prompt "Enter value for sql_id: "
-- accept sql_exec_id  prompt "Enter value for sql_exec_id: " default '16777216'

define sql_id = '&1' 


spool sqlmonitor_&&sql_id\.html

select
DBMS_SQL_MONITOR.REPORT_SQL_MONITOR(
   sql_id=>'&&sql_id',
   event_detail=>'YES',
   type=>'HTML',
   report_level=>'ALL') 
as report
from dual;

undef sql_id

spool off


exit;



