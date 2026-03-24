
-- #############################################################################################################
-- FILE: stats_feedback_diagnosis.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Diagnoses statistics/cardinality feedback behavior for a SQL_ID (optionally child cursor), checking feedback parameter state, cursor reoptimization indicators, plan notes, and reoptimization hints.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to diagnose for feedback/reoptimization behavior (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (child_no) - NUMBER - Optional child cursor number filter (e.g., 0).
--
-- OUTPUT DESCRIPTION:
-- Multiple sections: _optimizer_use_feedback parameter, V$SQL cursor indicators, DBMS_XPLAN note probe, OPT_ESTIMATE hints from V$SQL_REOPTIMIZATION_HINTS, and correlated hint/plan view; output spooled to stats_feedback_diagnosis.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Is optimizer feedback enabled in this environment?
-- Is the cursor marked reoptimizable for this SQL_ID/child?
-- Does plan note indicate cardinality/statistics feedback usage?
-- Are OPT_ESTIMATE reoptimization hints present for this SQL_ID?
-- How do reoptimization hints correlate with child cursors and plan hash values?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : stats_feedback_diagnosis.sql cm1fyt76dwbkb 0
-- #############################################################################################################
--
spool stats_feedback_diagnosis.log

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
  if '&&sql_id' is null then
    raise_application_error(-20501, 'SQL_ID is mandatory. Usage: @stats_feedback_diagnosis.sql <SQL_ID> [CHILD_NUMBER]');
  end if;

  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20502, 'Invalid SQL_ID format: &&sql_id');
  end if;

  if '&&child_no' is not null and not regexp_like('&&child_no', '^[0-9]+$') then
    raise_application_error(-20503, 'CHILD_NUMBER must be numeric when provided.');
  end if;
end;
/


prompt
prompt =====================================================================================================
prompt Statistics Feedback diagnosis for SQL_ID=&&sql_id CHILD_NUMBER=&&child_no
prompt =====================================================================================================
prompt NOTE: Read-only report. No data change is performed.

prompt
prompt --- 1) Hidden parameter: _optimizer_use_feedback ---

column name             format a35
column value            format a20
column isdefault        format a10
column issys_modifiable format a16

select name,
       value,
       isdefault,
       issys_modifiable,
       description
from   v$parameter
where  name = '_optimizer_use_feedback';

prompt
prompt --- 2) Cursor probe in V$SQL (feedback/reoptimization indicators) ---

column last_active_time    format a19
column avg_etime_s         format 999,999.99999
column avg_cpu_s           format 999,999.99999
column is_bind_sensitive   format a3
column is_bind_aware       format a3
column is_shareable        format a3
column is_reoptimizable    format a3

select child_number,
       plan_hash_value,
       executions,
       is_bind_sensitive,
       is_bind_aware,
       is_shareable,
       is_reoptimizable,
       to_char(last_active_time,'yyyy-mm-dd hh24:mi:ss') last_active_time,
       (elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_etime_s,
       (cpu_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_cpu_s,
       parsing_schema_name,
       module
from   v$sql
where  sql_id = '&&sql_id'
and   (nullif('&&child_no','') is null or child_number = to_number(nullif('&&child_no','')))
order by child_number;

prompt
prompt --- 2b) Plan note probe (look for: "cardinality feedback used for this statement") ---

select *
from table(
  dbms_xplan.display_cursor(
    sql_id          => '&&sql_id',
    cursor_child_no => case when nullif('&&child_no','') is null then null else to_number('&&child_no') end,
    format          => 'BASIC +NOTE'
  )
);

prompt
prompt --- 3) OPT_ESTIMATE hints from V$SQL_REOPTIMIZATION_HINTS ---

column hint_text      format a140 word_wrapped
column object_clue_1  format a40
column object_clue_2  format a40

select h.sql_id,
       h.child_number,
       h.hint_id,
       h.hint_text,
       regexp_substr(h.hint_text, '"[^"]+"', 1, 1) object_clue_1,
       regexp_substr(h.hint_text, '"[^"]+"', 1, 2) object_clue_2
from   v$sql_reoptimization_hints h
where  h.sql_id = '&&sql_id'
and   (nullif('&&child_no','') is null or h.child_number = to_number(nullif('&&child_no','')))
and    h.hint_text like '%OPT_ESTIMATE%'
order by h.child_number, h.hint_id;

prompt
prompt --- 4) Full reoptimization hints correlated with cursor plan ---

column hint_text format a120 word_wrapped

select h.sql_id,
       h.child_number,
       s.plan_hash_value,
       s.is_reoptimizable,
       h.hint_id,
       h.hint_text
from   v$sql_reoptimization_hints h
       left join v$sql s
         on s.sql_id = h.sql_id
        and s.child_number = h.child_number
where  h.sql_id = '&&sql_id'
and   (nullif('&&child_no','') is null or h.child_number = to_number(nullif('&&child_no','')))
order by h.child_number, h.hint_id;

prompt
prompt --- Action hints ---
prompt 1) If IS_REOPTIMIZABLE=Y, Oracle intends a hard parse on next execution.
prompt 2) If OPT_ESTIMATE hints exist, feedback-based reoptimization was recorded in memory.
prompt 3) Compare child cursors and plan_hash_value before/after subsequent execution.
prompt 4) To disable globally (test with caution): _optimizer_use_feedback=FALSE.


spool off
exit;
