
-- #############################################################################################################
-- FILE: find_sql_in_sql_set.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Finds a specific SQL_ID inside a given SQL Tuning Set and lists associated plan hash values and execution metrics from DBMS_SQLTUNE.SELECT_SQLSET.
--
-- INPUT PARAMETERS:
-- &1 (sql_set_name) - STRING - SQL Tuning Set name to search (e.g., 'MY_SQL_SET1').
-- &2 (sql_id) - STRING - SQL_ID to locate in the SQL set (e.g., 'ze5tf2gk8vc4').
--
-- OUTPUT DESCRIPTION:
-- One result set with SQL_ID, PLAN_HASH_VALUE, executions, elapsed_time, cpu_time, disk_reads, buffer_gets, and last_exec_start_time for matching rows in the selected SQL set.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Does a specific SQL_ID exist in a given SQL Tuning Set?
-- Which plan hash values are stored for this SQL_ID in the SQL set?
-- What execution and resource metrics are recorded for this SQL_ID in the SQL set?
-- When was this SQL_ID last executed according to SQL set content?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : find_sql_in_sql_set.sql MY_SQL_SET1 ze5tf2gk8vc4
-- #############################################################################################################
--
spool find_sql_in_sql_set.log

set feedback off
set sqlblanklines on
set verify off
set serveroutput on
set lines 180

define sql_set_name = '&1'
define sql_id = '&2'





select sql_id, plan_hash_value, executions, elapsed_time, cpu_time, disk_reads, buffer_gets , last_exec_start_time
from TABLE(DBMS_SQLTUNE.select_sqlset ('&&sql_set_name')) where SQL_ID='&&sql_id' order by last_exec_start_time;



spool off
exit;
