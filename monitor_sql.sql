----------------------------------------------------------------------------------------
--
-- File name:   monitor_sql.sql
--
-- Purpose:     Prompts for a sql_id and creates a patch with the monitor hint
-
-- Author:      Kerry Osborne
--
-- Usage:       This scripts prompts for one value.
--
--              sql_id: the sql_id of the statement to attach the patch to 
--                      (the statement must be in the shared pool)
--
--              
--              See kerryosborne.oracle-guy.com for additional information.
----------------------------------------------------------------------------------------- 


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


exit;
