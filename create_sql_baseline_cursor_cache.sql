
-- #############################################################################################################
-- FILE: create_sql_baseline_cursor_cache.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Creates a SQL Plan Baseline from cursor cache for a given SQL_ID and PLAN_HASH_VALUE, optionally sets FIXED and ENABLED flags, then renames the created baseline to SQLID_<SQL_ID>_<PLAN_HASH_VALUE>.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - Target SQL_ID from cursor cache (e.g., 'cm1fyt76dwbkb').
-- &2 (plan_hash_value) - NUMBER - Target execution plan hash value from cursor cache (e.g., 2481688974).
-- &3 (fixed) - STRING - Baseline fixed flag ('YES' or 'NO').
-- &4 (enabled) - STRING - Baseline enabled flag ('YES' or 'NO').
--
-- OUTPUT DESCRIPTION:
-- Creates and renames a SQL baseline, prints DBMS_SPM return codes and creation details through DBMS_OUTPUT, and exits SQL*Plus after undefining substitution variables.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I create a SQL Plan Baseline from cursor cache for a specific SQL_ID?
-- How can I load a specific plan hash value into SQL Plan Management?
-- Can I set FIXED and ENABLED attributes during baseline creation?
-- What return code did DBMS_SPM.LOAD_PLANS_FROM_CURSOR_CACHE produce?
-- What return code did DBMS_SPM.ALTER_SQL_PLAN_BASELINE produce?
-- How can I rename the newly created baseline to SQLID_<SQL_ID>_<PLAN_HASH_VALUE>?
-- Was the SQL Plan Baseline successfully created for the requested SQL_ID and plan hash value?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : create_sql_baseline_cursor_cache.sql cm1fyt76dwbkb 2481688974 YES YES
-- #############################################################################################################
--

spool create_sql_baseline_cursor_cache.log

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
l_fixed varchar2(3);
l_enabled varchar2(3);
major_release varchar2(3);
minor_release varchar2(3);


begin


l_sql_id := '&1';
l_plan_hash_value := to_number('&2');
l_fixed := '&3';
l_enabled := '&4';

ret := dbms_spm.load_plans_from_cursor_cache(
    sql_id=>l_sql_id, 
    plan_hash_value=>l_plan_hash_value,
    fixed=>l_fixed,
    enabled=>l_enabled);

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
undef fixed

spool off
exit;
