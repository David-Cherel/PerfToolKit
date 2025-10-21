-- #############################################################################################################
-- Author:      David Cherel from Kerry Osborne
-- SQL script to attempt to find SQL statements with plan instability.
-- Usage:       This scripts prompts for two values, both of which can be left blank.
--
--              min_stddev: the minimum "normalized" standard deviation between plans
--                          (the default is 2)
--
--              min_etime:  only include statements that have an avg. etime > this value
--                          (the default is .1 second)
--
--             Updated to handle very long running SQL statements that cross snapshots.
--
-- See http://kerryosborne.oracle-guy.com/2008/10/unstable-plans/ for more info.
-- #############################################################################################################

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--           unstable_plans_statspack.sql min_stddev min_etime
-- Example : unstable_plans_statspack.sql 2 0.1 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


spool unstable_plans_statspack.log

define min_stddev ='&1'
define min_etime ='&2'

alter session set current_schema=PERFSTAT;

set lines 180
col execs for 999,999,999
col min_etime for 999,999.99
col max_etime for 999,999.99
col avg_etime for 999,999.999
col avg_lio for 999,999,999.9
col norm_stddev for 999,999.9999
col begin_interval_time for a30
col node for 99999
break on plan_hash_value on startup_time skip 1
select * from (
select sql_id, sum(execs), min(avg_etime) min_etime, max(avg_etime) max_etime, stddev_etime/min(avg_etime) norm_stddev
from (
select sql_id, plan_hash_value, execs, avg_etime,
stddev(avg_etime) over (partition by sql_id) stddev_etime 
from (select  sqpu.sql_id, sqpu.plan_hash_value,
sum(nvl(summary.executions,0)) execs,
(sum(ELAPSED_TIME)/decode(sum(nvl(summary.executions,0)),0,1,sum(summary.executions)))/1000000 avg_etime,
(sum(BUFFER_GETS)/decode(sum(nvl(summary.executions,0)),0,1,sum(summary.executions))) avg_lio,
(sum(DISK_READS)/decode(sum(nvl(summary.executions,0)),0,1,sum(summary.executions))) avg_pio,
(sum(CPU_TIME)/decode(sum(nvl(summary.executions,0)),0,1,sum(summary.executions)))/1000000 avg_cpu_time
from STATS$SQL_SUMMARY summary, stats$sql_plan_usage sqpu , stats$snapshot snap
where sqpu.sql_id = summary.sql_id
and snap.snap_id = summary.snap_id
and snap.snap_id = sqpu.snap_id
and snap.instance_number = summary.instance_number
and snap.instance_number = sqpu.instance_number
and ELAPSED_TIME > 0
and snap.snap_id > nvl('&earliest_snap_id',0)
group by sqpu.sql_id, sqpu.plan_hash_value
)
)
group by sql_id, stddev_etime
)
where norm_stddev > nvl(to_number('&min_stddev'),2)
and max_etime > nvl(to_number('&min_etime'),1/10)
order by norm_stddev
/

spool off

exit
