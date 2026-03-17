-- #############################################################################################################
-- Create SQL Profile from SQL Tuning Advisor task
-- Enhanced: validation, safer SQL*Plus runtime, explicit force_match handling
-- #############################################################################################################

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : create_sql_profile.sql MY_TUNING_TASK MY_SQL_PROFILE YES
--           create_sql_profile.sql MY_TUNING_TASK MY_SQL_PROFILE NO
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

define task_name    ='&1'
define profile_name ='&2'
define force_match  ='&3'

begin
  if '&&task_name' is null then
    raise_application_error(-20701, 'TASK_NAME is mandatory. Usage: @create_sql_profile.sql <TASK_NAME> <PROFILE_NAME> [YES|NO]');
  end if;
  if '&&profile_name' is null then
    raise_application_error(-20702, 'PROFILE_NAME is mandatory. Usage: @create_sql_profile.sql <TASK_NAME> <PROFILE_NAME> [YES|NO]');
  end if;
  if '&&force_match' is not null and upper('&&force_match') not in ('YES','NO') then
    raise_application_error(-20703, 'FORCE_MATCH must be YES or NO when provided.');
  end if;
end;
/

spool create_sql_profile.log

prompt
prompt =====================================================================================================
prompt Create SQL Profile from SQL Tuning Advisor task
prompt TASK_NAME=&&task_name  PROFILE_NAME=&&profile_name  FORCE_MATCH=&&force_match
prompt =====================================================================================================
prompt NOTE: This script performs a change (creates/replaces SQL Profile).

declare
  l_force_match varchar2(3) := nvl(upper('&&force_match'), 'YES');
begin
  if l_force_match = 'YES' then
    dbms_sqltune.accept_sql_profile(
      task_name   => '&&task_name',
      name        => '&&profile_name',
      force_match => true,
      replace     => true
    );
  else
    dbms_sqltune.accept_sql_profile(
      task_name   => '&&task_name',
      name        => '&&profile_name',
      force_match => false,
      replace     => true
    );
  end if;

  dbms_output.put_line('SQL Profile created/replaced successfully: &&profile_name');
end;
/

prompt
prompt --- Created profile details ---

column name          format a40
column category      format a20
column status        format a10
column created       format a19
column last_modified format a19

select name,
       category,
       status,
       to_char(created,'yyyy-mm-dd hh24:mi:ss') created,
       to_char(last_modified,'yyyy-mm-dd hh24:mi:ss') last_modified,
       force_matching
from   dba_sql_profiles
where  name = '&&profile_name';

spool off

exit;
