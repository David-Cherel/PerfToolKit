-- #############################################################################################################
-- FILE: sql_wait_timeline_awr.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Produces a time-bucketed AWR ASH wait timeline for one SQL_ID across an incident window, showing wait-event evolution and wait-class distribution (including CPU proxy) to isolate when and how slowdown behavior shifted.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze (e.g., 'cm1fyt76dwbkb').
-- &2 (begin_snap_id) - NUMBER - Starting AWR snapshot ID (e.g., 10521).
-- &3 (end_snap_id) - NUMBER - Ending AWR snapshot ID (e.g., 10527).
-- &4 (instance_number) - NUMBER - RAC instance filter; use 0 for all instances (e.g., 1 or 0).
-- &5 (bucket_minutes) - NUMBER - Timeline bucket size in minutes (1..60, e.g., 10).
--
-- OUTPUT DESCRIPTION:
-- Two result sets:
-- 1. Wait Timeline by Event: bucket_start with wait class/event sample counts, estimated seconds, and share percentage.
-- 2. Wait-Class Trend Pivot: bucket_start with class-level estimated seconds (CPU/User I/O/Concurrency/Application/Commit/Other).
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- At what time did this SQL_ID become slower in the incident window?
-- Which wait events dominated each time bucket for this SQL_ID?
-- Is slowdown driven by CPU, User I/O, concurrency, or commit waits over time?
-- Did the dominant wait event change during the incident timeline?
-- Is there a clear before/after pattern in wait composition?
-- Which bucket has the highest estimated DB time contribution for this SQL_ID?
-- Did wait behavior shift simultaneously across RAC instances?
-- Are short spikes or sustained waits responsible for the slowdown?
-- Is the SQL mostly ON CPU or mostly waiting during peak buckets?
-- Which time range should be correlated with plan/stats/parameter changes?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : sql_wait_timeline_awr.sql cm1fyt76dwbkb 10521 10527 0 10
-- #############################################################################################################

-- Spool report output for incident records.
spool sql_wait_timeline_awr.log

-- Configure SQL*Plus formatting for timeline outputs.
set pages 9999
set lines 260
set verify off
set trimspool on
set tab off
set feedback on
set termout on

-- Stop immediately on SQL errors.
whenever sqlerror exit failure rollback

-- Capture runtime parameters.
define sql_id = '&1'
define begin_snap_id = '&2'
define end_snap_id = '&3'
define instance_number = '&4'
define bucket_minutes = '&5'

-- Validate parameter completeness and value domains.
declare
  l_sql_id varchar2(13);
  l_begin number;
  l_end number;
  l_inst number;
  l_bucket number;
begin
  if '&&sql_id' is null or '&&begin_snap_id' is null or '&&end_snap_id' is null
     or '&&instance_number' is null or '&&bucket_minutes' is null then
    raise_application_error(-20901,
      'Usage: @sql_wait_timeline_awr.sql <SQL_ID> <BEGIN_SNAP_ID> <END_SNAP_ID> <INSTANCE_NUMBER|0> <BUCKET_MINUTES>');
  end if;

  l_sql_id := lower('&&sql_id');
  l_begin := to_number('&&begin_snap_id');
  l_end := to_number('&&end_snap_id');
  l_inst := to_number('&&instance_number');
  l_bucket := to_number('&&bucket_minutes');

  if not regexp_like(l_sql_id, '^[[:alnum:]]{13}$') then
    raise_application_error(-20902, 'Invalid SQL_ID format: ' || l_sql_id);
  end if;

  if l_begin > l_end then
    raise_application_error(-20903, 'BEGIN_SNAP_ID must be <= END_SNAP_ID.');
  end if;

  if l_bucket < 1 or l_bucket > 60 then
    raise_application_error(-20904, 'BUCKET_MINUTES must be between 1 and 60.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt SQL wait timeline from AWR ASH for SQL_ID=&&sql_id BEGIN_SNAP=&&begin_snap_id END_SNAP=&&end_snap_id
prompt INST=&&instance_number BUCKET_MINUTES=&&bucket_minutes
prompt =====================================================================================================
prompt NOTE: Estimated seconds are derived from ASH samples (sample_count * 10 seconds).

-- Format columns for event timeline output.
column bucket_start         format a19
column wait_class           format a16
column wait_event           format a44
column sample_count         format 999,999,999,999
column est_seconds          format 999,999,999,990.99
column pct_in_bucket        format 999,990.99

prompt
prompt --- 1) Wait-event evolution by time bucket ---

-- Build time buckets and aggregate event-level contributions for the target SQL_ID.
with ash_raw as (
  select
    trunc(cast(a.sample_time as date), 'HH24')
      + (floor(to_number(to_char(cast(a.sample_time as date), 'MI')) / to_number('&&bucket_minutes'))
         * to_number('&&bucket_minutes')) / 1440 as bucket_start,
    case
      when a.session_state = 'ON CPU' then 'CPU'
      else nvl(a.wait_class, 'UNKNOWN')
    end as wait_class,
    case
      when a.session_state = 'ON CPU' then 'ON CPU'
      else nvl(a.event, 'WAITING (EVENT N/A)')
    end as wait_event
  from dba_hist_active_sess_history a
  where a.sql_id = lower('&&sql_id')
    and a.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
    and (to_number('&&instance_number') = 0 or a.instance_number = to_number('&&instance_number'))
), by_event as (
  select bucket_start,
         wait_class,
         wait_event,
         count(*) as sample_count
    from ash_raw
   group by bucket_start, wait_class, wait_event
), bucket_total as (
  select bucket_start,
         sum(sample_count) as bucket_samples
    from by_event
   group by bucket_start
)
select to_char(e.bucket_start, 'YYYY-MM-DD HH24:MI') as bucket_start,
       e.wait_class,
       e.wait_event,
       e.sample_count,
       round(e.sample_count * 10, 2) as est_seconds,
       round((e.sample_count / decode(nvl(t.bucket_samples, 0), 0, 1, t.bucket_samples)) * 100, 2) as pct_in_bucket
  from by_event e
  join bucket_total t
    on t.bucket_start = e.bucket_start
 order by e.bucket_start, e.sample_count desc;

-- Format columns for wait-class pivot output.
column cpu_sec              format 999,999,999,990.99
column user_io_sec          format 999,999,999,990.99
column concurrency_sec      format 999,999,999,990.99
column application_sec      format 999,999,999,990.99
column commit_sec           format 999,999,999,990.99
column other_wait_sec       format 999,999,999,990.99
column total_est_sec        format 999,999,999,990.99

prompt
prompt --- 2) Wait-class trend pivot by time bucket ---

-- Roll up timeline to high-level wait classes for quick incident-phase comparison.
with ash_raw as (
  select
    trunc(cast(a.sample_time as date), 'HH24')
      + (floor(to_number(to_char(cast(a.sample_time as date), 'MI')) / to_number('&&bucket_minutes'))
         * to_number('&&bucket_minutes')) / 1440 as bucket_start,
    case
      when a.session_state = 'ON CPU' then 'CPU'
      else nvl(a.wait_class, 'UNKNOWN')
    end as wait_class
  from dba_hist_active_sess_history a
  where a.sql_id = lower('&&sql_id')
    and a.snap_id between to_number('&&begin_snap_id') and to_number('&&end_snap_id')
    and (to_number('&&instance_number') = 0 or a.instance_number = to_number('&&instance_number'))
), by_class as (
  select bucket_start,
         wait_class,
         count(*) as sample_count
    from ash_raw
   group by bucket_start, wait_class
)
select to_char(bucket_start, 'YYYY-MM-DD HH24:MI') as bucket_start,
       round(sum(case when wait_class = 'CPU' then sample_count else 0 end) * 10, 2) as cpu_sec,
       round(sum(case when wait_class = 'User I/O' then sample_count else 0 end) * 10, 2) as user_io_sec,
       round(sum(case when wait_class = 'Concurrency' then sample_count else 0 end) * 10, 2) as concurrency_sec,
       round(sum(case when wait_class = 'Application' then sample_count else 0 end) * 10, 2) as application_sec,
       round(sum(case when wait_class = 'Commit' then sample_count else 0 end) * 10, 2) as commit_sec,
       round(sum(case when wait_class not in ('CPU','User I/O','Concurrency','Application','Commit') then sample_count else 0 end) * 10, 2) as other_wait_sec,
       round(sum(sample_count) * 10, 2) as total_est_sec
  from by_class
 group by bucket_start
 order by bucket_start;

-- End spooling and exit.
spool off

exit;
