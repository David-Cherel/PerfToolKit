-- #############################################################################################################
-- Session Optimizer Environment by SID
--
-- Purpose:
--   Display NAME, VALUE, ISDEFAULT, SQL_FEATURE from V$SES_OPTIMIZER_ENV for one SID.
--
-- Usage:
--   @ses_optimizer_env_by_sid.sql <SID>
--
-- Example:
--   @ses_optimizer_env_by_sid.sql 123
-- #############################################################################################################

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
