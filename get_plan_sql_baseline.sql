-- #############################################################################################################
-- Get execution plan from SQL Baseline Plan with plan_name as input
-- #############################################################################################################

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : get_plan_sql_baseline.sql SQLID_cm1fyt76dwbkb_2481688974 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set pages 999
set lines 180
set heading off
set long 10000
set serveroutput on
set verify off

define l_plan_name = '&1'


SELECT * FROM   TABLE(DBMS_XPLAN.display_sql_plan_baseline(plan_name=>'&l_plan_name'));

exit;



