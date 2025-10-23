-- ####################################################################
-- creation SQL baseline from AWR (SQL_ID and plan hash value)
-- ####################################################################
-- sql_id := &&1
-- plan_hash_value := &&2
-- fixed := &&3
-- enabled := &&4

-- WARNING :  This script will scan the latest Baselines created in the last 4 seconds
-- WARNING :  to rename the plan in this format : SQLID_<SQL_ID>_<PLAN_HASH_VALUE>
-- WARNING :  Therefore it is not possible to execute in parallel this SQL File on various sessions
--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : create_sql_baseline_awr.sql cm1fyt76dwbkb 2481688974 YES YES 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$




set serveroutput on
set sqlblanklines on
set feedback off
col sql_text for a50 trunc
col last_executed for a28
col enabled for a7
col plan_hash_value for a16
col last_executed for a16
col sql_handle for a24


--Mettre son SQL_ID ici:
define sql_id = '&1'
--Mettre son Bon plan d'exec performant, trouve dans les rapports AWR ici:
define plan_hash_value = &2
--Donner un nom a sa SQL Baseline ici:
define plan_name = 'X0X0X0X0'
define fixed = '&3'
define enabled = '&4'




exec DBMS_SQLTUNE.CREATE_SQLSET('CREATE_BASELINE_AWR');

declare
baseline_ref_cursor DBMS_SQLTUNE.SQLSET_CURSOR;
min_snap number;
max_snap number;
MYDBID number;
ret binary_integer;
l_sql_handle varchar2(40);
l_plan_name varchar2(40);
l_old_plan_name varchar2(40);

BEGIN

select CON_DBID into MYDBID from v$database;
dbms_output.put_line('MYDBID : '||MYDBID);
select min(snap_id), max(snap_id) into min_snap, max_snap from dba_hist_snapshot where DBID=MYDBID;
dbms_output.put_line('min_snap : '||min_snap);
dbms_output.put_line('max_snap : '||max_snap);

open baseline_ref_cursor for
select VALUE(p) from table(DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY(begin_snap => min_snap, 
			end_snap => max_snap,
			basic_filter => 'sql_id='||CHR(39)||'&&sql_id'||CHR(39)||' and plan_hash_value=&plan_hash_value',
			attribute_list => 'ALL', dbid => MYDBID)) p;

DBMS_SQLTUNE.LOAD_SQLSET('CREATE_BASELINE_AWR', baseline_ref_cursor);

ret := DBMS_SPM.LOAD_PLANS_FROM_SQLSET (
sqlset_name => 'CREATE_BASELINE_AWR',
sqlset_owner => 'SYS',
fixed => '&fixed',
enabled => '&enabled');



-- This statements looks for Baselines created in the last 4 seconds

    select sql_handle, plan_name,
    decode('&&plan_name','X0X0X0X0','SQLID_'||'&&sql_id'||'_'||'&&plan_hash_value','&&plan_name')
    into l_sql_handle, l_old_plan_name, l_plan_name
    from dba_sql_plan_baselines spb
    where created > sysdate-(1/24/60/15);


    ret := dbms_spm.alter_sql_plan_baseline(
    sql_handle=>l_sql_handle,
    plan_name=>l_old_plan_name,
    attribute_name=>'PLAN_NAME',
    attribute_value=>l_plan_name);



dbms_output.put_line(' ');
dbms_output.put_line('Baseline '||upper(l_plan_name)||' created.');
dbms_output.put_line(' ');

end;
/

clear breaks
exec  DBMS_SQLTUNE.DROP_SQLSET( sqlset_name => 'CREATE_BASELINE_AWR' );
undef sql_id
undef plan_hash_value
undef fixed
undef enabled
undef plan_name

exit;