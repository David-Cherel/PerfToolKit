
-- #############################################################################################################
-- FILE: get_plan.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Retrieves execution plan information from library cache for a SQL_ID, including cursor performance summary and detailed DBMS_XPLAN output with runtime statistics and outline/adaptive details.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze in library cache (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
--
-- OUTPUT DESCRIPTION:
-- Two result sets: (1) child cursor summary with plan hash and average performance metrics; (2) DBMS_XPLAN.DISPLAY_CURSOR output (ALLSTATS LAST + outline/binds/notes/adaptive). Output is spooled to get_plan.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- What execution plan is currently used in library cache for this SQL_ID?
-- Which child cursors exist and how do their performance metrics compare?
-- What are average elapsed time, CPU time, logical I/O, and physical I/O per child cursor?
-- What runtime row-source statistics are shown in DBMS_XPLAN for this SQL_ID?
-- Are outline hints, bind peeking details, notes, or adaptive plan information available?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : get_plan.sql cm1fyt76dwbkb
-- #############################################################################################################
--
spool get_plan.log

set pages 9999
set lines 220
set long 1000000
set longchunksize 32767
set trimspool on
set verify off
set feedback on
set tab off
set termout on

whenever sqlerror exit failure rollback

define sql_id ='&1'

begin
  if '&&sql_id' is null then
    raise_application_error(-20101, 'SQL_ID is mandatory. Usage: @get_plan.sql <SQL_ID>');
  end if;
  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20102, 'Invalid SQL_ID format: &&sql_id');
  end if;
end;
/


prompt
prompt =====================================================================================================
prompt Plan extraction from library cache for SQL_ID: &&sql_id
prompt =====================================================================================================
prompt NOTE: Read-only script. No data change is performed.

column last_active_time format a19
column avg_etime_s      format 999,999.99999
column avg_cpu_s        format 999,999.99999
column avg_lio          format 999,999,999.9
column avg_pio          format 999,999,999.9

prompt
prompt --- Cursor summary (children, execution profile) ---

/* PTK: Local instance scope with V$SQL (no INST_ID dimension) */
select child_number,
       plan_hash_value,
       executions,
       to_char(last_active_time,'yyyy-mm-dd hh24:mi:ss') last_active_time,
       (elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_etime_s,
       (cpu_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_cpu_s,
       buffer_gets/decode(nvl(executions,0),0,1,executions) avg_lio,
       disk_reads/decode(nvl(executions,0),0,1,executions) avg_pio,
       is_obsolete
from v$sql
where sql_id = '&&sql_id'
order by avg_etime_s desc, child_number;

prompt
prompt --- Execution plan (ALLSTATS LAST +OUTLINE) ---

select *
from table(
  dbms_xplan.display_cursor(
    sql_id          => '&&sql_id',
    cursor_child_no => null,
    format          => 'ALLSTATS LAST ALL +OUTLINE +PEEKED_BINDS +NOTE +ADAPTIVE'
  )
);

prompt
prompt --- Action hints ---
prompt 1) If multiple child cursors exist, compare top children by AVG_ETIME_S above.
prompt 2) If A-Rows diverge heavily from E-Rows, investigate object/column stats and bind skew.
prompt 3) If this SQL is aged out from cache, use @get_plan_awr.sql <SQL_ID> [PLAN_HASH_VALUE].


spool off
exit;
