-- #############################################################################################################
-- FILE: active_long_running_sql.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Lists currently active long-running SQL from GV$SESSION and GV$SQL_MONITOR with elapsed time, wait
-- class/event, blocking context, and execution progress to identify live SQL sessions causing immediate impact.
--
-- INPUT PARAMETERS:
-- &1 (min_elapsed_seconds) - NUMBER - Minimum elapsed runtime in seconds to include (e.g., 30).
-- &2 (instance_number) - NUMBER - RAC instance filter; use 0 for all instances (e.g., 2 or 0).
-- &3 (include_idle_waits) - STRING - Include idle waits: Y|N (e.g., 'N').
-- &4 (top_n) - NUMBER - Max rows to display (e.g., 50).
--
-- OUTPUT DESCRIPTION:
-- Two result sets:
-- 1. Active Long SQL Sessions: inst_id, sid/serial, username, module/action, sql_id/sql_exec_id,
--    elapsed seconds, wait class/event, state, blocking session, machine/program.
-- 2. SQL Monitor Runtime Detail: status, parallel info, elapsed/cpu/io stats, temp usage, and I/O volume.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL statements are currently running longer than expected?
-- Which live SQL session is consuming the most elapsed time right now?
-- What wait class and event are active for each long-running SQL?
-- Is the slowdown caused by blocking or lock contention?
-- Which module/action or program is generating the active long SQL?
-- Is the issue isolated to one RAC instance?
-- Which SQL has the highest current I/O load according to SQL Monitor?
-- Are parallel executions involved in the current slowdown?
-- Which session should be prioritized for immediate troubleshooting?
-- Is runtime indicating normal progress or stalled execution?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : active_long_running_sql.sql 30 0 N 50
-- #############################################################################################################

spool active_long_running_sql.log

set pages 9999
set lines 260
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define min_elapsed_seconds = '&1'
define instance_number    = '&2'
define include_idle_waits = upper('&3')
define top_n              = '&4'

-- Validate required parameters and accepted include-idle value.
declare
  l_min_elapsed number;
  l_instance    number;
  l_top_n       number;
  l_idle_flag   varchar2(1);
begin
  if '&&min_elapsed_seconds' is null or '&&instance_number' is null
     or '&&include_idle_waits' is null or '&&top_n' is null then
    raise_application_error(-20601,
      'Usage: @active_long_running_sql.sql <MIN_ELAPSED_SECONDS> <INSTANCE_NUMBER|0> <Y|N> <TOP_N>');
  end if;

  l_min_elapsed := to_number('&&min_elapsed_seconds');
  l_instance    := to_number('&&instance_number');
  l_top_n       := to_number('&&top_n');
  l_idle_flag   := upper('&&include_idle_waits');

  if l_min_elapsed < 0 then
    raise_application_error(-20602, 'MIN_ELAPSED_SECONDS must be >= 0.');
  end if;

  if l_top_n < 1 then
    raise_application_error(-20603, 'TOP_N must be >= 1.');
  end if;

  if l_idle_flag not in ('Y','N') then
    raise_application_error(-20604, 'INCLUDE_IDLE_WAITS must be Y or N.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Active long-running SQL: MIN_ELAPSED_SECONDS=&&min_elapsed_seconds INST=&&instance_number
prompt INCLUDE_IDLE_WAITS=&&include_idle_waits TOP_N=&&top_n
prompt =====================================================================================================

column username           format a20
column module             format a28
column action             format a28
column machine            format a28
column program            format a35
column sql_id             format a13
column sql_exec_id        format 999999999999999999
column status             format a8
column session_state      format a12
column wait_class         format a15
column event              format a40
column elapsed_s          format 999,999,999.999
column blocking_instance  format 99999
column blocking_session   format 999999
column sql_monitor_status format a15
column sid_serial         format a20

prompt
prompt --- 1) Active long SQL sessions (GV$SESSION + GV$SQL_MONITOR) ---

-- Correlate currently active sessions with SQL monitor facts to highlight live expensive SQL.
with live as (
  select s.inst_id,
         s.sid,
         s.serial#,
         s.username,
         s.module,
         s.action,
         s.machine,
         s.program,
         s.sql_id,
         s.sql_child_number,
         s.sql_exec_id,
         s.status,
         s.state as session_state,
         s.wait_class,
         s.event,
         s.blocking_instance,
         s.blocking_session,
         (sysdate - s.sql_exec_start) * 86400 as elapsed_s,
         m.status as sql_monitor_status,
         m.px_servers_requested,
         m.px_servers_allocated,
         m.sql_plan_hash_value,
         m.elapsed_time/1e6 as monitor_elapsed_s,
         m.cpu_time/1e6 as monitor_cpu_s,
         m.buffer_gets as monitor_lio,
         m.disk_reads as monitor_pio,
         m.direct_writes as monitor_direct_writes,
         m.temp_space/1024/1024 as monitor_temp_mb,
         m.physical_read_bytes/1024/1024 as monitor_phys_read_mb,
         m.physical_write_bytes/1024/1024 as monitor_phys_write_mb
    from gv$session s
    left join gv$sql_monitor m
      on m.inst_id = s.inst_id
     and m.sid = s.sid
     and m.sql_id = s.sql_id
     and m.sql_exec_id = s.sql_exec_id
   where s.type = 'USER'
     and s.status = 'ACTIVE'
     and s.sql_id is not null
     and (to_number('&&instance_number') = 0 or s.inst_id = to_number('&&instance_number'))
), ranked as (
  select l.*,
         row_number() over (order by l.elapsed_s desc nulls last) as rn
    from live l
   where nvl(l.elapsed_s,0) >= to_number('&&min_elapsed_seconds')
     and (upper('&&include_idle_waits') = 'Y' or nvl(l.wait_class,'?') <> 'Idle')
)
select r.inst_id,
       r.sid || ',' || r.serial# as sid_serial,
       r.username,
       r.module,
       r.action,
       r.machine,
       r.program,
       r.sql_id,
       r.sql_child_number,
       r.sql_exec_id,
       r.status,
       r.session_state,
       r.wait_class,
       r.event,
       round(r.elapsed_s,3) as elapsed_s,
       r.blocking_instance,
       r.blocking_session,
       r.sql_monitor_status,
       r.sql_plan_hash_value
  from ranked r
 where r.rn <= to_number('&&top_n')
 order by r.rn;

column monitor_elapsed_s       format 999,999,999.999
column monitor_cpu_s           format 999,999,999.999
column monitor_lio             format 999,999,999,999
column monitor_pio             format 999,999,999,999
column monitor_direct_writes   format 999,999,999,999
column monitor_temp_mb         format 999,999,999.99
column monitor_phys_read_mb    format 999,999,999.99
column monitor_phys_write_mb   format 999,999,999.99
column px_servers_requested    format 99999
column px_servers_allocated    format 99999

prompt
prompt --- 2) SQL Monitor runtime details for selected active SQL ---

-- Surface monitor-level runtime resource consumption for active SQL shortlist.
with live as (
  select s.inst_id,
         s.sid,
         s.serial#,
         s.sql_id,
         s.sql_exec_id,
         (sysdate - s.sql_exec_start) * 86400 as elapsed_s,
         m.status as sql_monitor_status,
         m.px_servers_requested,
         m.px_servers_allocated,
         m.elapsed_time/1e6 as monitor_elapsed_s,
         m.cpu_time/1e6 as monitor_cpu_s,
         m.buffer_gets as monitor_lio,
         m.disk_reads as monitor_pio,
         m.direct_writes as monitor_direct_writes,
         m.temp_space/1024/1024 as monitor_temp_mb,
         m.physical_read_bytes/1024/1024 as monitor_phys_read_mb,
         m.physical_write_bytes/1024/1024 as monitor_phys_write_mb,
         m.fetches,
         m.process_name
    from gv$session s
    left join gv$sql_monitor m
      on m.inst_id = s.inst_id
     and m.sid = s.sid
     and m.sql_id = s.sql_id
     and m.sql_exec_id = s.sql_exec_id
   where s.type = 'USER'
     and s.status = 'ACTIVE'
     and s.sql_id is not null
     and (to_number('&&instance_number') = 0 or s.inst_id = to_number('&&instance_number'))
), ranked as (
  select l.*,
         row_number() over (order by l.elapsed_s desc nulls last) as rn
    from live l
   where nvl(l.elapsed_s,0) >= to_number('&&min_elapsed_seconds')
)
select inst_id,
       sid || ',' || serial# as sid_serial,
       sql_id,
       sql_exec_id,
       round(elapsed_s,3) as elapsed_s,
       sql_monitor_status,
       px_servers_requested,
       px_servers_allocated,
       round(monitor_elapsed_s,3) as monitor_elapsed_s,
       round(monitor_cpu_s,3) as monitor_cpu_s,
       monitor_lio,
       monitor_pio,
       monitor_direct_writes,
       round(monitor_temp_mb,2) as monitor_temp_mb,
       round(monitor_phys_read_mb,2) as monitor_phys_read_mb,
       round(monitor_phys_write_mb,2) as monitor_phys_write_mb,
       fetches,
       process_name
  from ranked
 where rn <= to_number('&&top_n')
 order by rn;

spool off

exit;