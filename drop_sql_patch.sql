-- ########################################
-- drop SQL Patch 
-- ########################################
-- patchname := &&1

--
--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : drop_sql_patch.sql SQLPatch12345 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set feedback off
set sqlblanklines on
set serveroutput on
set verify off
spool create_sql_patch.log
declare


ret binary_integer;

l_name varchar2(40);


begin


l_name := '&1';

dbms_output.put_line('SQL Patch dropping ');

sys.DBMS_SQLDIAG.DROP_SQL_PATCH(name=>l_name);



dbms_output.put_line(' ');
dbms_output.put_line('SQL Patch : '||l_name||' dropped.');
dbms_output.put_line(' ');
 
end;
/

spool off
exit;