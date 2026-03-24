-- #############################################################################################################
-- FILE: dynamic_stats_diagnosis.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Diagnoses dynamic statistics usage for a SQL_ID/child cursor by reading DBMS_XPLAN note text, extracting sampling level, and correlating results with session optimizer environment values.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (child_no) - NUMBER - Child cursor number to analyze (e.g., 0).
--
-- OUTPUT DESCRIPTION:
-- Multiple result sets: cursor context, plan note lines indicating dynamic stats/sampling, extracted dynamic sampling level, active-session optimizer environment values, and session-vs-note correlation summary; output spooled to dynamic_stats_diagnosis.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Did this cursor use dynamic statistics according to DBMS_XPLAN notes?
-- What dynamic sampling level is reported in the plan note?
-- What is the current session optimizer_dynamic_sampling value for sessions using this SQL child?
-- Do session optimizer settings align with plan note sampling level?
-- Are there active sessions currently executing the analyzed SQL_ID/child?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : dynamic_stats_diagnosis.sql cm1fyt76dwbkb 0
-- #############################################################################################################
--
set pages 9999
set lines 260
set long 1000000
set longchunksize 32767
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define sql_id   = '&1'
define child_no = '&2'

begin
  if '&&sql_id' is null or '&&child_no' is null then
    raise_application_error(-20701,
      'Usage: @dynamic_stats_diagnosis.sql <SQL_ID> <CHILD_NUMBER>');
  end if;

  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20702, 'Invalid SQL_ID format: &&sql_id');
  end if;

  if not regexp_like('&&child_no', '^[0-9]+$') then
    raise_application_error(-20703, 'CHILD_NUMBER must be numeric.');
  end if;
end;
/

spool dynamic_stats_diagnosis.log

prompt
prompt =====================================================================================================
prompt Dynamic Statistics diagnosis for SQL_ID=&&sql_id CHILD_NUMBER=&&child_no
prompt =====================================================================================================
prompt NOTE: Read-only script. No data change is performed.

column last_active_time format a19
column avg_etime_s      format 999,999.99999
column avg_cpu_s        format 999,999.99999

prompt
prompt --- 1) Cursor context from V$SQL ---

select sql_id,
       child_number,
       plan_hash_value,
       executions,
       to_char(last_active_time,'yyyy-mm-dd hh24:mi:ss') last_active_time,
       optimizer_mode,
       is_bind_sensitive,
       is_bind_aware,
       (elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_etime_s,
       (cpu_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_cpu_s
from   v$sql
where  sql_id = '&&sql_id'
and    child_number = to_number('&&child_no');

prompt
prompt --- 2) Plan note probe (dynamic statistics / dynamic sampling note) ---

column plan_note_line format a170 word_wrapped

with plan_note as (
  select plan_table_output plan_note_line
  from   table(
           dbms_xplan.display_cursor(
             sql_id          => '&&sql_id',
             cursor_child_no => to_number('&&child_no'),
             format          => 'BASIC +NOTE'
           )
         )
)
select plan_note_line
from   plan_note
where  lower(plan_note_line) like '%dynamic statistics used%'
or     lower(plan_note_line) like '%dynamic sampling%';

prompt
prompt --- 3) Extracted dynamic sampling level from note text ---

column dynamic_sampling_level format 99999
column dynamic_stats_used     format a3

with plan_note as (
  select plan_table_output plan_note_line
  from   table(
           dbms_xplan.display_cursor(
             sql_id          => '&&sql_id',
             cursor_child_no => to_number('&&child_no'),
             format          => 'BASIC +NOTE'
           )
         )
), ds as (
  select regexp_substr(lower(plan_note_line), 'level\s*=\s*([0-9]+)', 1, 1, null, 1) lvl
  from   plan_note
  where  lower(plan_note_line) like '%dynamic statistics used%'
  or     lower(plan_note_line) like '%dynamic sampling%'
)
select case when count(*) > 0 then 'YES' else 'NO' end dynamic_stats_used,
       max(to_number(lvl)) dynamic_sampling_level
from   ds;

prompt
prompt --- 4) Active sessions currently on this SQL_ID/child + session env correlation ---

column username    format a20
column module      format a30
column action      format a25
column status      format a10
column sql_feature format a35
column env_name    format a40
column env_value   format a40

select s.sid,
       s.serial#,
       s.username,
       s.status,
       s.module,
       s.action,
       seo.name env_name,
       seo.value env_value,
       seo.isdefault,
       seo.sql_feature
from   v$session s
       join v$ses_optimizer_env seo
         on seo.sid = s.sid
where  s.sql_id = '&&sql_id'
and    s.sql_child_number = to_number('&&child_no')
and    lower(seo.name) in ('optimizer_dynamic_sampling','optimizer_features_enable')
order by s.sid, seo.name;

prompt
prompt --- 5) Session-level correlation summary vs extracted note level ---

with note_level as (
  select max(to_number(regexp_substr(lower(plan_table_output), 'level\s*=\s*([0-9]+)', 1, 1, null, 1))) ds_level
  from   table(
           dbms_xplan.display_cursor(
             sql_id          => '&&sql_id',
             cursor_child_no => to_number('&&child_no'),
             format          => 'BASIC +NOTE'
           )
         )
  where  lower(plan_table_output) like '%dynamic statistics used%'
  or     lower(plan_table_output) like '%dynamic sampling%'
)
select s.sid,
       max(case when lower(seo.name) = 'optimizer_dynamic_sampling' then seo.value end) session_optimizer_dynamic_sampling,
       (select ds_level from note_level) plan_note_dynamic_sampling_level
from   v$session s
       join v$ses_optimizer_env seo
         on seo.sid = s.sid
where  s.sql_id = '&&sql_id'
and    s.sql_child_number = to_number('&&child_no')
group by s.sid
order by s.sid;

prompt
prompt --- Action hints ---
prompt 1) If note shows dynamic statistics but no active session is found, cursor is historical/inactive now.
prompt 2) SESSION optimizer_dynamic_sampling can differ from level reported in note (internal escalation is possible).
prompt 3) Re-run on an actively executing session for freshest session correlation.

spool off

exit;
