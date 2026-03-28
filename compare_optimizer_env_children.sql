-- #############################################################################################################
-- FILE: compare_optimizer_env_children.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Compares optimizer environment parameters between two child cursors of the same SQL_ID from library cache, highlighting only differing values and providing side-by-side context to explain child-cursor plan divergence.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID in library cache (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (child_number_1) - NUMBER - First child cursor number to compare (e.g., 0).
-- &3 (child_number_2) - NUMBER - Second child cursor number to compare (e.g., 2).
-- &4 (include_hidden_params) - STRING - Include hidden parameters in comparison outputs: Y|N (e.g., 'N').
--
-- OUTPUT DESCRIPTION:
-- Three sections: (1) side-by-side child cursor identity/performance context, (2) parameter-level differences only between child environments, (3) full side-by-side parameter matrix for both children with match/diff flag.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which optimizer parameters differ between two child cursors of the same SQL_ID?
-- Are child cursor differences linked to hidden optimizer parameter changes?
-- Which child cursor has the slower average elapsed time and what env differences might explain it?
-- Do both children share the same optimizer_env_hash_value or not?
-- Which parameters are present in one child environment and missing in the other?
-- Can optimizer environment differences explain plan hash/value divergence across children?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : compare_optimizer_env_children.sql cm1fyt76dwbkb 0 2 N
-- #############################################################################################################
--

-- Spool output for diagnostic traceability.
spool compare_optimizer_env_children.log

-- Configure SQL*Plus report rendering.
set pages 9999
set lines 300
set long 1000000
set longchunksize 32767
set trimspool on
set verify off
set feedback on
set tab off
set termout on

-- Stop on SQL errors to avoid partial comparison output.
whenever sqlerror exit failure rollback

-- Capture runtime parameters.
define sql_id = '&1'
define child_number_1 = '&2'
define child_number_2 = '&3'
define include_hidden_params = upper('&4')

-- Validate inputs and cursor existence.
declare
  l_exists number;
begin
  if '&&sql_id' is null or '&&child_number_1' is null or '&&child_number_2' is null or '&&include_hidden_params' is null then
    raise_application_error(-21501,
      'Usage: @compare_optimizer_env_children.sql <SQL_ID> <CHILD_1> <CHILD_2> <INCLUDE_HIDDEN_PARAMS(Y|N)>');
  end if;

  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-21502, 'Invalid SQL_ID format: &&sql_id');
  end if;

  if not regexp_like('&&child_number_1', '^[0-9]+$') or not regexp_like('&&child_number_2', '^[0-9]+$') then
    raise_application_error(-21503, 'CHILD_NUMBER_1 and CHILD_NUMBER_2 must be non-negative integers.');
  end if;

  if to_number('&&child_number_1') = to_number('&&child_number_2') then
    raise_application_error(-21504, 'CHILD_NUMBER_1 and CHILD_NUMBER_2 must be different values.');
  end if;

  if upper('&&include_hidden_params') not in ('Y','N') then
    raise_application_error(-21505, 'INCLUDE_HIDDEN_PARAMS must be Y or N.');
  end if;

  select count(*)
    into l_exists
    from v$sql
   where sql_id = lower('&&sql_id')
     and child_number in (to_number('&&child_number_1'), to_number('&&child_number_2'));

  if l_exists < 2 then
    raise_application_error(-21506,
      'Both child cursors must exist in V$SQL for given SQL_ID. Re-parse SQL or verify child numbers.');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Optimizer environment comparison for SQL_ID=&&sql_id CHILD_1=&&child_number_1 CHILD_2=&&child_number_2
prompt INCLUDE_HIDDEN_PARAMS=&&include_hidden_params
prompt =====================================================================================================

-- Define formatting for child context section.
column parsing_schema_name      format a30
column module                   format a35
column action                   format a35
column last_active_time         format a19
column avg_etime_s              format 999,999,999,990.999
column optimizer_env_hash_value format 99999999999999999999

prompt
prompt --- 1) Child cursor context (side-by-side performance identity) ---

-- Show baseline identity and performance context for both compared child cursors.
select child_number,
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
 where sql_id = lower('&&sql_id')
   and child_number in (to_number('&&child_number_1'), to_number('&&child_number_2'))
 order by child_number;

-- Define formatting for diff-only section.
column param_name   format a55
column child1_value format a80
column child2_value format a80
column diff_type    format a22

prompt
prompt --- 2) Optimizer environment parameter differences only ---

-- Return only parameters whose values differ between child 1 and child 2.
with c1 as (
  select name,
         value,
         isdefault
    from v$sql_optimizer_env
   where sql_id = lower('&&sql_id')
     and child_number = to_number('&&child_number_1')
     and (upper('&&include_hidden_params') = 'Y' or name not like '\_%' escape '\')
),
c2 as (
  select name,
         value,
         isdefault
    from v$sql_optimizer_env
   where sql_id = lower('&&sql_id')
     and child_number = to_number('&&child_number_2')
     and (upper('&&include_hidden_params') = 'Y' or name not like '\_%' escape '\')
), joined as (
  select nvl(c1.name, c2.name) as param_name,
         c1.value as child1_value,
         c2.value as child2_value,
         c1.isdefault as child1_isdefault,
         c2.isdefault as child2_isdefault,
         case
           when c1.name is null then 'ONLY_IN_CHILD_2'
           when c2.name is null then 'ONLY_IN_CHILD_1'
           when nvl(c1.value, '#NULL#') <> nvl(c2.value, '#NULL#') then 'VALUE_DIFFERENCE'
           else 'MATCH'
         end as diff_type
    from c1
    full outer join c2
      on c1.name = c2.name
)
select param_name,
       child1_value,
       child2_value,
       diff_type,
       child1_isdefault,
       child2_isdefault
  from joined
 where diff_type <> 'MATCH'
 order by case diff_type when 'VALUE_DIFFERENCE' then 1 when 'ONLY_IN_CHILD_1' then 2 when 'ONLY_IN_CHILD_2' then 3 else 4 end,
          param_name;

column match_flag format a6

prompt
prompt --- 3) Full side-by-side optimizer environment matrix ---

-- Return all parameters with explicit MATCH/DIFF indicator for complete auditability.
with c1 as (
  select name,
         value,
         isdefault
    from v$sql_optimizer_env
   where sql_id = lower('&&sql_id')
     and child_number = to_number('&&child_number_1')
     and (upper('&&include_hidden_params') = 'Y' or name not like '\_%' escape '\')
),
c2 as (
  select name,
         value,
         isdefault
    from v$sql_optimizer_env
   where sql_id = lower('&&sql_id')
     and child_number = to_number('&&child_number_2')
     and (upper('&&include_hidden_params') = 'Y' or name not like '\_%' escape '\')
)
select nvl(c1.name, c2.name) as param_name,
       c1.value as child1_value,
       c2.value as child2_value,
       c1.isdefault as child1_isdefault,
       c2.isdefault as child2_isdefault,
       case when nvl(c1.value, '#NULL#') = nvl(c2.value, '#NULL#') then 'MATCH' else 'DIFF' end as match_flag
  from c1
  full outer join c2
    on c1.name = c2.name
 order by nvl(c1.name, c2.name);

prompt
prompt --- Action hints ---
prompt 1) Focus first on VALUE_DIFFERENCE rows where child1/child2 isdefault differs.
prompt 2) Correlate critical diffs with plan_hash_value and avg_etime_s from section 1.
prompt 3) For replay, run @replay_optimizer_env_for_child.sql for target child cursor.

-- End spool and terminate script.
spool off
exit;
