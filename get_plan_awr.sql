-- #############################################################################################################
-- FILE: get_plan_awr.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Retrieves historical execution plans from AWR for a SQL_ID, adds deterministic plan-hash auto-selection, and reports enriched per-plan performance/context metrics before rendering DBMS_XPLAN workload-repository plan details.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze in AWR (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (plan_hash_value) - NUMBER - Optional plan hash value filter; use -1 or blank for auto-selection (e.g., 2481688974 or -1).
-- &3 (min_executions) - NUMBER - Optional minimum execution preference used by auto-selection (default 1, e.g., 5).
-- &4 (top_n) - NUMBER - Optional maximum number of plan rows to display in AWR summary (default 20, e.g., 30).
--
-- OUTPUT DESCRIPTION:
-- Three sections: (1) deterministic selected PLAN_HASH_VALUE context, (2) enriched AWR summary by plan hash with execution and resource KPIs plus optimizer-env hash indicators, (3) DBMS_XPLAN.DISPLAY_WORKLOAD_REPOSITORY output for selected plan hash with adaptive/outline/bind/note/projection details. Output is spooled to get_plan_awr.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which historical AWR plan hash should be analyzed first for this SQL_ID based on elapsed-time impact?
-- Which plan hash values exist in AWR and how do their execution/resource profiles compare?
-- What historical plan text does DBMS_XPLAN show for the selected plan hash?
-- How many optimizer environment hash variants are associated with each historical plan?
-- Which plan hash has the highest average elapsed time per execution in AWR?
-- Can I force analysis to one explicit plan hash value instead of auto-selection?
-- Is this SQL_ID absent from AWR and therefore requiring another investigation path?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : get_plan_awr.sql cm1fyt76dwbkb -1 5 30
-- #############################################################################################################
--

-- Spool output for auditability and incident sharing.
spool get_plan_awr.log

-- Configure SQL*Plus rendering for large DBMS_XPLAN outputs.
set pages 9999
set lines 260
set long 1000000
set longchunksize 32767
set trimspool on
set verify off
set feedback on
set tab off
set termout on

-- Stop on SQL errors to avoid partial/misleading reports.
whenever sqlerror exit failure rollback

-- Capture user parameters (optional values can be blank).
define sql_id = '&1'
define plan_hash_value = '&2'
define min_executions = '&3'
define top_n = '&4'

-- Normalize optional parameters to deterministic defaults.
column effective_plan_hash new_value effective_plan_hash noprint
select case
         when trim('&&plan_hash_value') is null then '-1'
         else trim('&&plan_hash_value')
       end as effective_plan_hash
from dual;

column effective_min_exec new_value effective_min_exec noprint
select case
         when trim('&&min_executions') is null then '1'
         else trim('&&min_executions')
       end as effective_min_exec
from dual;

column effective_top_n new_value effective_top_n noprint
select case
         when trim('&&top_n') is null then '20'
         else trim('&&top_n')
       end as effective_top_n
from dual;

-- Validate input semantics and AWR presence.
declare
  l_exists number;
begin
  if '&&sql_id' is null then
    raise_application_error(-20201, 'SQL_ID is mandatory. Usage: @get_plan_awr.sql <SQL_ID> [PLAN_HASH_VALUE|-1] [MIN_EXEC] [TOP_N]');
  end if;

  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20202, 'Invalid SQL_ID format: &&sql_id');
  end if;

  if not regexp_like('&&effective_plan_hash', '^-?[0-9]+$') then
    raise_application_error(-20203, 'PLAN_HASH_VALUE must be numeric, -1, or blank.');
  end if;

  if to_number('&&effective_plan_hash') < -1 then
    raise_application_error(-20204, 'PLAN_HASH_VALUE must be -1 (auto) or >= 0.');
  end if;

  if to_number('&&effective_min_exec') < 0 then
    raise_application_error(-20205, 'MIN_EXECUTIONS must be >= 0.');
  end if;

  if to_number('&&effective_top_n') < 1 then
    raise_application_error(-20206, 'TOP_N must be >= 1.');
  end if;

  select count(*)
    into l_exists
    from cdb_hist_sqlstat s
   where s.sql_id = lower('&&sql_id')
     and (to_number('&&effective_plan_hash') = -1 or s.plan_hash_value = to_number('&&effective_plan_hash'));

  if l_exists = 0 then
    raise_application_error(-20207,
      'No AWR rows found for SQL_ID ' || lower('&&sql_id') ||
      case when to_number('&&effective_plan_hash') = -1 then '' else ' and PLAN_HASH_VALUE ' || '&&effective_plan_hash' end ||
      '. Check retention window or use library-cache script @get_plan.sql first.');
  end if;
end;
/

-- Resolve PLAN_HASH_VALUE deterministically in AUTO mode.
column selected_plan_hash new_value selected_plan_hash noprint
select case
         when to_number('&&effective_plan_hash') = -1 then
           to_char(
             (
               select plan_hash_value
                 from (
                   select s.plan_hash_value,
                          sum(nvl(s.executions_delta,0)) as total_execs,
                          sum(nvl(s.elapsed_time_delta,0))/1e6 as total_elapsed_s,
                          max(sn.end_interval_time) as last_seen,
                          (sum(nvl(s.elapsed_time_delta,0))/1e6)
                          / decode(sum(nvl(s.executions_delta,0)),0,1,sum(nvl(s.executions_delta,0))) as avg_etime_s
                     from cdb_hist_sqlstat s
                     join cdb_hist_snapshot sn
                       on sn.snap_id = s.snap_id
                      and sn.dbid = s.dbid
                      and sn.instance_number = s.instance_number
                      and sn.con_id = s.con_id
                    where s.sql_id = lower('&&sql_id')
                    group by s.plan_hash_value
                    order by case when sum(nvl(s.executions_delta,0)) >= to_number('&&effective_min_exec') then 0 else 1 end,
                             avg_etime_s desc,
                             total_execs desc,
                             last_seen desc,
                             s.plan_hash_value
                 )
                where rownum = 1
             )
           )
         else '&&effective_plan_hash'
       end as selected_plan_hash
from dual;

prompt
prompt =====================================================================================================
prompt Plan extraction from AWR for SQL_ID: &&sql_id
prompt PLAN_MODE: &&effective_plan_hash  SELECTED_PLAN_HASH: &&selected_plan_hash  MIN_EXECUTIONS: &&effective_min_exec  TOP_N: &&effective_top_n
prompt =====================================================================================================
prompt NOTE: Read-only script. No data change is performed.

-- Define summary display formats.
column first_seen              format a20
column last_seen               format a20
column total_execs             format 999,999,999,999
column total_elapsed_s         format 999,999,999,990.999
column avg_etime_s             format 999,999,999,990.999
column avg_cpu_s               format 999,999,999,990.999
column avg_lio                 format 999,999,999,999.9
column avg_pio                 format 999,999,999,999.9
column env_hash_count          format 999,999
column dominant_env_hash       format 99999999999999999999

prompt
prompt --- 1) AWR summary by PLAN_HASH_VALUE (enriched historical profile) ---

-- Aggregate historical performance by plan hash and expose optimizer-env hash context.
with plan_base as (
  select s.plan_hash_value,
         count(*) as snap_rows,
         min(sn.begin_interval_time) as first_seen,
         max(sn.end_interval_time) as last_seen,
         sum(nvl(s.executions_delta,0)) as total_execs,
         sum(nvl(s.elapsed_time_delta,0))/1e6 as total_elapsed_s,
         sum(nvl(s.cpu_time_delta,0))/1e6 as total_cpu_s,
         sum(nvl(s.buffer_gets_delta,0)) as total_lio,
         sum(nvl(s.disk_reads_delta,0)) as total_pio,
         count(distinct s.optimizer_env_hash_value) as env_hash_count
    from cdb_hist_sqlstat s
    join cdb_hist_snapshot sn
      on sn.snap_id = s.snap_id
     and sn.dbid = s.dbid
     and sn.instance_number = s.instance_number
     and sn.con_id = s.con_id
   where s.sql_id = lower('&&sql_id')
     and (to_number('&&effective_plan_hash') = -1 or s.plan_hash_value = to_number('&&effective_plan_hash'))
   group by s.plan_hash_value
), env_rank as (
  select s.plan_hash_value,
         s.optimizer_env_hash_value,
         count(*) as env_rows,
         row_number() over (
           partition by s.plan_hash_value
           order by count(*) desc, s.optimizer_env_hash_value
         ) as rn
    from cdb_hist_sqlstat s
   where s.sql_id = lower('&&sql_id')
     and (to_number('&&effective_plan_hash') = -1 or s.plan_hash_value = to_number('&&effective_plan_hash'))
   group by s.plan_hash_value, s.optimizer_env_hash_value
), ranked as (
  select p.plan_hash_value,
         p.snap_rows,
         to_char(p.first_seen,'dd-mon-yyyy hh24:mi:ss') as first_seen,
         to_char(p.last_seen,'dd-mon-yyyy hh24:mi:ss') as last_seen,
         p.total_execs,
         p.total_elapsed_s,
         round(p.total_elapsed_s / decode(p.total_execs,0,1,p.total_execs), 6) as avg_etime_s,
         round(p.total_cpu_s / decode(p.total_execs,0,1,p.total_execs), 6) as avg_cpu_s,
         round(p.total_lio / decode(p.total_execs,0,1,p.total_execs), 3) as avg_lio,
         round(p.total_pio / decode(p.total_execs,0,1,p.total_execs), 3) as avg_pio,
         p.env_hash_count,
         e.optimizer_env_hash_value as dominant_env_hash,
         row_number() over (
           order by (p.total_elapsed_s / decode(p.total_execs,0,1,p.total_execs)) desc,
                    p.total_execs desc,
                    p.plan_hash_value
         ) as rn
    from plan_base p
    left join env_rank e
      on e.plan_hash_value = p.plan_hash_value
     and e.rn = 1
)
select plan_hash_value,
       snap_rows,
       first_seen,
       last_seen,
       total_execs,
       total_elapsed_s,
       avg_etime_s,
       avg_cpu_s,
       avg_lio,
       avg_pio,
       env_hash_count,
       dominant_env_hash
  from ranked
 where rn <= to_number('&&effective_top_n')
 order by rn;

prompt
prompt --- 2) Execution plan from AWR for selected PLAN_HASH_VALUE ---

-- Render historical plan text from AWR for deterministically selected/explicit plan hash.
select *
from table (
  dbms_xplan.display_workload_repository(
    sql_id          => lower('&&sql_id'),
    plan_hash_value => to_number('&&selected_plan_hash'),
    format          => 'ALLSTATS LAST +ADAPTIVE +OUTLINE +PEEKED_BINDS +NOTE +ALIAS +PROJECTION'
  )
);

prompt
prompt --- Action hints ---
prompt 1) Re-run with explicit PLAN_HASH_VALUE to compare alternative historical plans one by one.
prompt 2) Compare with @get_plan.sql <SQL_ID> [CHILD|-1] [MIN_EXEC] [TOP_N] for current cache versus historical AWR.
prompt 3) If bad historical plan is confirmed, evaluate SQL Baseline / SQL Patch stabilization workflows.

-- End spool and terminate script.
spool off
exit;
