-- #############################################################################################################
-- FILE: get_plan_sql_baseline.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays the execution plan stored in SQL Plan Baseline repository for a given baseline PLAN_NAME using DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE.
--
-- INPUT PARAMETERS:
-- &1 (plan_name) - STRING - SQL Plan Baseline plan name to display (e.g., 'SQLID_cm1fyt76dwbkb_2481688974').
--
-- OUTPUT DESCRIPTION:
-- One result set containing formatted plan lines returned by DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE for the specified plan name.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- What execution plan is stored for a specific SQL Plan Baseline plan name?
-- How can I view baseline plan steps from SQL Plan Management repository?
-- Is the requested baseline plan name available for display?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : get_plan_sql_baseline.sql SQLID_cm1fyt76dwbkb_2481688974
-- #############################################################################################################
--
set pages 999
set lines 180
set heading off
set long 10000
set serveroutput on
set verify off

define l_plan_name = '&1'


SELECT * FROM   TABLE(DBMS_XPLAN.display_sql_plan_baseline(plan_name=>'&l_plan_name'));

exit;



