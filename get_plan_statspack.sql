-- #############################################################################################################
-- Get execution plan from Statspack snapshots with PLAN_HASH_VALUE as input
-- #############################################################################################################

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : get_plan_statspack.sql 3284627250 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set lines 180
set pages 0
define plan_hash_value ='&1'

spool get_plan_statspack.log

/* PTK */ select * from table(dbms_xplan.display(
  table_name   => 'perfstat.stats$sql_plan',
  statement_id => null,
  format       => 'ALL',
  filter_preds => 'plan_hash_value = &plan_hash_value'
  ));
  
  
spool off

exit
