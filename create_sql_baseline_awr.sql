
-- #############################################################################################################
-- FILE: create_sql_baseline_awr.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Creates a SQL Plan Baseline from AWR for a specified SQL_ID and PLAN_HASH_VALUE, loads it through a temporary SQL tuning set, renames the baseline, and optionally sets FIXED and ENABLED attributes.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - Target SQL_ID to import from AWR (e.g., 'cm1fyt76dwbkb').
-- &2 (plan_hash_value) - NUMBER - Target execution plan hash value from AWR (e.g., 2481688974).
-- &3 (fixed) - STRING - Baseline fixed flag ('YES' or 'NO').
-- &4 (enabled) - STRING - Baseline enabled flag ('YES' or 'NO').
--
-- OUTPUT DESCRIPTION:
-- Creates and renames a SQL baseline (default name pattern SQLID_<SQL_ID>_<PLAN_HASH_VALUE>), prints DBMS_OUTPUT progress/status, and drops the temporary SQL tuning set CREATE_BASELINE_AWR at script end.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I create a SQL baseline from AWR for a specific SQL_ID and plan hash value?
-- Can I import an historical AWR plan into SQL Plan Management?
-- How can I mark a newly created baseline as fixed?
-- How can I control whether the created baseline is enabled?
-- What baseline name will be assigned after creation?
-- Can I rename the created baseline to SQLID_<SQL_ID>_<PLAN_HASH_VALUE> automatically?
-- Did baseline creation and rename complete successfully?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : create_sql_baseline_awr.sql cm1fyt76dwbkb 2481688974 YES YES
-- #############################################################################################################
--

spool create_sql_baseline_awr.log

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

spool off
exit;
