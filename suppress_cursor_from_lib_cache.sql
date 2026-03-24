
-- #############################################################################################################
-- FILE: suppress_cursor_from_lib_cache.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Purges a parent cursor from library cache for a given SQL_ID by deriving ADDRESS/HASH_VALUE and invoking DBMS_SHARED_POOL.PURGE.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID of the parent cursor to purge from library cache (e.g., 'cm1fyt76dwbkb').
--
-- OUTPUT DESCRIPTION:
-- Resolves ADDRESS,HASH_VALUE from V$SQLAREA, executes DBMS_SHARED_POOL.PURGE with object type C, and prints purge command details via DBMS_OUTPUT.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I purge a parent cursor from library cache by SQL_ID?
-- Which ADDRESS/HASH_VALUE pair is used for DBMS_SHARED_POOL.PURGE?
-- Did the library cache purge command execute for the requested SQL_ID?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : suppress_cursor_from_lib_cache.sql cm1fyt76dwbkb
-- #############################################################################################################
--
spool suppress_cursor_from_lib_cache.log

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


spool off
exit;
