-- ################################################################################################
-- Drop SQL Set 
-- ################################################################################################
-- SQL_Set_Name := &&1

--
--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : create_sql_set_awr_snap.sql my_sal_set 25698 25950
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set feedback off
set sqlblanklines on
set verify off
set serveroutput on
set lines 180

define sql_set_name = '&1'



begin

DBMS_SQLSET.DROP_SQLSET (sqlset_name=>'&&sql_set_name');

END;
/

undef sql_set_name


exit;
