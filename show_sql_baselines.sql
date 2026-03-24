
-- #############################################################################################################
-- FILE: show_sql_baselines.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays SQL Plan Baselines with SQL handle, plan name, SQL text excerpt, status flags (enabled/accepted/fixed), and last execution timestamp by joining DBA_SQL_PLAN_BASELINES with SQL metadata.
--
-- INPUT PARAMETERS:
-- None - N/A - This script does not require SQL*Plus substitution parameters.
--
-- OUTPUT DESCRIPTION:
-- One result set listing baseline metadata: SQL_HANDLE, PLAN_NAME, SQL_TEXT (truncated), ENABLED, ACCEPTED, FIXED, and LAST_EXECUTED formatted as DD-MON-YY HH24:MI.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL Plan Baselines currently exist in the database?
-- What SQL handle and plan name are associated with each baseline?
-- Is each SQL Plan Baseline enabled?
-- Is each SQL Plan Baseline accepted?
-- Is each SQL Plan Baseline fixed?
-- What is the SQL text associated with each SQL Plan Baseline?
-- When was each SQL Plan Baseline last executed?
-- Which baselines have not been executed recently?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : show_sql_baselines.sql
-- #############################################################################################################
--

spool show_sql_baselines.log

set lines 155
col sql_text for a35 trunc
col last_executed for a28
col enabled for a7
col plan_hash_value for a16
col last_executed for a16
select spb.sql_handle, spb.plan_name, 
dbms_lob.substr(sql_text,3999,1) sql_text,
spb.enabled, spb.accepted, spb.fixed,
to_char(spb.last_executed,'dd-mon-yy HH24:MI') last_executed
from
dba_sql_plan_baselines spb, sqlobj$ so
where spb.signature = so.signature
and spb.plan_name = so.name;

spool off
