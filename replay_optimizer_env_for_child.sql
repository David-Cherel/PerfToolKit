-- #############################################################################################################
-- FILE: replay_optimizer_env_for_child.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Extracts optimizer environment settings for a specific SQL_ID child cursor from library cache and generates replay-ready ALTER SESSION statements, enabling controlled reproduction of optimizer behavior in a separate diagnostic session.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID in library cache (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (child_number) - NUMBER - Child cursor number to replay (e.g., 2).
-- &3 (include_hidden_params) - STRING - Include hidden parameters in generated ALTER SESSION statements: Y|N (e.g., 'N').
--
-- OUTPUT DESCRIPTION:
-- Three sections: (1) source child cursor identity/context from V$SQL, (2) optimizer environment parameter inventory from V$SQL_OPTIMIZER_ENV, (3) generated ALTER SESSION statements for non-default settings plus a reproducibility checklist.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which optimizer environment parameters were used by this SQL child cursor?
-- Which non-default optimizer settings should be replayed in a test session?
-- How can I generate ALTER SESSION commands from cursor optimizer environment metadata?
-- Should hidden optimizer parameters be included in replay commands?
-- What application/session context should also be aligned for reproducible testing?
-- Is the target SQL_ID child cursor available in current library cache?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : replay_optimizer_env_for_child.sql cm1fyt76dwbkb 2 N
-- #############################################################################################################
--

-- Spool output for reproducibility traceability.
spool replay_optimizer_env_for_child.log

-- Configure SQL*Plus report formatting.
set pages 9999
set lines 280
set long 1000000
set longchunksize 32767
set trimspool on
set verify off
set feedback on
set tab off
set termout on

-- Stop on SQL errors to avoid partial replay scripts.
whenever sqlerror exit failure rollback

-- Capture runtime parameters.
define sql_id = '&1'
define child_number = '&2'
define include_hidden_params = upper('&3')

-- Validate mandatory parameters and target child existence.
declare
  l_exists number;
begin
  if '&&sql_id' is null or '&&child_number' is null or '&&include_hidden_params' is null then
    raise_application_error(-21401,
      'Usage: @replay_optimizer_env_for_child.sql <SQL_ID> <CHILD_NUMBER> <INCLUDE_HIDDEN_PARAMS(Y|N)>');
  end if;

  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-21402, 'Invalid SQL_ID format: &&sql_id');
  end if;

  if not regexp_like('&&child_number', '^[0-9]+$') then
    raise_application_error(-21403, 'CHILD_NUMBER must be a non-negative integer.');
  end if;

  if upper('&&include_hidden_params') not in ('Y','N') then
    raise_application_error(-21404, 'INCLUDE_HIDDEN_PARAMS must be Y or N.');
  end if;

  select count(*)
    into l_exists
    from v$sql
   where sql_id = lower('&&sql_id')
     and child_number = to_number('&&child_number');

  if l_exists = 0 then
    raise_application_error(-21405,
      'SQL_ID/CHILD_NUMBER not found in V$SQL cache. Re-parse SQL or use AWR-based diagnostics first.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Optimizer environment replay extraction for SQL_ID=&&sql_id CHILD_NUMBER=&&child_number
prompt INCLUDE_HIDDEN_PARAMS=&&include_hidden_params
prompt =====================================================================================================
prompt NOTE: Generated ALTER SESSION statements are for controlled test sessions, not for production blind replay.

-- Define display formatting for source child cursor context.
column last_active_time         format a19
column parsing_schema_name      format a30
column module                   format a35
column action                   format a35
column optimizer_env_hash_value format 99999999999999999999

prompt
prompt --- 1) Source child cursor context ---

-- Show source child cursor identity and key context attributes.
select child_number,
       sql_id,
       plan_hash_value,
       executions,
       optimizer_env_hash_value,
       to_char(last_active_time, 'yyyy-mm-dd hh24:mi:ss') as last_active_time,
       parsing_schema_name,
       module,
       action
  from v$sql
 where sql_id = lower('&&sql_id')
   and child_number = to_number('&&child_number');

-- Define display formatting for optimizer env inventory.
column name      format a50
column value     format a80
column isdefault format a10

prompt
prompt --- 2) Optimizer environment inventory (V$SQL_OPTIMIZER_ENV) ---

-- List optimizer environment parameters captured for the selected child cursor.
select child_number,
       name,
       value,
       isdefault
  from v$sql_optimizer_env
 where sql_id = lower('&&sql_id')
   and child_number = to_number('&&child_number')
 order by name;

column replay_alter_session format a220

prompt
prompt --- 3) Generated ALTER SESSION statements (non-default settings) ---
prompt ---    Review carefully before execution in a test session. ---

-- Generate replay-ready ALTER SESSION statements for non-default parameters.
select 'alter session set ' || name || ' = ' ||
       case
         when value is null then 'NULL'
         when regexp_like(value, '^-?[0-9]+(\.[0-9]+)?$') then value
         when upper(value) in ('TRUE','FALSE') then lower(value)
         else '''' || replace(value, '''', '''''') || ''''
       end || ';' as replay_alter_session
  from v$sql_optimizer_env
 where sql_id = lower('&&sql_id')
   and child_number = to_number('&&child_number')
   and isdefault = 'NO'
   and (upper('&&include_hidden_params') = 'Y' or name not like '\_%' escape '\')
 order by case when name like '\_%' escape '\' then 1 else 0 end, name;

prompt
prompt --- Reproducibility checklist (manual alignment beyond optimizer params) ---
prompt 1) Use same DB user or same effective CURRENT_SCHEMA as source workload.
prompt 2) Align module/action/client_identifier using DBMS_APPLICATION_INFO and DBMS_SESSION.
prompt 3) Replay representative bind values (V$SQL_BIND_CAPTURE where available).
prompt 4) Run in same PDB/service and similar session NLS settings.
prompt 5) Validate plan with DBMS_XPLAN.DISPLAY_CURSOR after parsing/executing target SQL.
prompt 6) If child still differs, investigate cursor split reasons via @cursor_reason.sql <SQL_ID>.

-- End spool and terminate script.
spool off
exit;
