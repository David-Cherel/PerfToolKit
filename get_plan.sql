-- #############################################################################################################
-- Get execution plan from Library Cache with SQL_ID as input
-- #############################################################################################################

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : get_plan.sql cm1fyt76dwbkb 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set lines 180
set pages 0
define sql_id ='&1'
--For 19c

spool get_plan.log

Select * from table (DBMS_XPLAN.DISPLAY_CURSOR(sql_id=>'&sql_id',cursor_child_no=>NULL,format=> 'ALLSTATS LAST ALL +OUTLINE'));


spool off

exit;

