-- ########################################################
-- Drop SQL plan from Baseline from SPM repository (one unique SQL Plan)
-- ########################################################
-- sql_plan := &&1



-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : drop_sql_baseline.sql SQL_auy3f5g7da1ed45g
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$




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
l_plan_name varchar2(40);


begin

l_plan_name := '&1';

dbms_output.put_line('Droping SQL Plan from Baseline (one signle SQL Plan from a SQL Baseline) : '||l_plan_name);
ret := dbms_spm.DROP_SQL_PLAN_BASELINE(sql_handle => l_plan_name);

dbms_output.put_line('Status of drop   : '||ret);

end;
/


exit;