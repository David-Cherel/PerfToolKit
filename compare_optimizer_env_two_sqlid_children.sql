-- #############################################################################################################
-- FILE: compare_optimizer_env_two_sqlid_children.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Compares optimizer environment parameters between two different SQL_ID and child-cursor pairs from library cache, highlighting value differences and missing parameters to explain environment-driven plan or performance divergence.
--
-- INPUT PARAMETERS:
-- &1 (sql_id_1) - STRING - First SQL_ID in library cache (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (child_number_1) - NUMBER - Child cursor number for first SQL_ID (e.g., 0).
-- &3 (sql_id_2) - STRING - Second SQL_ID in library cache (13 alphanumeric characters, e.g., 'f3gyxvq104jgd').
-- &4 (child_number_2) - NUMBER - Child cursor number for second SQL_ID (e.g., 2).
-- &5 (include_hidden_params) - STRING - Include hidden parameters in comparison outputs: Y|N (e.g., 'N').
--
-- OUTPUT DESCRIPTION:
-- Three sections: (1) source context for both SQL_ID/child pairs, (2) differences-only optimizer parameter report, and
-- (3) full side-by-side optimizer parameter matrix with MATCH/DIFF indicator.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which optimizer environment parameters differ between two different SQL_ID child cursors?
-- Are hidden optimizer parameters responsible for differences across the two SQL statements?
-- Do both SQL child cursors use different optimizer_env_hash_value fingerprints?
-- Which parameter exists in one SQL child environment but not in the other?
-- Can optimizer environment differences explain plan or performance divergence between two SQL_IDs?
-- What side-by-side parameter values should be replayed to reproduce each SQL context?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : compare_optimizer_env_two_sqlid_children.sql cm1fyt76dwbkb 0 f3gyxvq104jgd 2 N
-- #############################################################################################################
--

-- Spool comparison output for incident records and auditability.
spool compare_optimizer_env_two_sqlid_children.log

-- Configure SQL*Plus report rendering for wide side-by-side parameter values.
set pages 9999
set lines 320
set long 1000000
set longchunksize 32767
set trimspool on
set verify off
set feedback on
set tab off
set termout on

-- Stop on SQL errors to avoid partial comparison reports.
whenever sqlerror exit failure rollback

-- Capture runtime parameters.
define sql_id_1 = '&1'
define child_number_1 = '&2'
define sql_id_2 = '&3'
define child_number_2 = '&4'
define include_hidden_params = upper('&5')

-- Validate input quality and verify both SQL_ID/child pairs exist in library cache.
declare
  l_exists number;
begin
  if '&&sql_id_1' is null or '&&child_number_1' is null or '&&sql_id_2' is null or '&&child_number_2' is null
     or '&&include_hidden_params' is null then
    raise_application_error(-21601,
      'Usage: @compare_optimizer_env_two_sqlid_children.sql <SQL_ID_1> <CHILD_1> <SQL_ID_2> <CHILD_2> <INCLUDE_HIDDEN_PARAMS(Y|N)>');
  end if;

  if not regexp_like('&&sql_id_1', '^[[:alnum:]]{13}$') then
    raise_application_error(-21602, 'Invalid SQL_ID_1 format: &&sql_id_1');
  end if;

  if not regexp_like('&&sql_id_2', '^[[:alnum:]]{13}$') then
    raise_application_error(-21603, 'Invalid SQL_ID_2 format: &&sql_id_2');
  end if;

  if not regexp_like('&&child_number_1', '^[0-9]+$') or not regexp_like('&&child_number_2', '^[0-9]+$') then
    raise_application_error(-21604, 'CHILD_NUMBER_1 and CHILD_NUMBER_2 must be non-negative integers.');
  end if;

  if upper('&&include_hidden_params') not in ('Y','N') then
    raise_application_error(-21605, 'INCLUDE_HIDDEN_PARAMS must be Y or N.');
  end if;

  select count(*)
    into l_exists
    from v$sql
   where sql_id = lower('&&sql_id_1')
     and child_number = to_number('&&child_number_1');

  if l_exists = 0 then
    raise_application_error(-21606,
      'Pair 1 not found in V$SQL cache: SQL_ID_1=' || lower('&&sql_id_1') || ', CHILD_1=&&child_number_1');
  end if;

  select count(*)
    into l_exists
    from v$sql
   where sql_id = lower('&&sql_id_2')
     and child_number = to_number('&&child_number_2');

  if l_exists = 0 then
    raise_application_error(-21607,
      'Pair 2 not found in V$SQL cache: SQL_ID_2=' || lower('&&sql_id_2') || ', CHILD_2=&&child_number_2');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Optimizer environment comparison across two SQL_ID/child pairs
prompt PAIR_1: SQL_ID=&&sql_id_1 CHILD=&&child_number_1
prompt PAIR_2: SQL_ID=&&sql_id_2 CHILD=&&child_number_2
prompt INCLUDE_HIDDEN_PARAMS=&&include_hidden_params
prompt =====================================================================================================

-- Define output formatting for pair context section.
column pair_id                  format a7
column sql_id                   format a13
column child_number             format 999999
column plan_hash_value          format 9999999999999
column optimizer_env_hash_value format 99999999999999999999
column executions               format 999,999,999,999
column avg_etime_s              format 999,999,999,990.999
column avg_cpu_s                format 999,999,999,990.999
column parsing_schema_name      format a30
column module                   format a35
column action                   format a35
column last_active_time         format a19

prompt
prompt --- 1) Source context for both SQL_ID/child pairs ---

-- Show identity and performance context of both compared SQL_ID/child pairs.
select case
         when sql_id = lower('&&sql_id_1') and child_number = to_number('&&child_number_1') then 'PAIR_1'
         when sql_id = lower('&&sql_id_2') and child_number = to_number('&&child_number_2') then 'PAIR_2'
         else 'UNKNOWN'
       end as pair_id,
       sql_id,
       child_number,
       plan_hash_value,
       optimizer_env_hash_value,
       executions,
       round((elapsed_time/1e6)/decode(nvl(executions,0),0,1,executions), 6) as avg_etime_s,
       round((cpu_time/1e6)/decode(nvl(executions,0),0,1,executions), 6) as avg_cpu_s,
       to_char(last_active_time, 'yyyy-mm-dd hh24:mi:ss') as last_active_time,
       parsing_schema_name,
       module,
       action
  from v$sql
 where (sql_id = lower('&&sql_id_1') and child_number = to_number('&&child_number_1'))
    or (sql_id = lower('&&sql_id_2') and child_number = to_number('&&child_number_2'))
 order by pair_id;

-- Define display formatting for differences-only section.
column param_name       format a55
column pair1_value      format a90
column pair2_value      format a90
column pair1_isdefault  format a12
column pair2_isdefault  format a12
column diff_type        format a22

prompt
prompt --- 2) Optimizer parameter differences only (PAIR_1 vs PAIR_2) ---

-- Compare parameter values and return only rows that differ between both pairs.
with p1 as (
  select name,
         value,
         isdefault
    from v$sql_optimizer_env
   where sql_id = lower('&&sql_id_1')
     and child_number = to_number('&&child_number_1')
     and (upper('&&include_hidden_params') = 'Y' or name not like '\_%' escape '\')
),
p2 as (
  select name,
         value,
         isdefault
    from v$sql_optimizer_env
   where sql_id = lower('&&sql_id_2')
     and child_number = to_number('&&child_number_2')
     and (upper('&&include_hidden_params') = 'Y' or name not like '\_%' escape '\')
), joined as (
  select nvl(p1.name, p2.name) as param_name,
         p1.value as pair1_value,
         p2.value as pair2_value,
         p1.isdefault as pair1_isdefault,
         p2.isdefault as pair2_isdefault,
         case
           when p1.name is null then 'ONLY_IN_PAIR_2'
           when p2.name is null then 'ONLY_IN_PAIR_1'
           when nvl(p1.value, '#NULL#') <> nvl(p2.value, '#NULL#') then 'VALUE_DIFFERENCE'
           else 'MATCH'
         end as diff_type
    from p1
    full outer join p2
      on p1.name = p2.name
)
select param_name,
       pair1_value,
       pair2_value,
       pair1_isdefault,
       pair2_isdefault,
       diff_type
  from joined
 where diff_type <> 'MATCH'
 order by case diff_type when 'VALUE_DIFFERENCE' then 1 when 'ONLY_IN_PAIR_1' then 2 when 'ONLY_IN_PAIR_2' then 3 else 4 end,
          param_name;

column match_flag format a6

prompt
prompt --- 3) Full side-by-side optimizer parameter matrix ---

-- Return full parameter inventory with MATCH/DIFF indicator for complete comparison trace.
with p1 as (
  select name,
         value,
         isdefault
    from v$sql_optimizer_env
   where sql_id = lower('&&sql_id_1')
     and child_number = to_number('&&child_number_1')
     and (upper('&&include_hidden_params') = 'Y' or name not like '\_%' escape '\')
),
p2 as (
  select name,
         value,
         isdefault
    from v$sql_optimizer_env
   where sql_id = lower('&&sql_id_2')
     and child_number = to_number('&&child_number_2')
     and (upper('&&include_hidden_params') = 'Y' or name not like '\_%' escape '\')
)
select nvl(p1.name, p2.name) as param_name,
       p1.value as pair1_value,
       p2.value as pair2_value,
       p1.isdefault as pair1_isdefault,
       p2.isdefault as pair2_isdefault,
       case when nvl(p1.value, '#NULL#') = nvl(p2.value, '#NULL#') then 'MATCH' else 'DIFF' end as match_flag
  from p1
  full outer join p2
    on p1.name = p2.name
 order by nvl(p1.name, p2.name);

prompt
prompt --- Action hints ---
prompt 1) Prioritize VALUE_DIFFERENCE rows with non-default flags for both pairs.
prompt 2) Replay one pair in a test session with @replay_optimizer_env_for_child.sql.
prompt 3) Correlate env differences with plan_hash_value and avg_etime_s from section 1.

-- End spool and terminate script.
spool off
exit;
