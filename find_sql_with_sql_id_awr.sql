-- #############################################################################################################
-- Find SQL Query in AWR Reports and displays KPI's 
-- Accept a sql_id as inputs (prompted)
-- Display : snap_id, inst_id, begin_interval_time, SQL_ID, plan_hash_value , EXECS ,	AVG_ETIME ,	AVG_LIO , avg_cpu_time
-- Allows to show performance KPI's for that SQL_ID and plan_hash_value 
-- #############################################################################################################


--
define sql_id ='&1'
set pages 9999
set lines 220
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

begin
  if '&&sql_id' is null then
    raise_application_error(-20071, 'SQL_ID is mandatory. Usage: @find_sql_with_sql_id_awr.sql <SQL_ID>');
  end if;
  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20072, 'Invalid SQL_ID format: &&sql_id');
  end if;
end;
/

col obsolete format a9
col begin_interval_time for a22
col snap_count for 999999
col first_seen for a22
col last_seen for a22
col min_avg_etime for 999,999.99999
col max_avg_etime for 999,999.99999
col etime_spread_pct for 999,990.99
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999


spool find_sql_with_sql_id_awr.log


PROMPT ****************************************************************************************************************
PROMPT In AWR Reports  :
PROMPT ****************************************************************************************************************
/* PTK */ select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value,
nvl(executions_delta,0) execs,
(elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime,
(buffer_gets_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_lio,
(disk_reads_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_pio,
(cpu_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_cpu_time
from CDB_HIST_SQLSTAT S, CDB_HIST_SNAPSHOT SS
where sql_id = '&sql_id'
and ss.snap_id = S.snap_id
and ss.DBID = S.DBID
and ss.instance_number = S.instance_number
order by avg_etime desc, ss.snap_id, ss.instance_number, sql_id;

PROMPT ****************************************************************************************************************
PROMPT Summary by PLAN_HASH_VALUE in AWR
PROMPT ****************************************************************************************************************

with base as (
  select s.plan_hash_value,
         ss.begin_interval_time,
         nvl(s.executions_delta,0) execs,
         (s.elapsed_time_delta/decode(nvl(s.executions_delta,0),0,1,s.executions_delta))/1000000 avg_etime
  from cdb_hist_sqlstat s
       join cdb_hist_snapshot ss
         on ss.snap_id = s.snap_id
        and ss.dbid = s.dbid
        and ss.instance_number = s.instance_number
  where s.sql_id = '&&sql_id'
)
select plan_hash_value,
       count(*) snap_count,
       to_char(min(begin_interval_time),'dd-mon-yyyy hh24:mi:ss') first_seen,
       to_char(max(begin_interval_time),'dd-mon-yyyy hh24:mi:ss') last_seen,
       sum(execs) total_execs,
       min(avg_etime) min_avg_etime,
       max(avg_etime) max_avg_etime,
       case when min(avg_etime)=0 then null else ((max(avg_etime)-min(avg_etime))/min(avg_etime))*100 end etime_spread_pct
from base
group by plan_hash_value
order by plan_hash_value;
PROMPT ****************************************************************************************************************



spool off

exit;

