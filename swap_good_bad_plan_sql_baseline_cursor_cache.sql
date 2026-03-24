
-- #############################################################################################################
-- FILE: swap_good_bad_plan_sql_baseline_cursor_cache.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Replaces a bad execution plan baseline with a good one by loading both from cursor cache, disabling/removing the bad plan, attaching and fixing the good plan, and renaming resulting baseline plan.
--
-- INPUT PARAMETERS:
-- &1 (sql_id_to_fix) - STRING - SQL_ID currently using the bad plan to replace (e.g., '4x6hkyd6r1d08').
-- &2 (bad_plan_hash_value) - NUMBER - Bad plan hash value to baseline then remove (e.g., 3284627250).
-- &3 (sql_id_with_good_plan) - STRING - SQL_ID providing the good plan from cursor cache (e.g., '8j3jyx070mvhd').
-- &4 (good_plan_hash_value) - NUMBER - Good plan hash value to load as fixed/enabled (e.g., 2068817167).
--
-- OUTPUT DESCRIPTION:
-- Performs baseline swap workflow with DBMS_SPM load/alter/drop calls, logs return codes and status messages, and writes execution trace to swap_good_bad_plan_sql_baseline_cursor_cache.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I replace a bad plan baseline with a good plan from cursor cache?
-- Can I load a bad plan as disabled and then attach a good fixed plan to the same SQL handle?
-- Did DBMS_SPM load/alter/drop operations succeed during the plan swap process?
-- What final baseline plan name and SQL handle are produced after the swap?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : swap_good_bad_plan_sql_baseline_cursor_cache.sql 4x6hkyd6r1d08 3284627250 8j3jyx070mvhd 2068817167
-- #############################################################################################################
--

spool swap_good_bad_plan_sql_baseline_cursor_cache.log

set feedback off
set sqlblanklines on
set serveroutput on
set verify off

declare



l_sql_id_to_fix varchar2(13);
l_bad_plan_hash_value number;
l_sql_id_with_good_plan varchar2(13);
l_good_plan_hash_value number;


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


l_sql_id_to_fix := '&1';
l_bad_plan_hash_value := to_number('&2');
l_sql_id_with_good_plan :='&3';
l_good_plan_hash_value := to_number('&4');

ret := dbms_spm.load_plans_from_cursor_cache(
    sql_id=>l_sql_id_to_fix, 
    plan_hash_value=>l_bad_plan_hash_value,
    fixed=>'NO',
    enabled=>'NO');

	dbms_output.put_line('dbms_spm.load_plans_from_cursor_cache return code:'||to_char(ret));

-- This statement looks for Baselines create in the last 4 seconds

    select sql_handle, plan_name, 'SQLID_'||l_sql_id_to_fix||'_'||to_char(l_bad_plan_hash_value)
    into l_sql_handle, l_old_plan_name, l_plan_name
    from dba_sql_plan_baselines spb
    where created > sysdate-(1/24/60/15);

-- This statement changes the SQL plan for the SQL Baselines

    ret := dbms_spm.alter_sql_plan_baseline(
    sql_handle=>l_sql_handle,
    plan_name=>l_old_plan_name,
    attribute_name=>'PLAN_NAME',
    attribute_value=>l_plan_name);
	dbms_output.put_line('dbms_spm.alter_sql_plan_baseline return code:'||to_char(ret));

    dbms_output.put_line(' ');
    dbms_output.put_line('SQL Plan: '||l_plan_name||' created for SQL Handle: '||l_sql_handle||' and Plan Hash Value: '||l_plan_hash_value );
    dbms_output.put_line(' ');


-- Second STEP : 
-- Adding the second Plan with the second SQL_ID 

    dbms_output.put_line(' ');
    dbms_output.put_line('Adding good SQL Plan: '||l_good_plan_hash_value||' in the SQL Handle: '||l_sql_handle||' originating from SQL_ID : '||l_sql_id_with_good_plan );
    dbms_output.put_line(' ');

ret := dbms_spm.load_plans_from_cursor_cache(
    sql_id=>l_sql_id_with_good_plan, 
    plan_hash_value=>l_good_plan_hash_value,
    sql_handle=>l_sql_handle,
	fixed=>'YES',
    enabled=>'YES');

	dbms_output.put_line('Second plan created as FIXED=YES and ENABLED=YES  ,  dbms_spm.load_plans_from_cursor_cache return code:'||to_char(ret));
	
	

-- This statement delete the first SQL plan from the SQL Baseline (with bad exec plan) 


ret := dbms_spm.DROP_SQL_PLAN_BASELINE(plan_name => l_plan_name);

dbms_output.put_line('Status of drop of '||l_plan_name||'   : '||ret);


	-- This statement search for the SQL Baseline with now only one good exec plan

	
    select  plan_name, 'SQLID_'||l_sql_id_to_fix||'_'||to_char(l_good_plan_hash_value)
    into  l_old_plan_name, l_plan_name
    from dba_sql_plan_baselines spb
    where sql_handle=l_sql_handle;


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
