-- #############################################################################################################
-- FILE: incident_change_correlator.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Correlates SQL regression signals for one SQL_ID across an incident window by combining snapshot performance and plan switches with AWR parameter modifications and related table statistics updates in one chronological analysis report.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to investigate (e.g., 'cm1fyt76dwbkb').
-- &2 (begin_snap_id) - NUMBER - Beginning AWR snapshot ID of the incident window (e.g., 10521).
-- &3 (end_snap_id) - NUMBER - Ending AWR snapshot ID of the incident window (e.g., 10527).
-- &4 (instance_number) - NUMBER - RAC instance filter; use 0 for all instances (e.g., 1 or 0).
--
-- OUTPUT DESCRIPTION:
-- Three result sets:
-- 1. SQL Snapshot Trend: per-snapshot SQL KPIs and plan hash values with previous-plan comparison.
-- 2. Correlated Change Timeline: chronological event stream containing PLAN_SWITCH, PARAM_CHANGE, and STATS_UPDATE markers.
-- 3. Related Table Stats Updates: detailed stats-history rows for SQL-referenced objects inside the incident period.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Did this SQL_ID experience a plan switch during the incident window?
-- When did performance metrics degrade versus prior snapshots?
-- Which snapshots show the highest average elapsed time per execution?
-- Did initialization parameter changes occur near the regression timing?
-- Which parameter values changed, and on which instance/container?
-- Were table statistics refreshed for objects used by this SQL_ID during the incident?
-- Which object stats updates happened closest to the plan switch timestamp?
-- Is regression timing more aligned with plan changes, parameter changes, or stats updates?
-- Did multiple change types cluster in a short period (change burst)?
-- What timeline should be prioritized for deeper root-cause analysis?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : incident_change_correlator.sql cm1fyt76dwbkb 10521 10527 0
-- #############################################################################################################

-- Spool output to keep a durable incident correlation report.
spool incident_change_correlator.log

-- Configure SQL*Plus display behavior for wide timeline output.
set pages 9999
set lines 260
set verify off
set trimspool on
set tab off
set feedback on
set termout on

-- Stop on any SQL error to avoid misleading partial reports.
whenever sqlerror exit failure rollback

-- Capture input parameters.
define sql_id = '&1'
define begin_snap_id = '&2'
define end_snap_id = '&3'
define instance_number = '&4'

-- Validate required parameters and value domains.
declare
  l_sql_id varchar2(13);
  l_begin number;
  l_end number;
  l_inst number;
begin
  if '&&sql_id' is null or '&&begin_snap_id' is null or '&&end_snap_id' is null or '&&instance_number' is null then
    raise_application_error(-21001,
      'Usage: @incident_change_correlator.sql <SQL_ID> <BEGIN_SNAP_ID> <END_SNAP_ID> <INSTANCE_NUMBER|0>');
  end if;

  l_sql_id := lower('&&sql_id');
  l_begin := to_number('&&begin_snap_id');
  l_end := to_number('&&end_snap_id');
  l_inst := to_number('&&instance_number');

  if not regexp_like(l_sql_id, '^[[:alnum:]]{13}$') then
    raise_application_error(-21002, 'Invalid SQL_ID format: ' || l_sql_id);
  end if;

  if l_begin > l_end then
    raise_application_error(-21003, 'BEGIN_SNAP_ID must be <= END_SNAP_ID.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Incident change correlator for SQL_ID=&&sql_id BEGIN_SNAP=&&begin_snap_id END_SNAP=&&end_snap_id INST=&&instance_number
prompt =====================================================================================================

-- Define formatting for SQL trend section.
column begin_time            format a19
column end_time              format a19
column plan_changed_flag     format a5
column plan_hash_value       format 9999999999999
column prev_plan_hash_value  format 9999999999999
column executions            format 999,999,999,999
column elapsed_s             format 999,999,999,990.99
column avg_elapsed_ms        format 999,999,999,990.99
column cpu_s                 format 999,999,999,990.99
column lio                   format 999,999,999,999
column pio                   format 999,999,999,999

prompt
prompt --- 1) SQL snapshot trend with plan-switch indicator ---

-- Build snapshot KPI trend and detect plan transitions between consecutive snapshots.
with trend as (
  select s.snap_id,
         sn.instance_number,
         sn.begin_interval_time,
         sn.end_interval_time,
         s.plan_hash_value,
         s.executions_delta as executions,
         s.elapsed_time_delta / 1e6 as elapsed_s,
         s.cpu_time_delta / 1e6 as cpu_s,
         s.buffer_gets_delta as lio,
         s.disk_reads_delta as pio,
         lag(s.plan_hash_value) over (
           partition by s.sql_id, sn.instance_number
           order by s.snap_id
         ) as prev_plan_hash_value
    from dba_hist_sqlstat s
    join dba_hist_snapshot sn
      on sn.snap_id = s.snap_id
     and sn.dbid = s.dbid
     and sn.instance_number = s.instance_number
   where s.sql_id = lower('&&sql_id')
     and s.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
     and (to_number('&&instance_number') = 0 or s.instance_number = to_number('&&instance_number'))
)
select snap_id,
       instance_number,
       to_char(begin_interval_time, 'YYYY-MM-DD HH24:MI:SS') as begin_time,
       to_char(end_interval_time, 'YYYY-MM-DD HH24:MI:SS') as end_time,
       plan_hash_value,
       prev_plan_hash_value,
       case
         when prev_plan_hash_value is null then 'N'
         when prev_plan_hash_value <> plan_hash_value then 'Y'
         else 'N'
       end as plan_changed_flag,
       executions,
       round(elapsed_s, 2) as elapsed_s,
       round((elapsed_s * 1000) / decode(nvl(executions,0),0,1,executions), 2) as avg_elapsed_ms,
       round(cpu_s, 2) as cpu_s,
       lio,
       pio
  from trend
 order by snap_id, instance_number;

-- Define formatting for unified timeline section.
column event_time            format a19
column event_type            format a14
column event_scope           format a80
column event_details         format a120

prompt
prompt --- 2) Correlated change timeline (PLAN_SWITCH / PARAM_CHANGE / STATS_UPDATE) ---

-- Produce one chronological event stream to align performance regression with configuration/statistics changes.
with snap_window as (
  select min(sn.begin_interval_time) as begin_time,
         max(sn.end_interval_time) as end_time
    from dba_hist_snapshot sn
   where sn.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
     and (to_number('&&instance_number') = 0 or sn.instance_number = to_number('&&instance_number'))
),
plan_switch as (
  select sn.end_interval_time as event_time,
         'PLAN_SWITCH' as event_type,
         'INST=' || s.instance_number || ' SNAP=' || s.snap_id as event_scope,
         'SQL_ID=' || s.sql_id ||
         ' PREV_PLAN=' || lag(s.plan_hash_value) over (partition by s.sql_id, s.instance_number order by s.snap_id) ||
         ' NEW_PLAN=' || s.plan_hash_value ||
         ' ELAPSED_S=' || to_char(round(s.elapsed_time_delta/1e6,2)) ||
         ' EXECS=' || to_char(s.executions_delta) as event_details,
         s.sql_id,
         s.instance_number,
         s.snap_id,
         s.plan_hash_value,
         lag(s.plan_hash_value) over (partition by s.sql_id, s.instance_number order by s.snap_id) as prev_plan_hash_value
    from dba_hist_sqlstat s
    join dba_hist_snapshot sn
      on sn.snap_id = s.snap_id
     and sn.dbid = s.dbid
     and sn.instance_number = s.instance_number
   where s.sql_id = lower('&&sql_id')
     and s.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
     and (to_number('&&instance_number') = 0 or s.instance_number = to_number('&&instance_number'))
),
param_changes as (
  select sn.end_interval_time as event_time,
         'PARAM_CHANGE' as event_type,
         'INST=' || p.instance_number || ' CON_ID=' || p.con_id || ' SNAP=' || p.snap_id as event_scope,
         p.parameter_name,
         'PARAM=' || p.parameter_name ||
         ' OLD=' || nvl(lag(p.value) over (partition by p.instance_number, p.con_id, p.parameter_name order by p.snap_id), '<NULL>') ||
         ' NEW=' || nvl(p.value, '<NULL>') as event_details,
         lag(p.value) over (partition by p.instance_number, p.con_id, p.parameter_name order by p.snap_id) as old_value,
         p.value as new_value
    from dba_hist_parameter p
    join dba_hist_snapshot sn
      on sn.snap_id = p.snap_id
     and sn.dbid = p.dbid
     and sn.instance_number = p.instance_number
     and sn.con_id = p.con_id
   where p.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
     and (to_number('&&instance_number') = 0 or p.instance_number = to_number('&&instance_number'))
),
related_tables as (
  select distinct owner, table_name
    from (
      select p.object_owner as owner,
             p.object_name as table_name
        from dba_hist_sql_plan p
       where p.sql_id = lower('&&sql_id')
         and p.object_owner is not null
         and p.object_name is not null
         and p.object_type like 'TABLE%'
      union all
      select i.table_owner as owner,
             i.table_name as table_name
        from dba_hist_sql_plan p
        join dba_indexes i
          on i.owner = p.object_owner
         and i.index_name = p.object_name
       where p.sql_id = lower('&&sql_id')
         and p.object_owner is not null
         and p.object_name is not null
         and p.object_type like 'INDEX%'
    )
),
stats_updates as (
  select h.stats_update_time as event_time,
         'STATS_UPDATE' as event_type,
         'OWNER=' || h.owner || ' TABLE=' || h.table_name as event_scope,
         'STATS_UPDATE_TIME=' || to_char(h.stats_update_time, 'YYYY-MM-DD HH24:MI:SS') as event_details
    from dba_tab_stats_history h
    join related_tables rt
      on rt.owner = h.owner
     and rt.table_name = h.table_name
    cross join snap_window sw
   where h.stats_update_time between sw.begin_time and sw.end_time
),
unioned as (
  select event_time, event_type, event_scope, event_details
    from plan_switch
   where prev_plan_hash_value is not null
     and prev_plan_hash_value <> plan_hash_value
  union all
  select event_time, event_type, event_scope, event_details
    from param_changes
   where nvl(old_value, '#NULL#') <> nvl(new_value, '#NULL#')
  union all
  select event_time, event_type, event_scope, event_details
    from stats_updates
)
select to_char(event_time, 'YYYY-MM-DD HH24:MI:SS') as event_time,
       event_type,
       event_scope,
       event_details
  from unioned
 order by event_time, event_type;

-- Define formatting for detailed stats history section.
column owner                format a30
column table_name           format a35
column stats_update_time    format a19

prompt
prompt --- 3) Detailed table statistics updates for SQL-related objects in incident window ---

-- Display detailed stats-update records for tables referenced by the investigated SQL_ID.
with snap_window as (
  select min(sn.begin_interval_time) as begin_time,
         max(sn.end_interval_time) as end_time
    from dba_hist_snapshot sn
   where sn.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
     and (to_number('&&instance_number') = 0 or sn.instance_number = to_number('&&instance_number'))
),
related_tables as (
  select distinct owner, table_name
    from (
      select p.object_owner as owner,
             p.object_name as table_name
        from dba_hist_sql_plan p
       where p.sql_id = lower('&&sql_id')
         and p.object_owner is not null
         and p.object_name is not null
         and p.object_type like 'TABLE%'
      union all
      select i.table_owner as owner,
             i.table_name as table_name
        from dba_hist_sql_plan p
        join dba_indexes i
          on i.owner = p.object_owner
         and i.index_name = p.object_name
       where p.sql_id = lower('&&sql_id')
         and p.object_owner is not null
         and p.object_name is not null
         and p.object_type like 'INDEX%'
    )
)
select h.owner,
       h.table_name,
       to_char(h.stats_update_time, 'YYYY-MM-DD HH24:MI:SS') as stats_update_time
  from dba_tab_stats_history h
  join related_tables rt
    on rt.owner = h.owner
   and rt.table_name = h.table_name
  cross join snap_window sw
 where h.stats_update_time between sw.begin_time and sw.end_time
 order by h.stats_update_time, h.owner, h.table_name;

-- Finalize report output and exit.
spool off

exit;
