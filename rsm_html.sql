-- #############################################################################################################
-- FILE: rsm_html.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Generates an HTML SQL Monitor report for a specified SQL_ID using DBMS_SQL_MONITOR.REPORT_SQL_MONITOR and writes it to a local SQL*Plus spool file.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to report with SQL Monitor (e.g., 'cm1fyt76dwbkb').
--
-- OUTPUT DESCRIPTION:
-- Produces an HTML file named sqlmonitor_<sql_id>.html containing SQL Monitor report details at report_level ALL with event details enabled.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I generate an HTML SQL Monitor report for a SQL_ID?
-- Where is the generated SQL Monitor HTML report stored?
-- How can I include full SQL Monitor event details in the output report?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : rsm_html.sql cm1fyt76dwbkb
-- #############################################################################################################
--
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



