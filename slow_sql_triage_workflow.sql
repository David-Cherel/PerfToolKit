
-- #############################################################################################################
-- FILE: slow_sql_triage_workflow.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Executes an end-to-end first-touch triage workflow for unknown slow SQL by combining slowdown scope,
-- top SQL candidate ranking, and immediate diagnostic script hints into one standardized incident report.
--
-- INPUT PARAMETERS:
-- &1 (analysis_mode) - STRING - REALTIME|AWR (e.g., 'AWR').
-- &2 (begin_snap_id_or_minutes_back) - NUMBER - AWR begin SNAP_ID in AWR mode, or minutes back in REALTIME mode.
-- &3 (end_snap_id_or_top_n) - NUMBER - AWR end SNAP_ID in AWR mode, or realtime shortlist scope value.
-- &4 (instance_number) - NUMBER - RAC instance filter; use 0 for all instances.
-- &5 (top_n_sql) - NUMBER - Number of SQL candidates to include in triage report.
-- &6 (order_metric) - STRING - ELAPSED|CPU|LIO|PIO|EXECS.
--
-- OUTPUT DESCRIPTION:
-- Three result sets:
-- 1. Triage Context: selected scope, mode, and filters used for incident reproducibility.
-- 2. Top SQL Candidates: ranked SQL_ID/plan candidates with execution and resource KPIs.
-- 3. Diagnostic Starter Hints: recommended next PTK scripts per candidate SQL_ID based on KPI patterns.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- What is the quickest shortlist of SQL_IDs to investigate for this slowdown?
-- Which SQL_ID should be analyzed first based on impact metrics?
-- Is the incident better treated with realtime or AWR evidence?
-- Which plan hash values are associated with top offenders?
-- Which offenders show signs of plan instability or regression?
-- Which offenders likely need cardinality/statistics diagnostics first?
-- Which offenders likely need ACS/cursor-sharing diagnostics first?
-- What PTK scripts should be run next for each candidate SQL_ID?
-- Can first-line support produce a consistent triage report in one execution?
-- How can unknown slow SQL be reduced to actionable SQL_ID diagnosis steps rapidly?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : slow_sql_triage_workflow.sql AWR 10521 10527 0 20 ELAPSED
-- #############################################################################################################


spool slow_sql_triage_workflow.log

set pages 9999
set lines 260
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define analysis_mode              = upper('&1')
define begin_snap_or_minutes_back = '&2'
define end_snap_or_top_n          = '&3'
define instance_number            = '&4'
define top_n_sql                  = '&5'
define order_metric               = upper('&6')

-- Validate workflow mode and input parameters.
declare
  l_mode        varchar2(20);
  l_p2          number;
  l_p3          number;
  l_inst        number;
  l_top_sql     number;
  l_metric      varchar2(20);
begin
  if '&&analysis_mode' is null or '&&begin_snap_or_minutes_back' is null
     or '&&end_snap_or_top_n' is null or '&&instance_number' is null
     or '&&top_n_sql' is null or '&&order_metric' is null then
    raise_application_error(-20901,
      'Usage: @slow_sql_triage_workflow.sql <REALTIME|AWR> <P2> <P3> <INSTANCE_NUMBER|0> <TOP_N_SQL> <ELAPSED|CPU|LIO|PIO|EXECS>');
  end if;

  l_mode    := upper('&&analysis_mode');
  l_p2      := to_number('&&begin_snap_or_minutes_back');
  l_p3      := to_number('&&end_snap_or_top_n');
  l_inst    := to_number('&&instance_number');
  l_top_sql := to_number('&&top_n_sql');
  l_metric  := upper('&&order_metric');

  if l_mode not in ('REALTIME','AWR') then
    raise_application_error(-20902, 'ANALYSIS_MODE must be REALTIME or AWR.');
  end if;

  if l_top_sql < 1 then
    raise_application_error(-20903, 'TOP_N_SQL must be >= 1.');
  end if;

  if l_metric not in ('ELAPSED','CPU','LIO','PIO','EXECS') then
    raise_application_error(-20904, 'ORDER_METRIC must be ELAPSED|CPU|LIO|PIO|EXECS.');
  end if;

  if l_mode = 'AWR' and l_p2 > l_p3 then
    raise_application_error(-20905, 'In AWR mode, BEGIN_SNAP_ID must be <= END_SNAP_ID.');
  end if;

  if l_mode = 'REALTIME' and l_p2 < 1 then
    raise_application_error(-20906, 'In REALTIME mode, MINUTES_BACK must be >= 1.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Slow SQL triage workflow
prompt MODE=&&analysis_mode P2=&&begin_snap_or_minutes_back P3=&&end_snap_or_top_n INST=&&instance_number
prompt TOP_N_SQL=&&top_n_sql ORDER_METRIC=&&order_metric
prompt =====================================================================================================

column triage_scope         format a24
column scope_value          format a50
column generated_at         format a19
column note                 format a100

prompt
prompt --- 1) Triage context ---

-- Provide the analysis scope context for incident reproducibility.
select 'ANALYSIS_MODE' as triage_scope,
       '&&analysis_mode' as scope_value,
       to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') as generated_at,
       case
         when '&&analysis_mode' = 'AWR' then 'P2=BEGIN_SNAP_ID, P3=END_SNAP_ID'
         else 'P2=MINUTES_BACK, P3=TOP_N in live shortlist'
       end as note
  from dual
union all
select 'INSTANCE_FILTER', '&&instance_number', to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'),
       '0 means all instances in RAC'
  from dual
union all
select 'ORDER_METRIC', '&&order_metric', to_char(sysdate,'yyyy-mm-dd hh24:mi:ss'),
       'Ranking metric for SQL offenders'
  from dual;

column sql_id           format a13
column plan_hash_value  format 9999999999
column executions       format 999,999,999,999
column elapsed_s        format 999,999,999,990.999
column cpu_s            format 999,999,999,990.999
column lio              format 999,999,999,999,999
column pio              format 999,999,999,999,999
column avg_elapsed_ms   format 999,999,999,990.999
column source_type      format a10
column source_context   format a40

prompt
prompt --- 2) Top SQL candidates ---

-- Return a unified candidate list from AWR mode or realtime mode.
with awr_candidates as (
  select 'AWR' as source_type,
         'snap ' || '&&begin_snap_or_minutes_back' || '-' || '&&end_snap_or_top_n' as source_context,
         s.sql_id,
         s.plan_hash_value,
         sum(s.executions_delta) as executions,
         sum(s.elapsed_time_delta)/1e6 as elapsed_s,
         sum(s.cpu_time_delta)/1e6 as cpu_s,
         sum(s.buffer_gets_delta) as lio,
         sum(s.disk_reads_delta) as pio
    from dba_hist_sqlstat s
   where '&&analysis_mode' = 'AWR'
     and s.snap_id between to_number('&&begin_snap_or_minutes_back') and to_number('&&end_snap_or_top_n')
     and (to_number('&&instance_number') = 0 or s.instance_number = to_number('&&instance_number'))
   group by s.sql_id, s.plan_hash_value
),
rt_candidates as (
  select 'REALTIME' as source_type,
         'last ' || '&&begin_snap_or_minutes_back' || ' min' as source_context,
         q.sql_id,
         q.plan_hash_value,
         sum(q.executions) as executions,
         sum(q.elapsed_time)/1e6 as elapsed_s,
         sum(q.cpu_time)/1e6 as cpu_s,
         sum(q.buffer_gets) as lio,
         sum(q.disk_reads) as pio
    from gv$sql q
   where '&&analysis_mode' = 'REALTIME'
     and q.last_active_time >= sysdate - (to_number('&&begin_snap_or_minutes_back') / 1440)
     and (to_number('&&instance_number') = 0 or q.inst_id = to_number('&&instance_number'))
   group by q.sql_id, q.plan_hash_value
),
combined as (
  select * from awr_candidates
  union all
  select * from rt_candidates
), ranked as (
  select c.*,
         round((c.elapsed_s*1000)/decode(nvl(c.executions,0),0,1,c.executions),3) as avg_elapsed_ms,
         row_number() over (
           order by
             case when '&&order_metric' = 'ELAPSED' then c.elapsed_s end desc,
             case when '&&order_metric' = 'CPU'     then c.cpu_s end desc,
             case when '&&order_metric' = 'LIO'     then c.lio end desc,
             case when '&&order_metric' = 'PIO'     then c.pio end desc,
             case when '&&order_metric' = 'EXECS'   then c.executions end desc,
             c.elapsed_s desc
         ) as rn
    from combined c
)
select source_type,
       source_context,
       sql_id,
       plan_hash_value,
       executions,
       elapsed_s,
       cpu_s,
       lio,
       pio,
       avg_elapsed_ms
  from ranked
 where rn <= to_number('&&top_n_sql')
 order by rn;

column recommended_next_step format a70
column rationale             format a90

prompt
prompt --- 3) Diagnostic starter hints ---

-- Suggest next PTK scripts based on candidate KPI fingerprints.
with awr_candidates as (
  select s.sql_id,
         s.plan_hash_value,
         sum(s.executions_delta) as executions,
         sum(s.elapsed_time_delta)/1e6 as elapsed_s,
         sum(s.cpu_time_delta)/1e6 as cpu_s,
         sum(s.buffer_gets_delta) as lio,
         sum(s.disk_reads_delta) as pio
    from dba_hist_sqlstat s
   where '&&analysis_mode' = 'AWR'
     and s.snap_id between to_number('&&begin_snap_or_minutes_back') and to_number('&&end_snap_or_top_n')
     and (to_number('&&instance_number') = 0 or s.instance_number = to_number('&&instance_number'))
   group by s.sql_id, s.plan_hash_value
),
rt_candidates as (
  select q.sql_id,
         q.plan_hash_value,
         sum(q.executions) as executions,
         sum(q.elapsed_time)/1e6 as elapsed_s,
         sum(q.cpu_time)/1e6 as cpu_s,
         sum(q.buffer_gets) as lio,
         sum(q.disk_reads) as pio
    from gv$sql q
   where '&&analysis_mode' = 'REALTIME'
     and q.last_active_time >= sysdate - (to_number('&&begin_snap_or_minutes_back') / 1440)
     and (to_number('&&instance_number') = 0 or q.inst_id = to_number('&&instance_number'))
   group by q.sql_id, q.plan_hash_value
),
combined as (
  select * from awr_candidates
  union all
  select * from rt_candidates
), ranked as (
  select c.*,
         round((c.elapsed_s*1000)/decode(nvl(c.executions,0),0,1,c.executions),3) as avg_elapsed_ms,
         row_number() over (
           order by
             case when '&&order_metric' = 'ELAPSED' then c.elapsed_s end desc,
             case when '&&order_metric' = 'CPU'     then c.cpu_s end desc,
             case when '&&order_metric' = 'LIO'     then c.lio end desc,
             case when '&&order_metric' = 'PIO'     then c.pio end desc,
             case when '&&order_metric' = 'EXECS'   then c.executions end desc,
             c.elapsed_s desc
         ) as rn
    from combined c
)
select r.sql_id,
       r.plan_hash_value,
       case
         when r.pio > r.lio * 0.20 then 'Run get_plan.sql + sql_wait_profile_awr.sql + table_stats_complete.sql'
         when r.cpu_s > r.elapsed_s * 0.70 then 'Run get_plan.sql + cardinality_misestimate_diagnosis.sql + acs_diagnosis.sql'
         when r.executions > 1000 and r.avg_elapsed_ms > 50 then 'Run compare_child_cursors_kpi.sql + cursor_reason.sql + stats_feedback_diagnosis.sql'
         else 'Run get_plan.sql + awr_plan_change.sql + spd_sqlid_diagnosis.sql'
       end as recommended_next_step,
       case
         when r.pio > r.lio * 0.20 then 'I/O-heavy fingerprint suggests access path/stats/storage investigation first.'
         when r.cpu_s > r.elapsed_s * 0.70 then 'CPU-heavy fingerprint suggests join/cardinality/selectivity diagnosis first.'
         when r.executions > 1000 and r.avg_elapsed_ms > 50 then 'High-frequency moderate latency suggests cursor variant or bind behavior impact.'
         else 'General regression path: verify plan changes, directives, and baseline stability.'
       end as rationale
  from ranked r
 where r.rn <= to_number('&&top_n_sql')
 order by r.rn;

spool off
exit;
