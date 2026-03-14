-- #############################################################################################################
-- Displays all plan hash values and performance kpi's for any queries related to a table  
-- It scans all history from AWR tables
-- Allows to detect performance changes for that SQL, and determine approximatively the time of change
-- #############################################################################################################
-- object_name := &&1

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : awr_plan_change_on_object.sql S_LOY_TXN 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set pages 9999
set lines 220
set verify off
set trimspool on
set tab off
set feedback on
set termout on
set serveroutput on

whenever sqlerror exit failure rollback

define object_name ='&1'

begin
  if '&&object_name' is null then
    raise_application_error(-20001, 'Parameter OBJECT_NAME is mandatory. Usage: @awr_plan_change_on_object.sql <OBJECT_NAME>');
  end if;
end;
/

col execs for 999,999,999
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999
col begin_interval_time for a22
col node for 99999
col snap_count for 999999
col first_seen for a22
col last_seen for a22
col min_avg_etime for 999,999.99999
col max_avg_etime for 999,999.99999
col etime_spread_pct for 999,990.99

spool awr_plan_change_on_object.log

prompt
prompt =====================================================================================================
prompt AWR plan change analysis for object: &&object_name
prompt =====================================================================================================

break on sql_id on plan_hash_value skip 1
/* PTK */ select ss.snap_id, ss.instance_number node, begin_interval_time, sql_id, plan_hash_value,
nvl(executions_delta,0) execs,
(elapsed_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_etime,
(buffer_gets_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_lio,
(disk_reads_delta/decode(nvl(executions_delta,0),0,1,executions_delta)) avg_pio,
(cpu_time_delta/decode(nvl(executions_delta,0),0,1,executions_delta))/1000000 avg_cpu_time
from CDB_HIST_SQLSTAT S, CDB_HIST_SNAPSHOT SS, V$DATABASE DB
where sql_id in (select distinct sql_id from cdb_hist_sql_plan sp , V$DATABASE DB where sp.object_name=upper('&object_name') and sp.CON_DBID=DB.CON_DBID)
and ss.snap_id = S.snap_id
and ss.instance_number = S.instance_number
and ss.DBID = S.DBID
and S.CON_DBID=DB.CON_DBID
order by 4,5,1;

prompt
prompt --------------------------------
prompt Summary by SQL_ID and PLAN_HASH_VALUE
prompt --------------------------------

with base as (
  select s.sql_id,
         s.plan_hash_value,
         ss.begin_interval_time,
         nvl(s.executions_delta,0) execs,
         (s.elapsed_time_delta/decode(nvl(s.executions_delta,0),0,1,s.executions_delta))/1000000 avg_etime
  from cdb_hist_sqlstat s
       join cdb_hist_snapshot ss
         on ss.snap_id = s.snap_id
        and ss.instance_number = s.instance_number
        and ss.dbid = s.dbid
       join v$database db
         on s.con_dbid = db.con_dbid
  where s.sql_id in (
      select distinct sp.sql_id
      from cdb_hist_sql_plan sp
           join v$database db2
             on sp.con_dbid = db2.con_dbid
      where sp.object_name = upper('&&object_name')
  )
)
select sql_id,
       plan_hash_value,
       count(*) snap_count,
       to_char(min(begin_interval_time),'dd-mon-yyyy hh24:mi:ss') first_seen,
       to_char(max(begin_interval_time),'dd-mon-yyyy hh24:mi:ss') last_seen,
       sum(execs) total_execs,
       min(avg_etime) min_avg_etime,
       max(avg_etime) max_avg_etime,
       case when min(avg_etime)=0 then null else ((max(avg_etime)-min(avg_etime))/min(avg_etime))*100 end etime_spread_pct
from base
group by sql_id, plan_hash_value
order by sql_id, plan_hash_value;

spool off

exit;
