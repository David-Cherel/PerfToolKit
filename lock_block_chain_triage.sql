-- #############################################################################################################
-- FILE: lock_block_chain_triage.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Builds a live blocking-tree triage report from GV$SESSION and GV$LOCK, exposing blocker SQL_ID, blocked-session wait impact, and chain depth to quickly prioritize lock contention during active incidents.
--
-- INPUT PARAMETERS:
-- &1 (instance_number) - NUMBER - RAC instance filter; use 0 for all instances (e.g., 1 or 0).
-- &2 (include_inactive) - STRING - Include inactive blocked sessions: Y|N (e.g., 'N').
-- &3 (top_n) - NUMBER - Maximum number of rows to display per result set (e.g., 50).
--
-- OUTPUT DESCRIPTION:
-- Two result sets:
-- 1. Blocking Chain Tree: hierarchical blocker->blocked view with SQL_ID, wait class/event, seconds waited, lock mode/request, and chain depth.
-- 2. Blocker Impact Summary: blockers ranked by impacted sessions and cumulative blocked wait seconds.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which sessions are currently blocking other sessions?
-- What is the full blocker-to-blocked chain right now?
-- Which blocker SQL_ID is creating the highest impact?
-- How many sessions are blocked by each blocker session?
-- How many cumulative wait seconds are attributable to each blocker?
-- Is lock contention isolated to one RAC instance?
-- Which wait events dominate in blocked sessions?
-- Which blocked sessions are currently ACTIVE versus INACTIVE?
-- What lock request and held lock modes are involved in the chain?
-- Which blocker should be remediated first to reduce incident impact?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : lock_block_chain_triage.sql 0 N 50
-- #############################################################################################################

-- Spool report output for incident evidence collection.
spool lock_block_chain_triage.log

-- Configure SQL*Plus display settings for wide operational diagnostics.
set pages 9999
set lines 260
set verify off
set trimspool on
set tab off
set feedback on
set termout on

-- Fail fast on SQL errors to avoid partial incident reports.
whenever sqlerror exit failure rollback

-- Capture runtime parameters.
define instance_number = '&1'
define include_inactive = upper('&2')
define top_n = '&3'

-- Validate mandatory parameters and accepted option values.
declare
  l_inst number;
  l_topn number;
  l_include varchar2(1);
begin
  if '&&instance_number' is null or '&&include_inactive' is null or '&&top_n' is null then
    raise_application_error(-20801,
      'Usage: @lock_block_chain_triage.sql <INSTANCE_NUMBER|0> <Y|N> <TOP_N>');
  end if;

  l_inst := to_number('&&instance_number');
  l_topn := to_number('&&top_n');
  l_include := upper('&&include_inactive');

  if l_topn < 1 then
    raise_application_error(-20802, 'TOP_N must be >= 1.');
  end if;

  if l_include not in ('Y','N') then
    raise_application_error(-20803, 'INCLUDE_INACTIVE must be Y or N.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Lock/Block chain triage - INST=&&instance_number INCLUDE_INACTIVE=&&include_inactive TOP_N=&&top_n
prompt =====================================================================================================

-- Define output formatting for chain-level report.
column chain_path           format a120
column blocker_sid_serial   format a20
column blocked_sid_serial   format a20
column blocker_sql_id       format a13
column blocked_sql_id       format a13
column blocker_user         format a20
column blocked_user         format a20
column blocked_status       format a10
column blocked_wait_class   format a15
column blocked_event        format a38
column blocked_seconds      format 999,999,999
column blocker_hold_mode    format a14
column blocked_req_mode     format a14
column chain_level          format 999

prompt
prompt --- 1) Blocking chain tree with blocker SQL_ID and blocked wait impact ---

-- Build blocker-to-blocked edges from GV$LOCK and enrich with session and SQL details.
with lock_edges as (
  select /*+ materialize */
         w.inst_id as blocked_inst_id,
         w.sid as blocked_sid,
         h.inst_id as blocker_inst_id,
         h.sid as blocker_sid,
         h.type as lock_type,
         h.id1,
         h.id2,
         h.lmode as blocker_lmode,
         w.request as blocked_request
    from gv$lock h
    join gv$lock w
      on w.type = h.type
     and w.id1 = h.id1
     and w.id2 = h.id2
     and w.request > 0
     and h.block = 1
   where (to_number('&&instance_number') = 0 or h.inst_id = to_number('&&instance_number') or w.inst_id = to_number('&&instance_number'))
), ses as (
  select s.inst_id,
         s.sid,
         s.serial#,
         s.username,
         s.status,
         s.sql_id,
         s.module,
         s.action,
         s.machine,
         s.program,
         s.wait_class,
         s.event,
         s.seconds_in_wait
    from gv$session s
   where s.type = 'USER'
), chains as (
  select e.blocker_inst_id,
         e.blocker_sid,
         e.blocked_inst_id,
         e.blocked_sid,
         e.lock_type,
         e.id1,
         e.id2,
         e.blocker_lmode,
         e.blocked_request,
         level as chain_level,
         connect_by_root e.blocker_inst_id as root_blocker_inst_id,
         connect_by_root e.blocker_sid as root_blocker_sid,
         sys_connect_by_path(
           to_char(e.blocker_inst_id) || ':' || to_char(e.blocker_sid) || '->' ||
           to_char(e.blocked_inst_id) || ':' || to_char(e.blocked_sid),
           ' | '
         ) as chain_path
    from lock_edges e
   connect by nocycle prior e.blocked_inst_id = e.blocker_inst_id
                  and prior e.blocked_sid = e.blocker_sid
   start with not exists (
     select 1
       from lock_edges p
      where p.blocked_inst_id = e.blocker_inst_id
        and p.blocked_sid = e.blocker_sid
   )
), ranked as (
  select c.chain_path,
         c.chain_level,
         c.blocker_inst_id,
         c.blocker_sid,
         b1.serial# as blocker_serial,
         nvl(b1.username, 'SYS/INTERNAL') as blocker_user,
         b1.sql_id as blocker_sql_id,
         c.blocked_inst_id,
         c.blocked_sid,
         b2.serial# as blocked_serial,
         nvl(b2.username, 'SYS/INTERNAL') as blocked_user,
         b2.status as blocked_status,
         b2.sql_id as blocked_sql_id,
         nvl(b2.wait_class, 'UNKNOWN') as blocked_wait_class,
         nvl(b2.event, 'WAIT EVENT N/A') as blocked_event,
         nvl(b2.seconds_in_wait, 0) as blocked_seconds,
         decode(c.blocker_lmode,
                0, 'None',
                1, 'Null',
                2, 'Row-S (SS)',
                3, 'Row-X (SX)',
                4, 'Share',
                5, 'S/Row-X (SSX)',
                6, 'Exclusive',
                to_char(c.blocker_lmode)) as blocker_hold_mode,
         decode(c.blocked_request,
                0, 'None',
                1, 'Null',
                2, 'Row-S (SS)',
                3, 'Row-X (SX)',
                4, 'Share',
                5, 'S/Row-X (SSX)',
                6, 'Exclusive',
                to_char(c.blocked_request)) as blocked_req_mode,
         row_number() over (order by nvl(b2.seconds_in_wait,0) desc, c.chain_level asc) as rn
    from chains c
    left join ses b1
      on b1.inst_id = c.blocker_inst_id
     and b1.sid = c.blocker_sid
    left join ses b2
      on b2.inst_id = c.blocked_inst_id
     and b2.sid = c.blocked_sid
   where (upper('&&include_inactive') = 'Y' or nvl(b2.status, 'INACTIVE') = 'ACTIVE')
)
select chain_path,
       chain_level,
       blocker_inst_id || ':' || blocker_sid || ',' || blocker_serial as blocker_sid_serial,
       blocker_user,
       blocker_sql_id,
       blocked_inst_id || ':' || blocked_sid || ',' || blocked_serial as blocked_sid_serial,
       blocked_user,
       blocked_status,
       blocked_sql_id,
       blocked_wait_class,
       blocked_event,
       blocked_seconds,
       blocker_hold_mode,
       blocked_req_mode
  from ranked
 where rn <= to_number('&&top_n')
 order by rn;

-- Define formatting for blocker impact summary.
column root_blocker_sid_serial format a22
column root_blocker_user       format a20
column root_blocker_sql_id     format a13
column blocked_sessions        format 999,999,999
column active_blocked_sessions format 999,999,999
column total_blocked_seconds   format 999,999,999
column max_single_wait_seconds format 999,999,999

prompt
prompt --- 2) Blocker impact summary (prioritization view) ---

-- Aggregate impact by root blocker to prioritize first remediation actions.
with lock_edges as (
  select /*+ materialize */
         w.inst_id as blocked_inst_id,
         w.sid as blocked_sid,
         h.inst_id as blocker_inst_id,
         h.sid as blocker_sid
    from gv$lock h
    join gv$lock w
      on w.type = h.type
     and w.id1 = h.id1
     and w.id2 = h.id2
     and w.request > 0
     and h.block = 1
   where (to_number('&&instance_number') = 0 or h.inst_id = to_number('&&instance_number') or w.inst_id = to_number('&&instance_number'))
), ses as (
  select s.inst_id,
         s.sid,
         s.serial#,
         nvl(s.username, 'SYS/INTERNAL') as username,
         s.sql_id,
         s.status,
         nvl(s.seconds_in_wait, 0) as seconds_in_wait
    from gv$session s
   where s.type = 'USER'
), roots as (
  select e.blocker_inst_id,
         e.blocker_sid,
         e.blocked_inst_id,
         e.blocked_sid,
         connect_by_root e.blocker_inst_id as root_blocker_inst_id,
         connect_by_root e.blocker_sid as root_blocker_sid
    from lock_edges e
   connect by nocycle prior e.blocked_inst_id = e.blocker_inst_id
                  and prior e.blocked_sid = e.blocker_sid
   start with not exists (
     select 1
       from lock_edges p
      where p.blocked_inst_id = e.blocker_inst_id
        and p.blocked_sid = e.blocker_sid
   )
), agg as (
  select r.root_blocker_inst_id,
         r.root_blocker_sid,
         count(*) as blocked_sessions,
         sum(case when bs.status = 'ACTIVE' then 1 else 0 end) as active_blocked_sessions,
         sum(bs.seconds_in_wait) as total_blocked_seconds,
         max(bs.seconds_in_wait) as max_single_wait_seconds
    from roots r
    left join ses bs
      on bs.inst_id = r.blocked_inst_id
     and bs.sid = r.blocked_sid
   group by r.root_blocker_inst_id, r.root_blocker_sid
), ranked as (
  select a.*,
         rb.serial# as root_blocker_serial,
         rb.username as root_blocker_user,
         rb.sql_id as root_blocker_sql_id,
         row_number() over (order by a.total_blocked_seconds desc, a.blocked_sessions desc) as rn
    from agg a
    left join ses rb
      on rb.inst_id = a.root_blocker_inst_id
     and rb.sid = a.root_blocker_sid
)
select root_blocker_inst_id || ':' || root_blocker_sid || ',' || root_blocker_serial as root_blocker_sid_serial,
       root_blocker_user,
       root_blocker_sql_id,
       blocked_sessions,
       active_blocked_sessions,
       total_blocked_seconds,
       max_single_wait_seconds
  from ranked
 where rn <= to_number('&&top_n')
 order by rn;

-- Stop spooling and exit cleanly.
spool off

exit;
