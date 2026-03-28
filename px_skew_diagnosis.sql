-- #############################################################################################################
-- FILE: px_skew_diagnosis.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Diagnoses live parallel execution imbalance for active workloads by correlating GV$PX_SESSION topology with recent GV$ACTIVE_SESSION_HISTORY samples, highlighting skew between PX slaves, QC context, and wait/resource asymmetry to prioritize remediation.
--
-- INPUT PARAMETERS:
-- &1 (instance_number) - NUMBER - RAC instance filter; use 0 for all instances (e.g., 1 or 0).
-- &2 (sample_seconds) - NUMBER - ASH lookback window in seconds for skew measurements (e.g., 120).
-- &3 (include_idle_waits) - STRING - Include idle waits in ASH-based skew metrics: Y|N (e.g., 'N').
-- &4 (top_n_qc) - NUMBER - Maximum number of QC groups to display (e.g., 20).
-- &5 (sql_id_filter) - STRING - SQL_ID filter for QC sessions; use '%' for all SQL_IDs (e.g., 'cm1fyt76dwbkb' or '%').
--
-- OUTPUT DESCRIPTION:
-- Two result sets:
-- 1. PX Topology and Runtime Context: QC and slave session mapping with SQL_ID, status, wait class/event, and requested/actual degree.
-- 2. PX Skew Metrics from Recent ASH: per-slave sample distribution, per-QC min/max/avg samples, and imbalance ratio.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Is a parallel execution currently imbalanced across PX slaves?
-- Which QC is associated with the most skewed PX workload right now?
-- Which PX slave sessions are overloaded compared with others?
-- Are PX slaves mostly ON CPU or waiting on a specific event?
-- Is the effective PX degree lower than requested degree for this execution?
-- Is skew isolated to one RAC instance or spread across instances?
-- Which active SQL_ID is currently affected by PX imbalance?
-- Are idle waits hiding apparent PX imbalance in sampling results?
-- What is the max-to-min sample ratio across PX slaves for each QC?
-- Which PX execution should be triaged first for immediate performance gain?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : px_skew_diagnosis.sql 0 120 N 20 %
-- #############################################################################################################

-- Spool report output for operational diagnostics traceability.
spool px_skew_diagnosis.log

-- Configure SQL*Plus formatting for wide PX diagnostic reports.
set pages 9999
set lines 280
set verify off
set trimspool on
set tab off
set feedback on
set termout on

-- Abort on SQL errors to avoid partial or misleading analysis.
whenever sqlerror exit failure rollback

-- Capture input parameters.
define instance_number = '&1'
define sample_seconds = '&2'
define include_idle_waits = upper('&3')
define top_n_qc = '&4'
define sql_id_filter = '&5'

-- Validate required inputs and value domains.
declare
  l_inst number;
  l_seconds number;
  l_topn number;
  l_idle varchar2(1);
begin
  if '&&instance_number' is null or '&&sample_seconds' is null
     or '&&include_idle_waits' is null or '&&top_n_qc' is null or '&&sql_id_filter' is null then
    raise_application_error(-21101,
      'Usage: @px_skew_diagnosis.sql <INSTANCE_NUMBER|0> <SAMPLE_SECONDS> <Y|N> <TOP_N_QC> <SQL_ID_FILTER|%>');
  end if;

  l_inst := to_number('&&instance_number');
  l_seconds := to_number('&&sample_seconds');
  l_topn := to_number('&&top_n_qc');
  l_idle := upper('&&include_idle_waits');

  if l_seconds < 10 then
    raise_application_error(-21102, 'SAMPLE_SECONDS must be >= 10.');
  end if;

  if l_topn < 1 then
    raise_application_error(-21103, 'TOP_N_QC must be >= 1.');
  end if;

  if l_idle not in ('Y','N') then
    raise_application_error(-21104, 'INCLUDE_IDLE_WAITS must be Y or N.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt PX skew diagnosis - INST=&&instance_number SAMPLE_SECONDS=&&sample_seconds INCLUDE_IDLE_WAITS=&&include_idle_waits
prompt TOP_N_QC=&&top_n_qc SQL_ID_FILTER=&&sql_id_filter
prompt =====================================================================================================

-- Define output formatting for topology section.
column qc_id                 format a22
column slave_id              format a22
column role_name             format a10
column sql_id                format a13
column status                format a8
column wait_class            format a15
column event                 format a38
column requested_degree      format 99999
column actual_degree         format 99999
column px_server_set         format 999
column px_server_num         format 999

prompt
prompt --- 1) PX topology and runtime context (QC + slaves) ---

-- Build live PX topology and attach current session runtime context for QC/slave roles.
with px_map as (
  select p.inst_id as slave_inst_id,
         p.sid as slave_sid,
         p.serial# as slave_serial,
         p.qcsid as qc_sid,
         p.qcserial# as qc_serial,
         p.server_set,
         p.server#,
         p.degree,
         p.req_degree
    from gv$px_session p
   where (to_number('&&instance_number') = 0 or p.inst_id = to_number('&&instance_number'))
),
ses as (
  select s.inst_id,
         s.sid,
         s.serial#,
         s.status,
         s.sql_id,
         s.wait_class,
         s.event
    from gv$session s
   where s.type = 'USER'
),
qc_rank as (
  select q.inst_id as qc_inst_id,
         q.sid as qc_sid,
         q.serial# as qc_serial,
         q.sql_id,
         row_number() over (order by q.inst_id, q.sid) as rn
    from gv$session q
   where q.type = 'USER'
     and q.sql_id like '&&sql_id_filter'
     and exists (
       select 1
         from px_map p
        where p.qc_sid = q.sid
          and p.qc_serial = q.serial#
          and (to_number('&&instance_number') = 0 or p.slave_inst_id = q.inst_id)
     )
)
select qr.qc_inst_id || ':' || qr.qc_sid || ',' || qr.qc_serial as qc_id,
       qr.sql_id,
       'QC' as role_name,
       qr.qc_inst_id || ':' || qr.qc_sid || ',' || qr.qc_serial as slave_id,
       qs.status,
       nvl(qs.wait_class, 'N/A') as wait_class,
       nvl(qs.event, 'N/A') as event,
       cast(null as number) as requested_degree,
       cast(null as number) as actual_degree,
       cast(null as number) as px_server_set,
       cast(null as number) as px_server_num
  from qc_rank qr
  left join ses qs
    on qs.inst_id = qr.qc_inst_id
   and qs.sid = qr.qc_sid
   and qs.serial# = qr.qc_serial
 where qr.rn <= to_number('&&top_n_qc')
union all
select qr.qc_inst_id || ':' || qr.qc_sid || ',' || qr.qc_serial as qc_id,
       qr.sql_id,
       'SLAVE' as role_name,
       p.slave_inst_id || ':' || p.slave_sid || ',' || p.slave_serial as slave_id,
       ss.status,
       nvl(ss.wait_class, 'N/A') as wait_class,
       nvl(ss.event, 'N/A') as event,
       p.req_degree as requested_degree,
       p.degree as actual_degree,
       p.server_set as px_server_set,
       p.server# as px_server_num
  from qc_rank qr
  join px_map p
    on p.qc_sid = qr.qc_sid
   and p.qc_serial = qr.qc_serial
  left join ses ss
    on ss.inst_id = p.slave_inst_id
   and ss.sid = p.slave_sid
   and ss.serial# = p.slave_serial
 where qr.rn <= to_number('&&top_n_qc')
 order by qc_id, role_name desc, slave_id;

-- Define output formatting for skew-metric section.
column ash_samples           format 999,999,999
column pct_of_qc_samples     format 999,990.99
column min_slave_samples     format 999,999,999
column max_slave_samples     format 999,999,999
column avg_slave_samples     format 999,999,990.99
column max_min_ratio         format 999,990.99

prompt
prompt --- 2) PX skew metrics from recent ASH samples ---

-- Aggregate recent ASH samples per PX slave and compute per-QC skew indicators.
with px_map as (
  select p.inst_id as slave_inst_id,
         p.sid as slave_sid,
         p.serial# as slave_serial,
         p.qcsid as qc_sid,
         p.qcserial# as qc_serial
    from gv$px_session p
   where (to_number('&&instance_number') = 0 or p.inst_id = to_number('&&instance_number'))
),
qc_rank as (
  select q.inst_id as qc_inst_id,
         q.sid as qc_sid,
         q.serial# as qc_serial,
         q.sql_id,
         row_number() over (order by q.inst_id, q.sid) as rn
    from gv$session q
   where q.type = 'USER'
     and q.sql_id like '&&sql_id_filter'
     and exists (
       select 1
         from px_map p
        where p.qc_sid = q.sid
          and p.qc_serial = q.serial#
          and (to_number('&&instance_number') = 0 or p.slave_inst_id = q.inst_id)
     )
),
ash_slave as (
  select p.qc_sid,
         p.qc_serial,
         p.slave_inst_id,
         p.slave_sid,
         p.slave_serial,
         count(*) as ash_samples
    from px_map p
    join gv$active_session_history a
      on a.inst_id = p.slave_inst_id
     and a.session_id = p.slave_sid
     and a.session_serial# = p.slave_serial
   where a.sample_time >= systimestamp - numtodsinterval(to_number('&&sample_seconds'), 'SECOND')
     and (upper('&&include_idle_waits') = 'Y' or nvl(a.wait_class, 'UNKNOWN') <> 'Idle')
   group by p.qc_sid, p.qc_serial, p.slave_inst_id, p.slave_sid, p.slave_serial
),
slave_with_qc as (
  select qr.qc_inst_id,
         qr.qc_sid,
         qr.qc_serial,
         qr.sql_id,
         a.slave_inst_id,
         a.slave_sid,
         a.slave_serial,
         a.ash_samples
    from qc_rank qr
    join ash_slave a
      on a.qc_sid = qr.qc_sid
     and a.qc_serial = qr.qc_serial
   where qr.rn <= to_number('&&top_n_qc')
),
qc_stat as (
  select qc_inst_id,
         qc_sid,
         qc_serial,
         sql_id,
         sum(ash_samples) as qc_samples,
         min(ash_samples) as min_slave_samples,
         max(ash_samples) as max_slave_samples,
         avg(ash_samples) as avg_slave_samples
    from slave_with_qc
   group by qc_inst_id, qc_sid, qc_serial, sql_id
)
select s.qc_inst_id || ':' || s.qc_sid || ',' || s.qc_serial as qc_id,
       s.sql_id,
       s.slave_inst_id || ':' || s.slave_sid || ',' || s.slave_serial as slave_id,
       s.ash_samples,
       round((s.ash_samples / decode(q.qc_samples,0,1,q.qc_samples)) * 100, 2) as pct_of_qc_samples,
       q.min_slave_samples,
       q.max_slave_samples,
       round(q.avg_slave_samples, 2) as avg_slave_samples,
       round(q.max_slave_samples / decode(q.min_slave_samples,0,1,q.min_slave_samples), 2) as max_min_ratio
  from slave_with_qc s
  join qc_stat q
    on q.qc_inst_id = s.qc_inst_id
   and q.qc_sid = s.qc_sid
   and q.qc_serial = s.qc_serial
 order by q.max_slave_samples / decode(q.min_slave_samples,0,1,q.min_slave_samples) desc,
          qc_id,
          s.ash_samples desc;

-- End spooling and terminate script cleanly.
spool off

exit;
