-- ########################################
-- Suppress parent cursor from Library cache / cursor cache
-- ########################################
-- sql_id := &&1

--

--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : suppress_cursor_from_lib_cache.sql cm1fyt76dwbkb
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set feedback off
set sqlblanklines on
set serveroutput on
set verify off

declare


ret binary_integer;
l_sql_id varchar2(13);
l_string varchar2(50);



begin


l_sql_id := '&1';


select address||', '||hash_value into l_string from v$sqlarea where SQL_ID=l_sql_id;
dbms_output.put_line('exec dbms_shared_pool.purge with : '||l_string);

dbms_shared_pool.purge(l_string,'C');


dbms_output.put_line(' ');



end;
/

undef ret
undef l_sql_id
undef l_string


exit;