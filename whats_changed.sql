-- #############################################################################################################
-- FILE: whats_changed.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Identifies SQL statements whose average elapsed time changed significantly before versus after a reference date (SYSDATE-days_ago) using AWR history, returning slower/faster SQL candidates ranked by normalized variability and execution impact.
--
-- INPUT PARAMETERS:
-- &1 (days_ago) - NUMBER - Number of days back used as the before/after split point (e.g., 7)
-- &2 (min_stddev) - NUMBER - Minimum normalized standard deviation threshold to keep significant changes (e.g., 2)
-- &3 (min_etime) - NUMBER - Minimum average elapsed time (seconds) to filter out very fast SQL (e.g., 0.1)
--
-- OUTPUT DESCRIPTION:
-- One result set showing SQL_ID, executions, average elapsed time before/after split, percentage delta,
-- normalized standard deviation, and a Faster/Slower label to highlight statements with meaningful performance change.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL statements became significantly slower after a recent change window?
-- Which SQL statements became significantly faster after a recent change window?
-- What is the average elapsed time before and after the reference date for each SQL_ID?
-- What percentage elapsed-time delta is observed per SQL_ID?
-- Which SQL_IDs have the highest normalized variability in elapsed time?
-- How many executions support the observed performance change for each SQL_ID?
-- Which SQL statements exceed a minimum elapsed-time relevance threshold?
-- What SQL statements should be prioritized for regression root-cause analysis?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : whats_changed.sql 7 2 0.1
-- #############################################################################################################
--

spool whats_changed.log

set pages 9999
set lines 180
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define days_ago ='&1'
define min_stddev ='&2'
define min_etime ='&3'

begin
  if '&&days_ago' is null or not regexp_like('&&days_ago', '^[0-9]+(\.[0-9]+)?$') then
    raise_application_error(-20031, 'DAYS_AGO must be numeric (example: 7).');
  end if;
  if '&&min_stddev' is not null and not regexp_like('&&min_stddev', '^[0-9]+(\.[0-9]+)?$') then
    raise_application_error(-20032, 'MIN_STDDEV must be numeric (example: 2).');
  end if;
  if '&&min_etime' is not null and not regexp_like('&&min_etime', '^[0-9]+(\.[0-9]+)?$') then
    raise_application_error(-20033, 'MIN_ETIME must be numeric seconds (example: 0.1).');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt AWR before/after change analysis (days_ago=&&days_ago, min_stddev=&&min_stddev, min_etime=&&min_etime)
prompt =====================================================================================================


col execs for 999,999,999
col before_etime for 999,990.99
col after_etime for 999,990.99
col before_avg_etime for 999,990.99 head AVG_ETIME_BEFORE
col after_avg_etime for 999,990.99 head AVG_ETIME_AFTER
col delta_pct for 999,990.99
col min_etime for 999,990.99
col max_etime for 999,990.99
col avg_etime for 999,990.999
col avg_lio for 999,999,990.9
col norm_stddev for 999,990.9999
col begin_interval_time for a30
col node for 99999
break on plan_hash_value on startup_time skip 1
select * from (
select sql_id, execs, before_avg_etime, after_avg_etime,
       case when before_avg_etime = 0 then null else ((after_avg_etime-before_avg_etime)/before_avg_etime)*100 end delta_pct,
       norm_stddev,
       case when to_number(before_avg_etime) < to_number(after_avg_etime) then 'Slower' else 'Faster' end result
-- select *
from (
select sql_id, sum(execs) execs, sum(before_execs) before_execs, sum(after_execs) after_execs,
       sum(before_avg_etime) before_avg_etime, sum(after_avg_etime) after_avg_etime,
       min(avg_etime) min_etime, max(avg_etime) max_etime, stddev_etime/min(avg_etime) norm_stddev,
       case when sum(before_avg_etime) > sum(after_avg_etime) then 'Slower' else 'Faster' end better_or_worse
from (
select sql_id,
       period_flag,
       execs,
       avg_etime,
       stddev_etime,
       case when period_flag = 'Before' then execs else 0 end before_execs,
       case when period_flag = 'Before' then avg_etime else 0 end before_avg_etime,
       case when period_flag = 'After' then execs else 0 end after_execs,
       case when period_flag = 'After' then avg_etime else 0 end after_avg_etime
from (
select sql_id, period_flag, execs, avg_etime,
stddev(avg_etime) over (partition by sql_id) stddev_etime
from (
select sql_id, period_flag, sum(execs) execs, sum(etime)/sum(decode(execs,0,1,execs)) avg_etime from (
select sql_id, 'Before' period_flag,
nvl(executions_delta,0) execs,
(elapsed_time_delta)/1000000 etime
-- sum((buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta))) avg_lio
from CDB_HIST_SQLSTAT S, CDB_HIST_SNAPSHOT SS, V$DATABASE DB
where ss.snap_id = S.snap_id
and ss.instance_number = S.instance_number
and ss.DBID = S.DBID
and S.CON_DBID=DB.CON_DBID
and executions_delta > 0
and elapsed_time_delta > 0
and ss.begin_interval_time <= sysdate-&&days_ago
union
select sql_id, 'After' period_flag,
nvl(executions_delta,0) execs,
(elapsed_time_delta)/1000000 etime
-- (elapsed_time_delta)/decode(nvl(executions_delta,0),0,1,executions_delta)/1000000 avg_etime
-- sum((buffer_gets_delta/decode(nvl(buffer_gets_delta,0),0,1,executions_delta))) avg_lio
from CDB_HIST_SQLSTAT S, CDB_HIST_SNAPSHOT SS, V$DATABASE DB
where ss.snap_id = S.snap_id
and ss.instance_number = S.instance_number
and ss.DBID = S.DBID
and S.CON_DBID=DB.CON_DBID
and executions_delta > 0
and elapsed_time_delta > 0
and ss.begin_interval_time > sysdate-&&days_ago
-- and s.snap_id >  7113
)
group by sql_id, period_flag
)
)
)
group by sql_id, stddev_etime
)
where norm_stddev > nvl(to_number('&min_stddev'),2)
and max_etime > nvl(to_number('&min_etime'),.1)
)

order by norm_stddev
/

prompt
prompt NOTE: RESULT=Slower means average elapsed time increased after reference date.



spool off
exit
