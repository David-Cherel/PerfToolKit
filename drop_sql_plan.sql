-- ########################################
-- Drop SQL Plan from SPM repository
-- ########################################
-- plan_name := &&1



-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : drop_sql_plan.sql SQLID_auy3f5g7da1_2481688974  
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

set feedback off
set sqlblanklines on
set serveroutput on
set verify off
set lines 160
spool drop_sql_plan.log

declare
l_plan_name varchar2(40);
ret number;


begin

l_plan_name := '&&1';

dbms_output.put_line('Droping SQL Plan : '||l_plan_name);
ret := dbms_spm.DROP_SQL_PLAN_BASELINE(plan_name => l_plan_name);

dbms_output.put_line('Status of drop   : '||ret);

end;
/

spool off
exit;