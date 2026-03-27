-- #############################################################################################################
-- FILE: compare_child_cursors_kpi.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Compares performance KPIs for two child cursors of the same SQL_ID using V$SQL, showing side-by-side values and deltas for elapsed time, CPU, logical/physical I/O, rows, fetches, memory, and execution behavior.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (child_1) - NUMBER - First child cursor number to compare (e.g., 0).
-- &3 (child_2) - NUMBER - Second child cursor number to compare (e.g., 1).
--
-- OUTPUT DESCRIPTION:
-- Two result sets:
-- 1) Child Cursor Snapshot: Key runtime and optimizer attributes for each selected child cursor.
-- 2) KPI Comparison: Metric-by-metric comparison with child_1 value, child_2 value, absolute delta, and percent change.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which child cursor is faster on average elapsed time for this SQL_ID?
-- Which child cursor consumes more CPU per execution?
-- Which child cursor performs more logical I/O per execution?
-- Which child cursor performs more physical I/O per execution?
-- Are row throughput and fetch behavior different between the two child cursors?
-- Is one child cursor associated with a different plan hash value?
-- Is one child bind-aware while the other is not?
-- Which child cursor has higher memory footprint in library cache?
-- Are execution counts skewed between child cursors?
-- What is the percentage performance gap between both child cursors?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : compare_child_cursors_kpi.sql cm1fyt76dwbkb 0 1
-- #############################################################################################################
--

spool compare_child_cursors_kpi.log

set pages 9999
set lines 240
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define sql_id  = '&1'
define child_1 = '&2'
define child_2 = '&3'

-- Validate inputs and ensure both child cursors exist for the provided SQL_ID.
declare
  l_cnt number;
begin
  if '&&sql_id' is null then
    raise_application_error(-20401, 'SQL_ID is mandatory. Usage: @compare_child_cursors_kpi.sql <SQL_ID> <CHILD_1> <CHILD_2>');
  end if;

  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20402, 'Invalid SQL_ID format: &&sql_id');
  end if;

  if not regexp_like('&&child_1', '^[0-9]+$') or not regexp_like('&&child_2', '^[0-9]+$') then
    raise_application_error(-20403, 'CHILD_1 and CHILD_2 must be numeric.');
  end if;

  if to_number('&&child_1') = to_number('&&child_2') then
    raise_application_error(-20404, 'CHILD_1 and CHILD_2 must be different values.');
  end if;

  select count(distinct child_number)
    into l_cnt
    from v$sql
   where sql_id = '&&sql_id'
     and child_number in (to_number('&&child_1'), to_number('&&child_2'));

  if l_cnt < 2 then
    raise_application_error(-20405, 'One or both child cursors were not found in V$SQL for SQL_ID=&&sql_id');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Child cursor KPI comparison for SQL_ID=&&sql_id  CHILD_1=&&child_1  CHILD_2=&&child_2
prompt =====================================================================================================
prompt NOTE: Read-only report from V$SQL.

column sql_id              format a13
column child_number        format 999999
column plan_hash_value     format 999999999999999
column is_bind_sensitive   format a3
column is_bind_aware       format a3
column is_shareable        format a3
column optimizer_mode      format a12
column parsing_schema_name format a20
column module              format a25
column last_active_time    format a19
column avg_elapsed_ms      format 999,999,999.99
column avg_cpu_ms          format 999,999,999.99
column avg_lio             format 999,999,999,999.99
column avg_pio             format 999,999,999,999.99
column avg_rows            format 999,999,999,999.99
column avg_fetches         format 999,999,999,999.99
column sharable_mem_kb     format 999,999,999,999
column persistent_mem_kb   format 999,999,999,999
column runtime_mem_kb      format 999,999,999,999

prompt
prompt --- 1) Child Cursor Snapshot ---

-- Snapshot each selected child cursor with normalized per-execution KPIs.
select sql_id,
       child_number,
       plan_hash_value,
       is_bind_sensitive,
       is_bind_aware,
       is_shareable,
       optimizer_mode,
       parsing_schema_name,
       module,
       executions,
       parse_calls,
       loads,
       invalidations,
       to_char(last_active_time, 'yyyy-mm-dd hh24:mi:ss') as last_active_time,
       round((elapsed_time/1000)/decode(nvl(executions,0),0,1,executions), 2) as avg_elapsed_ms,
       round((cpu_time/1000)/decode(nvl(executions,0),0,1,executions), 2) as avg_cpu_ms,
       round(buffer_gets/decode(nvl(executions,0),0,1,executions), 2) as avg_lio,
       round(disk_reads/decode(nvl(executions,0),0,1,executions), 2) as avg_pio,
       round(rows_processed/decode(nvl(executions,0),0,1,executions), 2) as avg_rows,
       round(fetches/decode(nvl(executions,0),0,1,executions), 2) as avg_fetches,
       round(sharable_mem/1024,0) as sharable_mem_kb,
       round(persistent_mem/1024,0) as persistent_mem_kb,
       round(runtime_mem/1024,0) as runtime_mem_kb
  from v$sql
 where sql_id = '&&sql_id'
   and child_number in (to_number('&&child_1'), to_number('&&child_2'))
 order by child_number;

column metric_name format a30
column child1_value format 999,999,999,999,990.9999
column child2_value format 999,999,999,999,990.9999
column delta_value  format 999,999,999,999,990.9999
column pct_change   format 999,999,999,990.99

prompt
prompt --- 2) KPI Comparison (CHILD_2 minus CHILD_1) ---

-- Normalize KPIs and compare metric-by-metric between the two chosen child cursors.
with kpi as (
  select child_number,
         executions,
         parse_calls,
         invalidations,
         loads,
         round((elapsed_time/1000)/decode(nvl(executions,0),0,1,executions), 4) as avg_elapsed_ms,
         round((cpu_time/1000)/decode(nvl(executions,0),0,1,executions), 4) as avg_cpu_ms,
         round(buffer_gets/decode(nvl(executions,0),0,1,executions), 4) as avg_lio,
         round(disk_reads/decode(nvl(executions,0),0,1,executions), 4) as avg_pio,
         round(rows_processed/decode(nvl(executions,0),0,1,executions), 4) as avg_rows,
         round(fetches/decode(nvl(executions,0),0,1,executions), 4) as avg_fetches,
         round(end_of_fetch_count/decode(nvl(executions,0),0,1,executions), 4) as avg_eof_count,
         round(sharable_mem/1024,4) as sharable_mem_kb,
         round(persistent_mem/1024,4) as persistent_mem_kb,
         round(runtime_mem/1024,4) as runtime_mem_kb
    from v$sql
   where sql_id = '&&sql_id'
     and child_number in (to_number('&&child_1'), to_number('&&child_2'))
),
metric_rows as (
  select child_number, 'EXECUTIONS'        as metric_name, executions         as metric_value from kpi
  union all select child_number, 'PARSE_CALLS'       as metric_name, parse_calls        as metric_value from kpi
  union all select child_number, 'INVALIDATIONS'     as metric_name, invalidations      as metric_value from kpi
  union all select child_number, 'LOADS'             as metric_name, loads              as metric_value from kpi
  union all select child_number, 'AVG_ELAPSED_MS'    as metric_name, avg_elapsed_ms     as metric_value from kpi
  union all select child_number, 'AVG_CPU_MS'        as metric_name, avg_cpu_ms         as metric_value from kpi
  union all select child_number, 'AVG_LIO'           as metric_name, avg_lio            as metric_value from kpi
  union all select child_number, 'AVG_PIO'           as metric_name, avg_pio            as metric_value from kpi
  union all select child_number, 'AVG_ROWS'          as metric_name, avg_rows           as metric_value from kpi
  union all select child_number, 'AVG_FETCHES'       as metric_name, avg_fetches        as metric_value from kpi
  union all select child_number, 'AVG_EOF_COUNT'     as metric_name, avg_eof_count      as metric_value from kpi
  union all select child_number, 'SHARABLE_MEM_KB'   as metric_name, sharable_mem_kb    as metric_value from kpi
  union all select child_number, 'PERSISTENT_MEM_KB' as metric_name, persistent_mem_kb  as metric_value from kpi
  union all select child_number, 'RUNTIME_MEM_KB'    as metric_name, runtime_mem_kb     as metric_value from kpi
),
comp as (
  select metric_name,
         max(case when child_number = to_number('&&child_1') then metric_value end) as child1_value,
         max(case when child_number = to_number('&&child_2') then metric_value end) as child2_value
    from metric_rows
   group by metric_name
)
select metric_name,
       child1_value,
       child2_value,
       (child2_value - child1_value) as delta_value,
       case
         when nvl(child1_value,0) = 0 then null
         else round(((child2_value - child1_value) / child1_value) * 100, 2)
       end as pct_change
  from comp
 order by metric_name;

prompt
prompt --- Action hints ---
prompt 1) If AVG_ELAPSED_MS and AVG_CPU_MS diverge strongly, check wait events by child cursor.
prompt 2) If AVG_LIO/AVG_PIO differs, compare access paths and object stats per plan.
prompt 3) If one child is bind-aware and the other is not, investigate bind selectivity skew.
prompt 4) Correlate with V$SQL_SHARED_CURSOR reasons when large KPI gaps are observed.

spool off
exit;
