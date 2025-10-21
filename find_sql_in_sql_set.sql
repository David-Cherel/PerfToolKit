-- ################################################################################################
-- Find SQL and Plan_hash_value in a SQL Set  
-- It will show all plans if found in SQL Set
-- It accepts SQL_ID ans SQL Set name
-- ################################################################################################
-- SQL_Set_Name := &&1
-- SQL_ID := &&2
--
--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : find_sql_in_sql_set.sql MySQL_Setl ze5tf2gk8vc4
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set feedback off
set sqlblanklines on
set verify off
set serveroutput on
set lines 180

define sql_set_name = '&1'
define sql_id = '&2'





select sql_id, plan_hash_value, executions, elapsed_time, cpu_time, disk_reads, buffer_gets , last_exec_start_time
from TABLE(DBMS_SQLTUNE.select_sqlset ('&&sql_set_name')) where SQL_ID='&&sql_id' order by last_exec_start_time;



exit;
