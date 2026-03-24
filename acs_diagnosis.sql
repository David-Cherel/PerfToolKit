
-- #############################################################################################################
-- FILE: acs_diagnosis.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Produces an Adaptive Cursor Sharing diagnosis report for a SQL_ID (optionally one child cursor), combining parameter checks, cursor performance, split reasons, bind capture, and ACS selectivity/statistics/histogram views.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to diagnose for ACS behavior (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (child_no) - NUMBER - Optional child cursor number filter (e.g., 0).
--
-- OUTPUT DESCRIPTION:
-- Multiple result sets covering ACS-related parameters, V$SQL/V$SQLAREA cursor metrics, V$SQL_SHARED_CURSOR reasons, V$SQL_BIND_CAPTURE values, and V$SQL_CS_* ACS views; output is spooled to acs_diagnosis.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Is this SQL_ID bind-sensitive and bind-aware?
-- Which child cursors exist and how do their performance metrics differ?
-- Why were additional child cursors created for this SQL_ID?
-- What bind values were captured for each child cursor?
-- What ACS selectivity buckets and runtime statistics are recorded?
-- Are ACS-related hidden optimizer parameters enabled as expected?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : acs_diagnosis.sql cm1fyt76dwbkb 0
-- #############################################################################################################
--
spool acs_diagnosis.log

set pages 9999
set lines 240
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
  if '&&sql_id' is null then
    raise_application_error(-20401, 'SQL_ID is mandatory. Usage: @acs_diagnosis.sql <SQL_ID> [CHILD_NUMBER]');
  end if;
  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20402, 'Invalid SQL_ID format: &&sql_id');
  end if;
  if '&&child_no' is not null and not regexp_like('&&child_no', '^[0-9]+$') then
    raise_application_error(-20403, 'CHILD_NUMBER must be numeric when provided.');
  end if;
end;
/


prompt
prompt =====================================================================================================
prompt ACS diagnosis for SQL_ID=&&sql_id  CHILD_NUMBER=&&child_no
prompt =====================================================================================================
prompt NOTE: Read-only report. No data change is performed.

prompt
prompt --- 0) ACS-related hidden optimizer parameters ---

column name             format a45
column value            format a30
column isdefault        format a10
column issys_modifiable format a16

select name,
       value,
       isdefault,
       issys_modifiable
from   v$parameter
where  name in (
         '_optim_peek_user_binds',
         '_optimizer_adaptive_cursor_sharing',
         '_optimizer_extended_cursor_sharing_rel'
       )
order by name;

column last_active_time   format a19
column avg_ela_time_ms        format 999,999.99
column avg_cpu_time_ms          format 999,999.99
column avg_lio            format 999,999,999.9
column avg_pio            format 999,999,999.9
column is_bind_sensitive  format a3
column is_bind_aware      format a3
column is_shareable       format a3

prompt
prompt --- 1) V$SQL overview: bind sensitivity / awareness per child cursor ---

select child_number,
       plan_hash_value,
       is_bind_sensitive,
       is_bind_aware,
       is_shareable,
       executions,
       to_char(last_active_time,'yyyy-mm-dd hh24:mi:ss') last_active_time,
       (elapsed_time/1000)/decode(nvl(executions,0),0,1,executions) avg_ela_time_ms,
       (cpu_time/1000)/decode(nvl(executions,0),0,1,executions) avg_cpu_time_ms,
       buffer_gets/decode(nvl(executions,0),0,1,executions) avg_lio,
       disk_reads/decode(nvl(executions,0),0,1,executions) avg_pio
from   v$sql
where  sql_id = '&&sql_id'
and   (nullif('&&child_no','') is null or child_number = to_number(nullif('&&child_no','')))
order by child_number;

prompt
prompt --- 2) V$SQLAREA parent-level snapshot ---

select sql_id,
       plan_hash_value,
       version_count,
       loaded_versions,
       open_versions,
       users_opening,
       executions,
       parsing_schema_name,
       module,
       action
from   v$sqlarea
where  sql_id = '&&sql_id';

prompt
prompt --- 3) V$SQL_SHARED_CURSOR (child split reasons) ---

column reason_text format a80
column reason_html format a180 word_wrapped

with child_reasons as (
  select ssc.child_number,
         xt.reason_text
  from   v$sql_shared_cursor ssc,
         xmltable('/ChildNode/reason'
           passing xmlparse(content ssc.reason)
           columns reason_text varchar2(4000) path '.') xt
  where  ssc.sql_id = '&&sql_id'
  and   (nullif('&&child_no','') is null or ssc.child_number = to_number(nullif('&&child_no','')))
)
select child_number,
       reason_text,
       '<div class="child-reason"><b>Child '||child_number||'</b> - '
       ||'<span class="reason">'||reason_text||'</span></div>' as reason_html
from   child_reasons
order by child_number, reason_text;

prompt
prompt --- 4) V$SQL_BIND_CAPTURE (captured bind values/types) ---

column name            format a30
column datatype_string format a20
column value_string    format a60
column last_captured   format a19

select child_number,
       name,
       position,
       datatype_string,
       value_string,
       to_char(last_captured,'yyyy-mm-dd hh24:mi:ss') last_captured,
       was_captured
from   v$sql_bind_capture
where  sql_id = '&&sql_id'
and   (nullif('&&child_no','') is null or child_number = to_number(nullif('&&child_no','')))
order by child_number, position;

prompt
prompt --- 5) V$SQL_CS_SELECTIVITY (ACS selectivity buckets) ---

select *
from   v$sql_cs_selectivity
where  sql_id = '&&sql_id'
and   (nullif('&&child_no','') is null or child_number = to_number(nullif('&&child_no','')))
order by child_number;

prompt
prompt --- 6) V$SQL_CS_STATISTICS (ACS runtime statistics) ---

select *
from   v$sql_cs_statistics
where  sql_id = '&&sql_id'
and   (nullif('&&child_no','') is null or child_number = to_number(nullif('&&child_no','')))
order by child_number;

prompt
prompt --- 7) V$SQL_CS_HISTOGRAM (ACS histogram buckets) ---

select *
from   v$sql_cs_histogram
where  sql_id = '&&sql_id'
and   (nullif('&&child_no','') is null or child_number = to_number(nullif('&&child_no','')))
order by child_number;

prompt
prompt --- Action hints ---
prompt 1) If IS_BIND_SENSITIVE=Y but IS_BIND_AWARE=N, ACS may need more executions.
prompt 2) If many child cursors exist, check V$SQL_SHARED_CURSOR for BIND_MISMATCH/OPTIMIZER_MISMATCH.
prompt 3) Correlate V$SQL_BIND_CAPTURE values with V$SQL_CS_* selectivity buckets.
prompt 4) If bind skew is real, evaluate histogram strategy (prefer pending stats test first).


spool off
exit;
