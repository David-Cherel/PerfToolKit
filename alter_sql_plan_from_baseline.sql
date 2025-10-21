-- #################################################
-- Alter SQL plan from SQL baseline 
-- #################################################
-- sql_handle := &&1
-- plan_name := &&2
-- fixed := &&3
-- enabled := &&4
--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : alter_sql_plan_from_baseline.sql SQL_46ada9aadcbb946e SQLID_auy3f5g7da1_2481688974 YES YES
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$




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