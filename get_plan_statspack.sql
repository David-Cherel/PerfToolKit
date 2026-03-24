-- #############################################################################################################
-- FILE: get_plan_statspack.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays execution plan lines from Statspack plan repository for a specified PLAN_HASH_VALUE using DBMS_XPLAN.DISPLAY on PERFSTAT.STATS$SQL_PLAN.
--
-- INPUT PARAMETERS:
-- &1 (plan_hash_value) - NUMBER - Plan hash value to display from Statspack plan table (e.g., 3284627250).
--
-- OUTPUT DESCRIPTION:
-- One result set containing formatted execution plan text returned by DBMS_XPLAN for Statspack rows filtered by the provided PLAN_HASH_VALUE; output is spooled to get_plan_statspack.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- What execution plan corresponds to a given PLAN_HASH_VALUE in Statspack?
-- How can I display plan steps stored in PERFSTAT.STATS$SQL_PLAN?
-- Is the requested PLAN_HASH_VALUE present in Statspack plan history?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : get_plan_statspack.sql 3284627250
-- #############################################################################################################
--
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
