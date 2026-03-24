-- #############################################################################################################
-- FILE: unstable_plans.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Identifies SQL statements with potential execution-plan instability in AWR by comparing average elapsed time across plans and ranking SQL_IDs by normalized standard deviation.
--
-- INPUT PARAMETERS:
-- &1 (min_stddev) - NUMBER - Optional minimum normalized stddev threshold between plans (e.g., 2 or 2.5).
-- &2 (min_etime) - NUMBER - Optional minimum maximum average elapsed time threshold in seconds (e.g., 0.1).
--
-- OUTPUT DESCRIPTION:
-- One ranked result set of unstable SQL candidates with SQL_ID, executions, min/max avg elapsed time, normalized stddev, and elapsed-time spread percentage; output spooled to unstable_plans.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL_IDs show significant elapsed-time instability across execution plans?
-- What is the normalized variability (NORM_STDDEV) for each SQL_ID?
-- Which SQL statements exceed minimum elapsed-time and variability thresholds?
-- How large is elapsed-time spread between best and worst plans for each SQL_ID?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : unstable_plans.sql 2 0.1
-- #############################################################################################################
--
set pages 9999
set lines 180
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define min_stddev ='&1'
define min_etime ='&2'

begin
  if '&&min_stddev' is not null and not regexp_like('&&min_stddev', '^[0-9]+(\.[0-9]+)?$') then
    raise_application_error(-20021, 'MIN_STDDEV must be numeric (example: 2 or 2.5).');
  end if;
  if '&&min_etime' is not null and not regexp_like('&&min_etime', '^[0-9]+(\.[0-9]+)?$') then
    raise_application_error(-20022, 'MIN_ETIME must be numeric seconds (example: 0.1).');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt AWR unstable plans analysis (min_stddev=&&min_stddev, min_etime=&&min_etime)
prompt =====================================================================================================

spool unstable_plans.log

col execs for 999,999,999
col min_etime for 999,999.99
col max_etime for 999,999.99
col avg_etime for 999,999.999
col avg_lio for 999,999,999.9
col norm_stddev for 999,999.9999
col etime_spread_pct for 999,990.99
col begin_interval_time for a30
col node for 99999
break on plan_hash_value on startup_time skip 1
select * from (
select sql_id,
       sum(execs) execs,
       min(avg_etime) min_etime,
       max(avg_etime) max_etime,
       stddev_etime/min(avg_etime) norm_stddev,
       case when min(avg_etime)=0 then null else ((max(avg_etime)-min(avg_etime))/min(avg_etime))*100 end etime_spread_pct
from (
select sql_id, plan_hash_value, execs, avg_etime,
stddev(avg_etime) over (partition by sql_id) stddev_etime 
from (
select sql_id, plan_hash_value,
sum(nvl(executions_delta,0)) execs,
(sum(elapsed_time_delta)/decode(sum(nvl(executions_delta,0)),0,1,sum(executions_delta))/1000000) avg_etime
-- sum((buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta))) avg_lio
from DBA_HIST_SQLSTAT S, DBA_HIST_SNAPSHOT SS
where ss.snap_id = S.snap_id
and ss.instance_number = S.instance_number 
-- and executions_delta > 0
and elapsed_time_delta > 0
and s.snap_id > nvl('&earliest_snap_id',0)
group by sql_id, plan_hash_value
)
)
group by sql_id, stddev_etime
)
where norm_stddev > nvl(to_number('&min_stddev'),2)
and max_etime > nvl(to_number('&min_etime'),1/10)
order by norm_stddev desc
/

prompt
prompt NOTE: Higher NORM_STDDEV and ETIME_SPREAD_PCT indicate stronger instability.

spool off

exit
