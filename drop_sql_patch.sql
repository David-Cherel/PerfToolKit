
-- #############################################################################################################
-- FILE: drop_sql_patch.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Drops a SQL Patch by name using SYS.DBMS_SQLDIAG.DROP_SQL_PATCH and logs execution output for operational traceability.
--
-- INPUT PARAMETERS:
-- &1 (patch_name) - STRING - SQL Patch name to drop (e.g., 'SQLPatch12345').
--
-- OUTPUT DESCRIPTION:
-- Executes SQL Patch deletion, prints confirmation messages through DBMS_OUTPUT, and writes output to create_sql_patch.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I drop a specific SQL Patch by name?
-- Which patch name is being targeted for deletion?
-- Did SQL Patch drop operation complete successfully?
-- Where can I review the SQL Patch drop execution log?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : drop_sql_patch.sql SQLPatch12345
-- #############################################################################################################
--
spool drop_sql_patch.log

set feedback off
set sqlblanklines on
set serveroutput on
set verify off
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
