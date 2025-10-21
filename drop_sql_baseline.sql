-- ########################################################
-- Drop SQL Baseline from SPM repository (all SQL Plans)
-- ########################################################
-- sql_handle := &&1



-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : drop_sql_baseline.sql SQL_auy3f5g7da1ed45g
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

set feedback off
set sqlblanklines on
set serveroutput on
set verify off
set lines 160
spool drop_sql_plan.log

declare
l_sql_handle varchar2(40);
ret number;


begin

l_sql_handle := '&1';

dbms_output.put_line('Droping SQL Baseline (all SQL Plans from SQL Baseline) : '||l_sql_handle);
ret := dbms_spm.DROP_SQL_PLAN_BASELINE(sql_handle => l_sql_handle);

dbms_output.put_line('Status of drop   : '||ret);

end;
/

spool off
exit;