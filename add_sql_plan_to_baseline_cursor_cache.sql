
-- #############################################################################################################
-- FILE: add_sql_plan_to_baseline_cursor_cache.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Adds a plan from cursor cache into an existing SQL baseline (SQL handle), then renames the newly loaded plan to SQLID_<SQL_ID>_<PLAN_HASH_VALUE> for easier baseline identification.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID whose cursor cache plan must be loaded (e.g., 'cm1fyt76dwbkb').
-- &2 (plan_hash_value) - NUMBER - Plan hash value to load from cursor cache (e.g., 2481688974).
-- &3 (sql_handle) - STRING - Target SQL baseline handle where the plan is added (e.g., 'SQL_46ada9aadcbb946e').
--
-- OUTPUT DESCRIPTION:
-- Executes DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE and DBMS_SPM.ALTER_SQL_PLAN_BASELINE, prints return codes and created plan details via DBMS_OUTPUT.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I add a cursor cache plan into an existing SQL baseline handle?
-- Did DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE load the requested SQL_ID/plan hash value?
-- How can I rename the newly loaded baseline plan to SQLID_<SQL_ID>_<PLAN_HASH_VALUE>?
-- Did DBMS_SPM.ALTER_SQL_PLAN_BASELINE succeed for the new plan?
-- Which SQL handle and plan hash value were effectively registered in baseline repository?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : add_sql_plan_to_baseline_cursor_cache.sql cm1fyt76dwbkb 2481688974 SQL_46ada9aadcbb946e
-- #############################################################################################################
--
spool add_sql_plan_to_baseline_cursor_cache.log

set feedback off
set sqlblanklines on
set serveroutput on
set verify off

declare


l_plan_name varchar2(40);
l_old_plan_name varchar2(40);
l_sql_handle varchar2(40);
ret binary_integer;
l_sql_id varchar2(13);
l_plan_hash_value number;
major_release varchar2(3);
minor_release varchar2(3);


begin


l_sql_id := '&1';
l_plan_hash_value := to_number('&2');
l_sql_handle := '&3';


ret := dbms_spm.load_plans_from_cursor_cache(
    sql_id=>l_sql_id, 
    plan_hash_value=>l_plan_hash_value,
    sql_handle=>l_sql_handle);

	dbms_output.put_line('dbms_spm.load_plans_from_cursor_cache return code:'||to_char(ret));

-- This statements looks for Baselines create in the last 4 seconds

    select sql_handle, plan_name, 'SQLID_'||l_sql_id||'_'||to_char(l_plan_hash_value)
    into l_sql_handle, l_old_plan_name, l_plan_name
    from dba_sql_plan_baselines spb
    where created > sysdate-(1/24/60/15);


    ret := dbms_spm.alter_sql_plan_baseline(
    sql_handle=>l_sql_handle,
    plan_name=>l_old_plan_name,
    attribute_name=>'PLAN_NAME',
    attribute_value=>l_plan_name);
	dbms_output.put_line('dbms_spm.alter_sql_plan_baseline return code:'||to_char(ret));

    dbms_output.put_line(' ');
    dbms_output.put_line('SQL Plan: '||l_plan_name||' created for SQL Handle: '||l_sql_handle||' and Plan Hash Value: '||l_plan_hash_value );
    dbms_output.put_line(' ');


end;
/

undef sql_id
undef plan_hash_value
undef plan_name


spool off
exit;
