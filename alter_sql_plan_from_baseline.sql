-- #############################################################################################################
-- FILE: alter_sql_plan_from_baseline.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Alters attributes of an existing SQL Plan Baseline plan (FIXED and ENABLED flags) for a specified SQL handle and plan name using DBMS_SPM.ALTER_SQL_PLAN_BASELINE.
--
-- INPUT PARAMETERS:
-- &1 (sql_handle) - STRING - SQL baseline handle containing the plan to alter (e.g., 'SQL_46ada9aadcbb946e').
-- &2 (plan_name) - STRING - Baseline plan name to alter (e.g., 'SQLID_auy3f5g7da1_2481688974').
-- &3 (fixed) - STRING - Target FIXED attribute value ('YES' or 'NO').
-- &4 (enabled) - STRING - Target ENABLED attribute value ('YES' or 'NO').
--
-- OUTPUT DESCRIPTION:
-- Executes two DBMS_SPM.ALTER_SQL_PLAN_BASELINE calls to update FIXED and ENABLED attributes for the specified plan.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I set a SQL baseline plan as fixed or not fixed?
-- How can I enable or disable a specific SQL baseline plan?
-- Which SQL handle and plan name are being altered?
-- Did attribute updates for FIXED and ENABLED execute successfully?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : alter_sql_plan_from_baseline.sql SQL_46ada9aadcbb946e SQLID_auy3f5g7da1_2481688974 YES YES
-- #############################################################################################################
--
set serveroutput on
set sqlblanklines on
set feedback off
col sql_text for a50 trunc
col last_executed for a28
col enabled for a7
col plan_hash_value for a16
col last_executed for a16
col sql_handle for a24



declare

ret binary_integer;
l_sql_handle varchar2(40);
l_plan_name varchar2(40);
l_fixed varchar2(3);
l_enabled varchar2(3);

BEGIN

l_sql_handle := '&1';
l_plan_name := '&2';
l_fixed := '&3';
l_enabled := '&4';

    ret := dbms_spm.alter_sql_plan_baseline(
    sql_handle=>l_sql_handle,
    plan_name=>l_plan_name,
    attribute_name=>'fixed',
    attribute_value=>l_fixed);

    ret := dbms_spm.alter_sql_plan_baseline(
    sql_handle=>l_sql_handle,
    plan_name=>l_plan_name,
    attribute_name=>'enabled',
    attribute_value=>l_enabled);

end;
/


exit;