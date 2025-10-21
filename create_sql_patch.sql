-- ########################################
-- creation SQL Patch from cursor cache
-- ########################################
-- sql_id := &&1
-- hint := &&2
-- patchname := &&3


--
--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : create_sql_patch.sql cm1fyt76dwbkb SQLPatch12345 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set feedback off
set sqlblanklines on
set serveroutput on
set verify off
spool create_sql_patch.log
declare




ret varchar2(40);
l_sql_id varchar2(13);
l_name varchar2(40);
l_hint varchar2(4000);

begin


l_sql_id := '&1';
l_hint := '&2';
l_name := '&3';

dbms_output.put_line('SQL Patch creation ');

ret:= SYS.dbms_sqldiag.create_sql_patch(
    sql_id    => l_sql_id,
    hint_text => to_clob(l_hint),
    name      => l_name);


dbms_output.put_line('Return code : '||ret);
dbms_output.put_line(' ');
dbms_output.put_line('SQL Patch : '||l_name||' created.');
dbms_output.put_line(' ');
 
end;
/

spool off
exit;