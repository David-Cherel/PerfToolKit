-- #############################################################################################################
-- FILE: get_plan_awr.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Retrieves execution plan details from AWR for a SQL_ID (optionally filtered by PLAN_HASH_VALUE), including historical performance summary and DBMS_XPLAN workload repository plan output.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze in AWR (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (plan_hash_value) - NUMBER - Optional plan hash value filter to focus on one historical plan (e.g., 2481688974).
--
-- OUTPUT DESCRIPTION:
-- Two result sets: (1) AWR summary by PLAN_HASH_VALUE with snapshot range and execution/elapsed metrics; (2) DBMS_XPLAN.DISPLAY_WORKLOAD_REPOSITORY plan output with adaptive/outline/bind/note details. Output is spooled to get_plan_awr.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which historical plans exist in AWR for a given SQL_ID?
-- What is the execution profile of each plan hash value in AWR?
-- What plan details does DBMS_XPLAN show from AWR for this SQL_ID?
-- How can I focus analysis on one specific plan hash value?
-- How does historical AWR plan behavior compare across plans?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : get_plan_awr.sql cm1fyt76dwbkb 2481688974
-- #############################################################################################################
--
set pages 9999
set lines 220
set long 1000000
set longchunksize 32767
set trimspool on
set verify off
set feedback on
set tab off
set termout on

whenever sqlerror exit failure rollback

define sql_id ='&1'
define plan_hash_value ='&2'

begin
  if '&&sql_id' is null then
    raise_application_error(-20201, 'SQL_ID is mandatory. Usage: @get_plan_awr.sql <SQL_ID> [PLAN_HASH_VALUE]');
  end if;
  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20202, 'Invalid SQL_ID format: &&sql_id');
  end if;
  if '&&plan_hash_value' is not null and not regexp_like('&&plan_hash_value', '^[0-9]+$') then
    raise_application_error(-20203, 'PLAN_HASH_VALUE must be numeric when provided.');
  end if;
end;
/

spool get_plan_awr.log

prompt
prompt =====================================================================================================
prompt Plan extraction from AWR for SQL_ID: &&sql_id, PLAN_HASH_VALUE: &&plan_hash_value
prompt =====================================================================================================
prompt NOTE: Read-only script. No data change is performed.

column begin_interval_time format a22
column end_interval_time   format a22
column avg_etime_s         format 999,999.99999
column avg_cpu_s           format 999,999.99999
column avg_lio             format 999,999,999.9
column avg_pio             format 999,999,999.9

prompt
prompt --- AWR summary by PLAN_HASH_VALUE ---

select s.plan_hash_value,
       count(*) snap_count,
       to_char(min(sn.begin_interval_time),'dd-mon-yyyy hh24:mi:ss') first_seen,
       to_char(max(sn.end_interval_time),'dd-mon-yyyy hh24:mi:ss') last_seen,
       sum(nvl(s.executions_delta,0)) total_execs,
       min((s.elapsed_time_delta/1000000)/decode(nvl(s.executions_delta,0),0,1,s.executions_delta)) min_avg_etime_s,
       max((s.elapsed_time_delta/1000000)/decode(nvl(s.executions_delta,0),0,1,s.executions_delta)) max_avg_etime_s
from cdb_hist_sqlstat s
     join cdb_hist_snapshot sn
       on sn.snap_id = s.snap_id
      and sn.dbid = s.dbid
      and sn.instance_number = s.instance_number
where s.sql_id = '&&sql_id'
  and ( '&&plan_hash_value' is null or s.plan_hash_value = to_number('&&plan_hash_value') )
group by s.plan_hash_value
order by s.plan_hash_value;

prompt
prompt --- Execution plan from AWR ---

select *
from table (
  dbms_xplan.display_workload_repository(
    sql_id          => '&&sql_id',
    plan_hash_value => nullif('&&plan_hash_value',''),
    format          => 'ALLSTATS +ADAPTIVE +OUTLINE +PEEKED_BINDS +NOTE'
  )
);

prompt
prompt --- Action hints ---
prompt 1) If several plans exist, re-run with a specific PLAN_HASH_VALUE to focus analysis.
prompt 2) Compare with @get_plan.sql <SQL_ID> to check current cache plan vs historical AWR plans.
prompt 3) If regression is confirmed, evaluate SQL Baseline/SQL Patch workflows.

spool off

exit
