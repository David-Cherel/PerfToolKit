-- #############################################################################################################
-- FILE: top_sql_awr_window.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Ranks top SQL statements in a selected AWR snapshot window by chosen KPI (elapsed time, CPU, logical I/O,
-- physical I/O, executions), to quickly identify the most expensive SQL_ID candidates during a slowdown period.
--
-- INPUT PARAMETERS:
-- &1 (begin_snap_id) - NUMBER - Starting AWR SNAP_ID for the analysis window (e.g., 10521).
-- &2 (end_snap_id) - NUMBER - Ending AWR SNAP_ID for the analysis window (e.g., 10527).
-- &3 (instance_number) - NUMBER - RAC instance filter; use 0 for all instances (e.g., 1 or 0).
-- &4 (top_n) - NUMBER - Number of top SQL rows to return (e.g., 30).
-- &5 (order_metric) - STRING - Ranking metric: ELAPSED|CPU|LIO|PIO|EXECS (e.g., 'ELAPSED').
--
-- OUTPUT DESCRIPTION:
-- Two result sets:
-- 1. Ranked Top SQL in AWR window: SQL_ID, PLAN_HASH_VALUE, executions delta, elapsed/cpu/i/o deltas,
--    avg elapsed per exec, schema/module, and time range.
-- 2. Metric Summary by SQL_ID: consolidated totals per SQL_ID (all plans) for quick shortlist selection.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL_ID consumed the most elapsed time in this slowdown window?
-- Which SQL_ID consumed the most CPU in this window?
-- Which SQL statements generated the highest logical I/O?
-- Which SQL statements generated the highest physical I/O?
-- Which SQL_ID has high average elapsed time per execution?
-- Did one SQL_ID dominate total workload during selected snapshots?
-- Which plan hash values contributed most for a top SQL_ID?
-- Is the top SQL concentrated on one instance or spread across RAC instances?
-- Which SQL_ID should be investigated first after identifying a hot window?
-- What is the top-N offender list for this incident period?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : top_sql_awr_window.sql 10521 10527 0 30 ELAPSED
-- #############################################################################################################


spool top_sql_awr_window.log

set pages 9999
set lines 240
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define begin_snap_id   = '&1'
define end_snap_id     = '&2'
define instance_number = '&3'
define top_n           = '&4'
define order_metric    = upper('&5')

-- Validate required parameters and accepted ranking metric.
declare
  l_begin_snap   number;
  l_end_snap     number;
  l_instance     number;
  l_top_n        number;
  l_metric       varchar2(30);
begin
  if '&&begin_snap_id' is null or '&&end_snap_id' is null or '&&instance_number' is null
     or '&&top_n' is null or '&&order_metric' is null then
    raise_application_error(-20501,
      'Usage: @top_sql_awr_window.sql <BEGIN_SNAP_ID> <END_SNAP_ID> <INSTANCE_NUMBER|0> <TOP_N> <ELAPSED|CPU|LIO|PIO|EXECS>');
  end if;

  l_begin_snap := to_number('&&begin_snap_id');
  l_end_snap   := to_number('&&end_snap_id');
  l_instance   := to_number('&&instance_number');
  l_top_n      := to_number('&&top_n');
  l_metric     := upper('&&order_metric');

  if l_begin_snap > l_end_snap then
    raise_application_error(-20502, 'BEGIN_SNAP_ID must be <= END_SNAP_ID.');
  end if;

  if l_top_n < 1 then
    raise_application_error(-20503, 'TOP_N must be >= 1.');
  end if;

  if l_metric not in ('ELAPSED','CPU','LIO','PIO','EXECS') then
    raise_application_error(-20504, 'ORDER_METRIC must be one of ELAPSED|CPU|LIO|PIO|EXECS.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Top SQL from AWR window: BEGIN_SNAP=&&begin_snap_id END_SNAP=&&end_snap_id INST=&&instance_number
prompt ORDER_METRIC=&&order_metric TOP_N=&&top_n
prompt =====================================================================================================

column sql_id              format a13
column parsing_schema_name format a20
column module              format a30
column sql_text            format a100
column plan_hash_value     format 9999999999
column executions          format 999,999,999,999
column elapsed_s           format 999,999,999,990.999
column cpu_s               format 999,999,999,990.999
column lio                 format 999,999,999,999,999
column pio                 format 999,999,999,999,999
column avg_elapsed_ms      format 999,999,999,990.999
column begin_time          format a19
column end_time            format a19

prompt
prompt --- 1) Ranked Top SQL in AWR window (SQL_ID + PLAN_HASH_VALUE) ---

-- Aggregate AWR deltas by SQL_ID and PLAN_HASH_VALUE in selected snapshot window.
with agg as (
  select s.sql_id,
         s.plan_hash_value,
         min(sn.begin_interval_time) as begin_time,
         max(sn.end_interval_time)   as end_time,
         sum(s.executions_delta)     as executions,
         sum(s.elapsed_time_delta)/1e6 as elapsed_s,
         sum(s.cpu_time_delta)/1e6     as cpu_s,
         sum(s.buffer_gets_delta)      as lio,
         sum(s.disk_reads_delta)       as pio,
         max(s.parsing_schema_name)    as parsing_schema_name,
         max(s.module)                 as module
    from dba_hist_sqlstat s
    join dba_hist_snapshot sn
      on sn.snap_id = s.snap_id
     and sn.dbid = s.dbid
     and sn.instance_number = s.instance_number
   where s.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
     and (to_number('&&instance_number') = 0 or s.instance_number = to_number('&&instance_number'))
   group by s.sql_id, s.plan_hash_value
), ranked as (
  select a.*,
         round((a.elapsed_s*1000) / decode(nvl(a.executions,0),0,1,a.executions), 3) as avg_elapsed_ms,
         row_number() over (
           order by
             case when '&&order_metric' = 'ELAPSED' then a.elapsed_s end desc,
             case when '&&order_metric' = 'CPU'     then a.cpu_s end desc,
             case when '&&order_metric' = 'LIO'     then a.lio end desc,
             case when '&&order_metric' = 'PIO'     then a.pio end desc,
             case when '&&order_metric' = 'EXECS'   then a.executions end desc,
             a.elapsed_s desc
         ) as rn
    from agg a
)
select r.sql_id,
       r.plan_hash_value,
       r.executions,
       r.elapsed_s,
       r.cpu_s,
       r.lio,
       r.pio,
       r.avg_elapsed_ms,
       r.parsing_schema_name,
       r.module,
       to_char(r.begin_time, 'yyyy-mm-dd hh24:mi:ss') as begin_time,
       to_char(r.end_time,   'yyyy-mm-dd hh24:mi:ss') as end_time
  from ranked r
 where r.rn <= to_number('&&top_n')
 order by r.rn;

prompt
prompt --- 2) Consolidated metric summary by SQL_ID (all plans combined) ---

-- Consolidate all plan hash values under each SQL_ID for fast shortlist review.
with agg as (
  select s.sql_id,
         sum(s.executions_delta)       as executions,
         sum(s.elapsed_time_delta)/1e6 as elapsed_s,
         sum(s.cpu_time_delta)/1e6     as cpu_s,
         sum(s.buffer_gets_delta)      as lio,
         sum(s.disk_reads_delta)       as pio,
         count(distinct s.plan_hash_value) as distinct_plans
    from dba_hist_sqlstat s
   where s.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
     and (to_number('&&instance_number') = 0 or s.instance_number = to_number('&&instance_number'))
   group by s.sql_id
), ranked as (
  select a.*,
         round((a.elapsed_s*1000) / decode(nvl(a.executions,0),0,1,a.executions), 3) as avg_elapsed_ms,
         row_number() over (
           order by
             case when '&&order_metric' = 'ELAPSED' then a.elapsed_s end desc,
             case when '&&order_metric' = 'CPU'     then a.cpu_s end desc,
             case when '&&order_metric' = 'LIO'     then a.lio end desc,
             case when '&&order_metric' = 'PIO'     then a.pio end desc,
             case when '&&order_metric' = 'EXECS'   then a.executions end desc,
             a.elapsed_s desc
         ) as rn
    from agg a
)
select sql_id,
       executions,
       elapsed_s,
       cpu_s,
       lio,
       pio,
       avg_elapsed_ms,
       distinct_plans
  from ranked
 where rn <= to_number('&&top_n')
 order by rn;

spool off

exit;