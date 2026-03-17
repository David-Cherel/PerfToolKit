-- #############################################################################################################
-- Drop SQL Profile
-- Enhanced: validation, safer SQL*Plus runtime, post-action verification
-- #############################################################################################################

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : drop_sql_profile.sql MY_SQL_PROFILE
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

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

spool drop_sql_profile.log

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
