
-- #############################################################################################################
-- FILE: monitor_sql.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Creates a SQL Patch with MONITOR hint for a specified SQL_ID using DBMS_SQLDIAG.CREATE_SQL_PATCH to force SQL Monitoring for that statement.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID of statement in shared pool to patch with MONITOR hint (e.g., 'cm1fyt76dwbkb').
--
-- OUTPUT DESCRIPTION:
-- Executes SQL Patch creation and prints created patch name/confirmation via DBMS_OUTPUT.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I force SQL Monitoring for a specific SQL_ID?
-- Was a MONITOR SQL Patch created successfully for this SQL_ID?
-- What is the name of the created monitor patch?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : monitor_sql.sql cm1fyt76dwbkb
-- #############################################################################################################
--
spool monitor_sql.log

define sql_id = '&1' 


set feedback off
set sqlblanklines on
set serverout on format wrapped

declare

cl_sql_text clob;
l_category varchar2(30);
l_validate varchar2(3);
b_validate boolean;
l_patch_name VARCHAR2(32767);

begin

-- Not compatible before 12c 
l_patch_name := SYS.DBMS_SQLDIAG.create_sql_patch(
    sql_id    => '&&sql_id',
    hint_text => 'MONITOR',
    name      => 'MONITOR_PATCH_'||'&&sql_id');


dbms_output.put_line(' ');
dbms_output.put_line('SQL Patch '||l_patch_name||' created.');
dbms_output.put_line(' ');


end;
/

undef sql_id

set sqlblanklines off
set feedback on
set serverout off


spool off
exit;
