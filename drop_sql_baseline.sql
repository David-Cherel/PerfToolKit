-- #############################################################################################################
-- FILE: drop_sql_baseline.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Drops all SQL Plan Baselines associated with a specified SQL handle from the SQL Plan Management repository using DBMS_SPM.DROP_SQL_PLAN_BASELINE.
--
-- INPUT PARAMETERS:
-- &1 (sql_handle) - STRING - SQL handle whose baselines must be removed (e.g., 'SQL_auy3f5g7da1ed45g').
--
-- OUTPUT DESCRIPTION:
-- Executes baseline drop operation, prints DBMS_OUTPUT status/return count, and writes execution output to drop_sql_plan.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I drop all baselines for a specific SQL handle?
-- What SQL handle is being targeted for baseline removal?
-- How many baselines were dropped by DBMS_SPM.DROP_SQL_PLAN_BASELINE?
-- Did baseline drop complete successfully?
-- Where can I review the drop operation output log?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : drop_sql_baseline.sql SQL_auy3f5g7da1ed45g
-- #############################################################################################################
--
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