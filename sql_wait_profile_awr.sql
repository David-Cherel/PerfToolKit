-- #############################################################################################################
-- FILE: sql_wait_profile_awr.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Builds an AWR wait profile for a SQL_ID across a snapshot window, breaking down DB time by wait class,
-- wait event, and CPU proxy to explain where execution time is spent and why the SQL is slow.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze (e.g., 'cm1fyt76dwbkb').
-- &2 (begin_snap_id) - NUMBER - Starting AWR SNAP_ID (e.g., 10521).
-- &3 (end_snap_id) - NUMBER - Ending AWR SNAP_ID (e.g., 10527).
-- &4 (instance_number) - NUMBER - RAC instance filter; use 0 for all instances (e.g., 1 or 0).
--
-- OUTPUT DESCRIPTION:
-- Two result sets:
-- 1. Wait Profile by Event: event-level ASH sample counts, estimated seconds, and percentage of SQL time.
-- 2. Wait Profile by Class + CPU: wait-class totals with execution normalization (avg seconds per execution).
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Is this SQL slow because of CPU, I/O, concurrency, or commit waits?
-- Which wait event contributes most to SQL elapsed time?
-- What percentage of SQL time is CPU versus non-CPU waits?
-- Is User I/O the dominant wait class for this SQL_ID?
-- Did wait profile change across snapshots in the selected period?
-- Are concurrency waits driving the slowdown?
-- What is the average wait time per execution for this SQL_ID?
-- Is the SQL mostly waiting on storage-related events?
-- Does the wait profile indicate plan inefficiency or external contention?
-- Which wait class should be targeted first for remediation?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : sql_wait_profile_awr.sql cm1fyt76dwbkb 10521 10527 0
-- #############################################################################################################


spool sql_wait_profile_awr.log

set pages 9999
set lines 240
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define sql_id          = '&1'
define begin_snap_id   = '&2'
define end_snap_id     = '&3'
define instance_number = '&4'

-- Validate required parameters for AWR SQL wait profile analysis.
declare
  l_sql_id    varchar2(13);
  l_begin     number;
  l_end       number;
  l_inst      number;
begin
  if '&&sql_id' is null or '&&begin_snap_id' is null or '&&end_snap_id' is null or '&&instance_number' is null then
    raise_application_error(-20701,
      'Usage: @sql_wait_profile_awr.sql <SQL_ID> <BEGIN_SNAP_ID> <END_SNAP_ID> <INSTANCE_NUMBER|0>');
  end if;

  l_sql_id := lower('&&sql_id');
  l_begin  := to_number('&&begin_snap_id');
  l_end    := to_number('&&end_snap_id');
  l_inst   := to_number('&&instance_number');

  if not regexp_like(l_sql_id, '^[[:alnum:]]{13}$') then
    raise_application_error(-20702, 'Invalid SQL_ID format: ' || l_sql_id);
  end if;

  if l_begin > l_end then
    raise_application_error(-20703, 'BEGIN_SNAP_ID must be <= END_SNAP_ID.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt SQL wait profile from AWR ASH for SQL_ID=&&sql_id BEGIN_SNAP=&&begin_snap_id END_SNAP=&&end_snap_id
prompt INSTANCE=&&instance_number
prompt =====================================================================================================
prompt NOTE: wait-time seconds below are estimated from ASH sample counts (sample_count * 10 seconds).

column wait_event          format a45
column wait_class          format a18
column sample_count        format 999,999,999,999
column est_seconds         format 999,999,999,990.99
column pct_of_total        format 999,990.99
column executions          format 999,999,999,999
column avg_sec_per_exec    format 999,999,999,990.999

prompt
prompt --- 1) Wait profile by event (including ON CPU) ---

-- Aggregate ASH samples by SQL event to show dominant wait contributors for selected SQL_ID.
with ash_base as (
  select case
           when a.session_state = 'ON CPU' then 'ON CPU'
           else nvl(a.event, 'WAITING (EVENT N/A)')
         end as wait_event,
         case
           when a.session_state = 'ON CPU' then 'CPU'
           else nvl(a.wait_class, 'UNKNOWN')
         end as wait_class,
         count(*) as sample_count
    from dba_hist_active_sess_history a
   where a.sql_id = lower('&&sql_id')
     and a.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
     and (to_number('&&instance_number') = 0 or a.instance_number = to_number('&&instance_number'))
   group by case
              when a.session_state = 'ON CPU' then 'ON CPU'
              else nvl(a.event, 'WAITING (EVENT N/A)')
            end,
            case
              when a.session_state = 'ON CPU' then 'CPU'
              else nvl(a.wait_class, 'UNKNOWN')
            end
), totals as (
  select sum(sample_count) as total_samples
    from ash_base
)
select a.wait_event,
       a.wait_class,
       a.sample_count,
       round(a.sample_count * 10, 2) as est_seconds,
       round((a.sample_count / decode(nvl(t.total_samples,0),0,1,t.total_samples)) * 100, 2) as pct_of_total
  from ash_base a
 cross join totals t
 order by a.sample_count desc;

prompt
prompt --- 2) Wait profile by class + CPU with per-execution normalization ---

-- Roll up ASH samples by wait class and correlate with AWR executions delta to normalize per execution.
with ash_class as (
  select case
           when a.session_state = 'ON CPU' then 'CPU'
           else nvl(a.wait_class, 'UNKNOWN')
         end as wait_class,
         count(*) as sample_count
    from dba_hist_active_sess_history a
   where a.sql_id = lower('&&sql_id')
     and a.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
     and (to_number('&&instance_number') = 0 or a.instance_number = to_number('&&instance_number'))
   group by case
              when a.session_state = 'ON CPU' then 'CPU'
              else nvl(a.wait_class, 'UNKNOWN')
            end
),
execs as (
  select nvl(sum(s.executions_delta),0) as executions
    from dba_hist_sqlstat s
   where s.sql_id = lower('&&sql_id')
     and s.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
     and (to_number('&&instance_number') = 0 or s.instance_number = to_number('&&instance_number'))
),
total as (
  select sum(sample_count) as total_samples
    from ash_class
)
select c.wait_class,
       c.sample_count,
       round(c.sample_count * 10, 2) as est_seconds,
       round((c.sample_count / decode(nvl(t.total_samples,0),0,1,t.total_samples)) * 100, 2) as pct_of_total,
       e.executions,
       round((c.sample_count * 10) / decode(nvl(e.executions,0),0,1,e.executions), 3) as avg_sec_per_exec
  from ash_class c
 cross join execs e
 cross join total t
 order by c.sample_count desc;

spool off

exit;