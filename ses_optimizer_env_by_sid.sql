-- #############################################################################################################
-- FILE: ses_optimizer_env_by_sid.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays optimizer environment settings for a specific session SID from V$SES_OPTIMIZER_ENV, including parameter value, default flag, and related SQL feature context.
--
-- INPUT PARAMETERS:
-- &1 (sid_in) - NUMBER - Session SID to inspect optimizer environment values (e.g., 123).
--
-- OUTPUT DESCRIPTION:
-- One result set listing optimizer environment NAME, VALUE, ISDEFAULT, and SQL_FEATURE for the provided SID; output is spooled to ses_optimizer_env_by_sid.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- What optimizer environment parameters are active for a given SID?
-- Which optimizer settings differ from default for this session?
-- Which SQL features are associated with optimizer environment entries for this SID?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : ses_optimizer_env_by_sid.sql 123
-- #############################################################################################################
--
set pages 9999
set lines 220
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define sid_in = '&1'

begin
  if '&&sid_in' is null then
    raise_application_error(-20601, 'SID is mandatory. Usage: @ses_optimizer_env_by_sid.sql <SID>');
  end if;

  if not regexp_like('&&sid_in', '^[0-9]+$') then
    raise_application_error(-20602, 'SID must be numeric.');
  end if;
end;
/

spool ses_optimizer_env_by_sid.log

prompt
prompt =====================================================================================================
prompt Session optimizer environment for SID=&&sid_in
prompt =====================================================================================================

column name        format a45
column value       format a55
column isdefault   format a10
column sql_feature format a35

select name,
       value,
       isdefault,
       sql_feature
from   v$ses_optimizer_env
where  sid = to_number('&&sid_in')
order  by name;

spool off

exit;
