
-- #############################################################################################################
-- FILE: create_sql_profile.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Creates or replaces a SQL Profile from a SQL Tuning Advisor task using DBMS_SQLTUNE.ACCEPT_SQL_PROFILE, with input validation, configurable FORCE_MATCH behavior, and post-creation profile detail reporting.
--
-- INPUT PARAMETERS:
-- &1 (task_name) - STRING - SQL Tuning Advisor task name containing the recommendation to accept.
-- &2 (profile_name) - STRING - Name for the SQL Profile to create or replace.
-- &3 (force_match) - STRING - Optional flag ('YES' or 'NO'); controls force matching behavior (default YES when null).
--
-- OUTPUT DESCRIPTION:
-- Validates inputs, creates/replaces the SQL Profile, writes execution output to create_sql_profile.log, prints DBMS_OUTPUT confirmation, and returns profile details (NAME, CATEGORY, STATUS, timestamps, FORCE_MATCHING).
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I create a SQL Profile from a SQL Tuning Advisor task?
-- How can I replace an existing SQL Profile with a new accepted recommendation?
-- How can I control FORCE_MATCH behavior when creating a SQL Profile?
-- Did SQL Profile creation complete successfully?
-- What are the resulting attributes of the created SQL Profile?
-- When was the created SQL Profile last modified?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : create_sql_profile.sql TASK_12345 PROFILE_SQLID_CM1FYT76DWBKB YES
-- #############################################################################################################
--

spool create_sql_profile.log

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
