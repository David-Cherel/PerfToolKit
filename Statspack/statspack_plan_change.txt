select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value,
nvl(executions,0) execs,
(elapsed_time/decode(nvl(executions,0),0,1,executions))/1000000 avg_etime,
(buffer_gets/decode(nvl(executions,0),0,1,executions)) avg_lio,
(disk_reads/decode(nvl(executions,0),0,1,executions)) avg_pio,
(cpu_time/decode(nvl(executions,0),0,1,executions))/1000000 avg_cpu_time
from STATS$SQL_SUMMARY S, STATS$SNAPSHOT SS
where sql_id = '&sql_id'
and ss.snap_id = S.snap_id
and ss.instance_number = S.instance_number
order by 1, 2, 3;