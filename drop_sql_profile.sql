
-- #############################################################################################################
-- FILE: drop_sql_profile.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Drops a SQL Profile by name using DBMS_SQLTUNE.DROP_SQL_PROFILE, with input validation, safe SQL*Plus runtime settings, and post-drop verification query against DBA_SQL_PROFILES.
--
-- INPUT PARAMETERS:
-- &1 (profile_name) - STRING - SQL Profile name to drop (e.g., 'MY_SQL_PROFILE').
--
-- OUTPUT DESCRIPTION:
-- Validates input, drops the SQL Profile, writes execution output to drop_sql_profile.log, prints DBMS_OUTPUT confirmation, and displays verification query results (expected zero row after drop).
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I drop a SQL Profile by name?
-- Is PROFILE_NAME input provided and valid before execution?
-- Did DBMS_SQLTUNE.DROP_SQL_PROFILE complete successfully?
-- Does the SQL Profile still exist after the drop operation?
-- Where can I review the SQL Profile drop execution log?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : drop_sql_profile.sql MY_SQL_PROFILE
-- #############################################################################################################
--
spool drop_sql_profile.log

set pages 9999
set lines 220
set long 1000000
set longchunksize 32767
set trimspool on
set verify off
set feedback on
set tab off
set termout on
set serveroutput on size unlimited

whenever sqlerror exit failure rollback

define profile_name ='&1'

begin
  if '&&profile_name' is null then
    raise_application_error(-20801, 'PROFILE_NAME is mandatory. Usage: @drop_sql_profile.sql <PROFILE_NAME>');
  end if;
end;
/


prompt
prompt =====================================================================================================
prompt Drop SQL Profile: &&profile_name
prompt =====================================================================================================
prompt NOTE: This script performs a change (drops SQL Profile).

begin
  dbms_sqltune.drop_sql_profile(name => '&&profile_name');
  dbms_output.put_line('SQL Profile dropped successfully: &&profile_name');
end;
/

prompt
prompt --- Verification (should return 0 row) ---

column name format a40

select name,
       status,
       to_char(last_modified,'yyyy-mm-dd hh24:mi:ss') last_modified
from   dba_sql_profiles
where  name = '&&profile_name';


spool off
exit;
