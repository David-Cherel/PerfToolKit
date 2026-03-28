-- #############################################################################################################
-- FILE: ash_session_timeline.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Produces a session-centric ASH timeline for one SID/SERIAL across a time window, exposing wait-event evolution, SQL_ID transitions, blocking context, and activity intensity to reconstruct incident behavior at session level.
--
-- INPUT PARAMETERS:
-- &1 (instance_number) - NUMBER - RAC instance of the target session (e.g., 1).
-- &2 (sid) - NUMBER - Session SID to analyze (e.g., 1234).
-- &3 (serial_number) - NUMBER - Session SERIAL# to analyze (e.g., 56789).
-- &4 (minutes_back) - NUMBER - Lookback window in minutes from current time (e.g., 60).
-- &5 (bucket_minutes) - NUMBER - Bucket size in minutes for timeline aggregation (1..30, e.g., 5).
--
-- OUTPUT DESCRIPTION:
-- Two result sets:
-- 1. Session Event Timeline: time buckets with wait class/event, SQL_ID, sample count, estimated seconds, and blocked-state indicators.
-- 2. Session SQL Transition Summary: SQL_ID-level timeline summary with first/last seen times, active sample volume, and dominant wait signature.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- What was this session doing over the incident timeline?
-- Which wait events dominated this session at different times?
-- Did this session switch SQL_ID during the slowdown period?
-- When did this session become blocked, and by whom?
-- Was this session mostly ON CPU or waiting during peak impact?
-- Which time bucket had the highest activity for this session?
-- Did the session wait profile change before and after a specific timestamp?
-- What is the dominant wait signature for each SQL_ID executed by this session?
-- Is the incident caused by one SQL_ID or multiple SQL transitions in the same session?
-- Which exact session-phase should be correlated with plan, stats, or parameter changes?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : ash_session_timeline.sql 1 1234 56789 60 5
-- #############################################################################################################

-- Spool timeline output for forensic incident review.
spool ash_session_timeline.log

-- Configure SQL*Plus reporting options for timeline readability.
set pages 9999
set lines 280
set verify off
set trimspool on
set tab off
set feedback on
set termout on

-- Stop on SQL failure to avoid partial analysis results.
whenever sqlerror exit failure rollback

-- Define runtime parameters.
define instance_number = '&1'
define sid = '&2'
define serial_number = '&3'
define minutes_back = '&4'
define bucket_minutes = '&5'

-- Validate mandatory parameters and accepted boundaries.
declare
  l_inst number;
  l_sid number;
  l_serial number;
  l_minutes number;
  l_bucket number;
begin
  if '&&instance_number' is null or '&&sid' is null or '&&serial_number' is null
     or '&&minutes_back' is null or '&&bucket_minutes' is null then
    raise_application_error(-21201,
      'Usage: @ash_session_timeline.sql <INSTANCE_NUMBER> <SID> <SERIAL#> <MINUTES_BACK> <BUCKET_MINUTES>');
  end if;

  l_inst := to_number('&&instance_number');
  l_sid := to_number('&&sid');
  l_serial := to_number('&&serial_number');
  l_minutes := to_number('&&minutes_back');
  l_bucket := to_number('&&bucket_minutes');

  if l_minutes < 1 then
    raise_application_error(-21202, 'MINUTES_BACK must be >= 1.');
  end if;

  if l_bucket < 1 or l_bucket > 30 then
    raise_application_error(-21203, 'BUCKET_MINUTES must be between 1 and 30.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt ASH session timeline - INST=&&instance_number SID=&&sid SERIAL#=&&serial_number MINUTES_BACK=&&minutes_back
prompt BUCKET_MINUTES=&&bucket_minutes
prompt =====================================================================================================
prompt NOTE: Estimated seconds are ASH-sample approximations (sample_count * 1 second in GV$ASH).

-- Format timeline result columns.
column bucket_start             format a19
column sql_id                   format a13
column wait_class               format a15
column wait_event               format a42
column sample_count             format 999,999,999
column est_seconds              format 999,999,999.99
column pct_in_bucket            format 999,990.99
column blocked_samples          format 999,999,999
column blocker_sid              format a18

prompt
prompt --- 1) Session event timeline by bucket ---

-- Build bucketed ASH timeline for the target session and capture wait/blocking behavior evolution.
with ash_raw as (
  select
    trunc(cast(a.sample_time as date), 'HH24')
      + (floor(to_number(to_char(cast(a.sample_time as date), 'MI')) / to_number('&&bucket_minutes'))
         * to_number('&&bucket_minutes')) / 1440 as bucket_start,
    nvl(a.sql_id, 'NO_SQL_ID') as sql_id,
    case
      when a.session_state = 'ON CPU' then 'CPU'
      else nvl(a.wait_class, 'UNKNOWN')
    end as wait_class,
    case
      when a.session_state = 'ON CPU' then 'ON CPU'
      else nvl(a.event, 'WAITING (EVENT N/A)')
    end as wait_event,
    case when a.blocking_session is not null then 1 else 0 end as is_blocked,
    nvl(to_char(a.blocking_inst_id) || ':' || to_char(a.blocking_session), 'N/A') as blocker_sid
  from gv$active_session_history a
  where a.inst_id = to_number('&&instance_number')
    and a.session_id = to_number('&&sid')
    and a.session_serial# = to_number('&&serial_number')
    and a.sample_time >= systimestamp - numtodsinterval(to_number('&&minutes_back'), 'MINUTE')
), bucket_totals as (
  select bucket_start,
         count(*) as bucket_samples
    from ash_raw
   group by bucket_start
), by_event as (
  select bucket_start,
         sql_id,
         wait_class,
         wait_event,
         count(*) as sample_count,
         sum(is_blocked) as blocked_samples,
         min(case when is_blocked = 1 then blocker_sid end) as blocker_sid
    from ash_raw
   group by bucket_start, sql_id, wait_class, wait_event
)
select to_char(e.bucket_start, 'YYYY-MM-DD HH24:MI') as bucket_start,
       e.sql_id,
       e.wait_class,
       e.wait_event,
       e.sample_count,
       round(e.sample_count * 1, 2) as est_seconds,
       round((e.sample_count / decode(nvl(t.bucket_samples,0),0,1,t.bucket_samples)) * 100, 2) as pct_in_bucket,
       e.blocked_samples,
       nvl(e.blocker_sid, 'N/A') as blocker_sid
  from by_event e
  join bucket_totals t
    on t.bucket_start = e.bucket_start
 order by e.bucket_start, e.sample_count desc;

-- Format SQL transition summary columns.
column first_seen              format a19
column last_seen               format a19
column total_samples           format 999,999,999
column active_samples          format 999,999,999
column waiting_samples         format 999,999,999
column dominant_wait_class     format a18
column dominant_wait_event     format a44

prompt
prompt --- 2) Session SQL transition summary ---

-- Summarize per-SQL_ID session behavior to identify phase changes and dominant waits.
with ash_raw as (
  select a.sample_time,
         nvl(a.sql_id, 'NO_SQL_ID') as sql_id,
         case when a.session_state = 'ON CPU' then 1 else 0 end as on_cpu_flag,
         case when a.session_state = 'WAITING' then 1 else 0 end as waiting_flag,
         case
           when a.session_state = 'ON CPU' then 'CPU'
           else nvl(a.wait_class, 'UNKNOWN')
         end as wait_class,
         case
           when a.session_state = 'ON CPU' then 'ON CPU'
           else nvl(a.event, 'WAITING (EVENT N/A)')
         end as wait_event
    from gv$active_session_history a
   where a.inst_id = to_number('&&instance_number')
     and a.session_id = to_number('&&sid')
     and a.session_serial# = to_number('&&serial_number')
     and a.sample_time >= systimestamp - numtodsinterval(to_number('&&minutes_back'), 'MINUTE')
),
base as (
  select sql_id,
         min(sample_time) as first_seen,
         max(sample_time) as last_seen,
         count(*) as total_samples,
         sum(on_cpu_flag) as active_samples,
         sum(waiting_flag) as waiting_samples
    from ash_raw
   group by sql_id
),
dominant as (
  select sql_id,
         wait_class,
         wait_event,
         cnt,
         row_number() over (partition by sql_id order by cnt desc, wait_class, wait_event) as rn
    from (
      select sql_id,
             wait_class,
             wait_event,
             count(*) as cnt
        from ash_raw
       group by sql_id, wait_class, wait_event
    )
)
select b.sql_id,
       to_char(b.first_seen, 'YYYY-MM-DD HH24:MI:SS') as first_seen,
       to_char(b.last_seen, 'YYYY-MM-DD HH24:MI:SS') as last_seen,
       b.total_samples,
       b.active_samples,
       b.waiting_samples,
       d.wait_class as dominant_wait_class,
       d.wait_event as dominant_wait_event
  from base b
  left join dominant d
    on d.sql_id = b.sql_id
   and d.rn = 1
 order by b.first_seen;

-- Finalize spool output and exit script.
spool off

exit;
