-- ########################################
-- creation SQL baseline from cursor cache
-- ########################################
-- sql_id := &&1
-- plan_hash_value := &&2
-- fixed := &&3
-- enabled := &&4
--
-- WARNING :  This script will scan the latest Baselines created in the last 4 seconds
-- WARNING :  to rename the plan in this format : SQLID_<SQL_ID>_<PLAN_HASH_VALUE>
-- WARNING :  Therefore it is not possible to execute in parallel this SQL File on various sessions
--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : create_sql_baseline_cursor_cache.sql cm1fyt76dwbkb 2481688974 NO YES 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


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

exit;