-- #############################################################################################################
-- FILE: drop_sql_set.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Drops a SQL Tuning Set by name using DBMS_SQLSET.DROP_SQLSET and cleans SQL*Plus substitution variables at script end.
--
-- INPUT PARAMETERS:
-- &1 (sql_set_name) - STRING - Name of the SQL Tuning Set to drop (e.g., 'MY_SQL_SET').
--
-- OUTPUT DESCRIPTION:
-- Executes SQL tuning set deletion through PL/SQL block and returns SQL*Plus execution status (success or Oracle error message).
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I drop a SQL Tuning Set by name?
-- Which SQL set name is targeted for deletion?
-- Did DBMS_SQLSET.DROP_SQLSET complete successfully?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : drop_sql_set.sql MY_SQL_SET
-- #############################################################################################################
--
set feedback off
set sqlblanklines on
set verify off
set serveroutput on
set lines 180

define sql_set_name = '&1'



begin

DBMS_SQLSET.DROP_SQLSET (sqlset_name=>'&&sql_set_name');

END;
/

undef sql_set_name


exit;
