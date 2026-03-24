
-- #############################################################################################################
-- FILE: drop_sql_plan.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Drops a specific SQL Plan Baseline by PLAN_NAME from the SQL Plan Management repository using DBMS_SPM.DROP_SQL_PLAN_BASELINE.
--
-- INPUT PARAMETERS:
-- &1 (plan_name) - STRING - Baseline plan name to drop (e.g., 'SQLID_auy3f5g7da1_2481688974').
--
-- OUTPUT DESCRIPTION:
-- Executes SQL Plan drop operation, prints DBMS_OUTPUT status/return count, and writes execution output to drop_sql_plan.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I drop a specific SQL Plan Baseline by plan name?
-- Which plan name is being targeted for baseline removal?
-- How many plans were dropped by DBMS_SPM.DROP_SQL_PLAN_BASELINE?
-- Did SQL plan drop complete successfully?
-- Where can I review the SQL plan drop output log?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : drop_sql_plan.sql SQLID_auy3f5g7da1_2481688974
-- #############################################################################################################
--
spool drop_sql_plan.log

set feedback off
set sqlblanklines on
set serveroutput on
set verify off
set lines 160

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
