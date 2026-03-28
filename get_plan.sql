-- #############################################################################################################
-- FILE: get_plan.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Retrieves execution plan information from library cache for a SQL_ID, adds deterministic child-cursor selection, and displays DBMS_XPLAN runtime details with richer cursor context for faster and more reliable root-cause analysis.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze in library cache (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (child_number) - NUMBER - Optional child cursor number; use -1 or blank for auto-selection (e.g., 2 or -1).
-- &3 (min_executions) - NUMBER - Optional minimum executions preference used by auto-selection (default 1, e.g., 5).
-- &4 (top_n) - NUMBER - Optional maximum child rows returned in summary (default 20, e.g., 30).
--
-- OUTPUT DESCRIPTION:
-- Three result sets/sections: (1) deterministic selection context for target child cursor, (2) child cursor summary with extended KPIs and runtime metadata, (3) DBMS_XPLAN.DISPLAY_CURSOR output for selected child (ALLSTATS LAST + outline/binds/notes/adaptive/projection). Output is spooled to get_plan.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which child cursor should be analyzed first for this SQL_ID based on elapsed-time impact?
-- Which child cursors exist and how do their average elapsed/CPU/I/O profiles compare?
-- What execution plan is shown for the selected child cursor in library cache?
-- Are runtime row-source statistics available for this selected child?
-- Are outline hints, bind peeking details, notes, aliases, or adaptive plan details available?
-- Which parsing schema/module is associated with the most expensive child cursor?
-- Is the SQL_ID absent from cache and therefore better analyzed in AWR?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : get_plan.sql cm1fyt76dwbkb -1 5 30
-- #############################################################################################################
--

-- Spool output for auditability and incident sharing.
spool get_plan.log

-- Configure SQL*Plus rendering for large DBMS_XPLAN outputs.
set pages 9999
set lines 260
set long 1000000
set longchunksize 32767
set trimspool on
set verify off
set feedback on
set tab off
set termout on

-- Stop on SQL errors to avoid partial/misleading reports.
whenever sqlerror exit failure rollback

-- Capture user parameters (optional values can be blank).
define sql_id = '&1'
define child_number = '&2'
define min_executions = '&3'
define top_n = '&4'

-- Normalize optional parameters to deterministic defaults.
column effective_child new_value effective_child noprint
select case
         when trim('&&child_number') is null then '-1'
         else trim('&&child_number')
       end as effective_child
from dual;

column effective_min_exec new_value effective_min_exec noprint
select case
         when trim('&&min_executions') is null then '1'
         else trim('&&min_executions')
       end as effective_min_exec
from dual;

column effective_top_n new_value effective_top_n noprint
select case
         when trim('&&top_n') is null then '20'
         else trim('&&top_n')
       end as effective_top_n
from dual;

-- Validate input semantics and child existence (if explicit child is requested).
declare
  l_exists number;
begin
  if '&&sql_id' is null then
    raise_application_error(-20101, 'SQL_ID is mandatory. Usage: @get_plan.sql <SQL_ID> [CHILD_NO|-1] [MIN_EXEC] [TOP_N]');
  end if;

  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20102, 'Invalid SQL_ID format: &&sql_id');
  end if;

  if to_number('&&effective_min_exec') < 0 then
    raise_application_error(-20103, 'MIN_EXECUTIONS must be >= 0.');
  end if;

  if to_number('&&effective_top_n') < 1 then
    raise_application_error(-20104, 'TOP_N must be >= 1.');
  end if;

  if to_number('&&effective_child') < -1 then
    raise_application_error(-20105, 'CHILD_NUMBER must be -1 (auto) or >= 0.');
  end if;

  select count(*)
    into l_exists
    from v$sql
   where sql_id = lower('&&sql_id');

  if l_exists = 0 then
    raise_application_error(-20106, 'SQL_ID ' || lower('&&sql_id') || ' not found in V$SQL cache. Use @get_plan_awr.sql <SQL_ID> [PLAN_HASH_VALUE].');
  end if;

  if to_number('&&effective_child') >= 0 then
    select count(*)
      into l_exists
      from v$sql
     where sql_id = lower('&&sql_id')
       and child_number = to_number('&&effective_child');

    if l_exists = 0 then
      raise_application_error(-20107, 'Requested CHILD_NUMBER not found for SQL_ID in V$SQL cache.');
    end if;
  end if;
end;
/

-- Resolve child cursor deterministically in AUTO mode.
column selected_child new_value selected_child noprint
select case
         when to_number('&&effective_child') = -1 then
           to_char(
             (
               select child_number
                 from (
                   select child_number,
                          nvl(executions,0) as executions,
                          (elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) as avg_etime_s,
                          last_active_time
                     from v$sql
                    where sql_id = lower('&&sql_id')
                    order by case when nvl(executions,0) >= to_number('&&effective_min_exec') then 0 else 1 end,
                             avg_etime_s desc,
                             executions desc,
                             last_active_time desc nulls last,
                             child_number
                 )
                where rownum = 1
             )
           )
         else '&&effective_child'
       end as selected_child
from dual;

prompt
prompt =====================================================================================================
prompt Plan extraction from library cache for SQL_ID: &&sql_id
prompt CHILD_MODE: &&effective_child  SELECTED_CHILD: &&selected_child  MIN_EXECUTIONS: &&effective_min_exec  TOP_N: &&effective_top_n
prompt =====================================================================================================
prompt NOTE: Read-only script. No data change is performed.

-- Define child-summary display formats.
column last_active_time        format a19
column avg_etime_s             format 999,999,999.99999
column avg_cpu_s               format 999,999,999.99999
column avg_lio                 format 999,999,999,999.9
column avg_pio                 format 999,999,999,999.9
column avg_rows                format 999,999,999,999.9
column avg_fetches             format 999,999,999,999.9
column parsing_schema_name     format a25
column module                  format a28
column optimizer_env_hash_value format 99999999999999999999

prompt
prompt --- 1) Cursor summary (children, execution profile, runtime context) ---

-- Rank and display top child cursors with richer diagnostics context.
with children as (
  select child_number,
         plan_hash_value,
         executions,
         to_char(last_active_time,'yyyy-mm-dd hh24:mi:ss') as last_active_time,
         (elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) as avg_etime_s,
         (cpu_time/1000000)/decode(nvl(executions,0),0,1,executions) as avg_cpu_s,
         buffer_gets/decode(nvl(executions,0),0,1,executions) as avg_lio,
         disk_reads/decode(nvl(executions,0),0,1,executions) as avg_pio,
         rows_processed/decode(nvl(executions,0),0,1,executions) as avg_rows,
         fetches/decode(nvl(executions,0),0,1,executions) as avg_fetches,
         parse_calls,
         parsing_schema_name,
         module,
         optimizer_env_hash_value,
         is_obsolete,
         row_number() over (
           order by (elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) desc,
                    nvl(executions,0) desc,
                    child_number
         ) as rn
    from v$sql
   where sql_id = lower('&&sql_id')
)
select child_number,
       plan_hash_value,
       executions,
       last_active_time,
       avg_etime_s,
       avg_cpu_s,
       avg_lio,
       avg_pio,
       avg_rows,
       avg_fetches,
       parse_calls,
       parsing_schema_name,
       module,
       optimizer_env_hash_value,
       is_obsolete
  from children
 where rn <= to_number('&&effective_top_n')
 order by rn;

prompt
prompt --- 2) Execution plan for selected child (ALLSTATS LAST +OUTLINE +PEEKED_BINDS +NOTE +ADAPTIVE) ---

-- Display deterministic child-cursor plan text with runtime stats and metadata.
select *
from table(
  dbms_xplan.display_cursor(
    sql_id          => lower('&&sql_id'),
    cursor_child_no => to_number('&&selected_child'),
    format          => 'ALLSTATS LAST ALL +OUTLINE +PEEKED_BINDS +NOTE +ADAPTIVE +ALIAS +PROJECTION'
  )
);

prompt
prompt --- Action hints ---
prompt 1) Use SELECTED_CHILD as baseline for deeper diagnostics (ACS, cardinality, stats feedback).
prompt 2) If A-Rows diverge heavily from E-Rows, investigate object/column stats and bind skew.
prompt 3) If child churn is high, run @cursor_reason.sql &&sql_id for non-shared-cursor causes.
prompt 4) If SQL is aged out from cache later, use @get_plan_awr.sql <SQL_ID> [PLAN_HASH_VALUE].

-- End spool and terminate script.
spool off
exit;
