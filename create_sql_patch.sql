
-- #############################################################################################################
-- FILE: create_sql_patch.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Creates a SQL Patch for a specified SQL_ID using provided optimizer hint text and patch name through SYS.DBMS_SQLDIAG.CREATE_SQL_PATCH, and logs execution output to create_sql_patch.log.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - Target SQL_ID for patch creation (e.g., 'cm1fyt76dwbkb').
-- &2 (hint_text) - STRING - Optimizer hint text to embed in the SQL Patch (e.g., '/*+ INDEX(table index_name) */').
-- &3 (patch_name) - STRING - Name to assign to the created SQL Patch (e.g., 'SQLPatch12345').
--
-- OUTPUT DESCRIPTION:
-- Executes SQL Patch creation, prints return code and confirmation messages through DBMS_OUTPUT, and writes the run output to create_sql_patch.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I create a SQL Patch for a specific SQL_ID?
-- How can I apply custom optimizer hints through SQL Patch?
-- What patch name is assigned to the created SQL Patch?
-- Did DBMS_SQLDIAG.CREATE_SQL_PATCH return successfully?
-- Was the SQL Patch created for the intended SQL_ID?
-- Where can I review the SQL Patch creation output log?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : create_sql_patch.sql cm1fyt76dwbkb "/*+ INDEX(T IDX_T1) */" SQLPATCH_TEST_01
-- #############################################################################################################
--

spool create_sql_patch.log

set feedback off
set sqlblanklines on
set serveroutput on
set verify off
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
