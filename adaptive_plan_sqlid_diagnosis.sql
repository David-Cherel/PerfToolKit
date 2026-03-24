-- #############################################################################################################
-- FILE: adaptive_plan_sqlid_diagnosis.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Diagnoses adaptive execution plan behavior for a SQL_ID (optionally a child cursor), showing full adaptive plan and analyzing STATISTICS COLLECTOR branches to identify likely cardinality misestimate suspects.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to diagnose for adaptive plan behavior (13 alphanumeric characters, e.g., '4r3harjun4dvz').
-- &2 (child_no) - NUMBER - Optional child cursor number; if null, most recently active child is selected.
--
-- OUTPUT DESCRIPTION:
-- Multiple result sets: adaptive parameter status, full DBMS_XPLAN adaptive plan, STATISTICS COLLECTOR nodes, branch object/predicate analysis, and ranked misestimate suspects by A/E ratio; output spooled to adaptive_plan_sqlid_diagnosis.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Is optimizer adaptive plan functionality enabled for this environment?
-- What adaptive plan (including inactive branches) was generated for this SQL_ID?
-- Which STATISTICS COLLECTOR nodes drove adaptive branch decisions?
-- Which objects and predicates are most likely involved in cardinality misestimates?
-- Which branch operations show the highest actual-to-estimated row divergence?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : adaptive_plan_sqlid_diagnosis.sql 4r3harjun4dvz 0
-- #############################################################################################################
--
set pages 9999
set lines 260
set long 1000000
set longchunksize 32767
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define sql_id   = '&1'
define child_no = '&2'

begin
  if '&&sql_id' is null then
    raise_application_error(-20901, 'SQL_ID is mandatory. Usage: @adaptive_plan_sqlid_diagnosis.sql <SQL_ID> [CHILD_NUMBER]');
  end if;
  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20902, 'Invalid SQL_ID format: &&sql_id');
  end if;
  if '&&child_no' is not null and not regexp_like('&&child_no', '^[0-9]+$') then
    raise_application_error(-20903, 'CHILD_NUMBER must be numeric when provided.');
  end if;
end;
/

column chosen_child new_value chosen_child noprint
select case
         when nullif('&&child_no','') is not null then to_number('&&child_no')
         else (
           select child_number
           from   v$sql
           where  sql_id = '&&sql_id'
           order by last_active_time desc nulls last
           fetch first 1 row only
         )
       end as chosen_child
from dual;

spool adaptive_plan_sqlid_diagnosis.log

prompt
prompt =====================================================================================================
prompt Adaptive Plan diagnosis for SQL_ID=&&sql_id CHILD_NUMBER=&&chosen_child
prompt =====================================================================================================
prompt NOTE: Read-only report. No data change is performed.

prompt
prompt --- 0) Adaptive plan parameter state ---

column name             format a35
column value            format a20
column isdefault        format a10
column issys_modifiable format a16

select name,
       value,
       isdefault,
       issys_modifiable,
       description
from   v$parameter
where  name = 'optimizer_adaptive_plans';

prompt
prompt --- 1) Full adaptive execution plan (with inactive rows '-') ---

select *
from table(
  dbms_xplan.display_cursor(
    sql_id          => '&&sql_id',
    cursor_child_no => to_number('&&chosen_child'),
    format          => 'ALLSTATS LAST +ADAPTIVE +OUTLINE +PEEKED_BINDS +NOTE'
  )
);

prompt
prompt --- 2) Statistics Collector nodes for this cursor ---

column operation format a30
column options   format a25

select id,
       parent_id,
       operation,
       options,
       cardinality est_rows,
       last_output_rows a_rows,
       case when nvl(cardinality,0)=0 then null else round(last_output_rows/cardinality,2) end a_over_e
from   v$sql_plan_statistics_all
where  sql_id = '&&sql_id'
and    child_number = to_number('&&chosen_child')
and    operation = 'STATISTICS COLLECTOR'
order by id;

prompt
prompt --- 3) Branch analysis below each STATISTICS COLLECTOR ---
prompt (Objects/predicates likely involved in adaptive switch)

column collector_id      format 99999
column object_owner      format a20
column object_name       format a35
column object_type       format a20
column operation         format a30
column options           format a20
column access_predicates format a70 word_wrapped
column filter_predicates format a70 word_wrapped

with plan_data as (
  select id,
         parent_id,
         operation,
         options,
         object_owner,
         object_name,
         object_type,
         cardinality,
         last_output_rows,
         access_predicates,
         filter_predicates
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
), collectors as (
  select id collector_id
  from   plan_data
  where  operation = 'STATISTICS COLLECTOR'
), tree (collector_id, id, parent_id, lvl) as (
  select c.collector_id, c.collector_id, p.parent_id, 0
  from   collectors c
         join plan_data p on p.id = c.collector_id
  union all
  select t.collector_id, p.id, p.parent_id, t.lvl + 1
  from   tree t
         join plan_data p
           on p.parent_id = t.id
)
select t.collector_id,
       t.id,
       t.parent_id,
       t.lvl,
       p.operation,
       p.options,
       p.object_owner,
       p.object_name,
       p.object_type,
       p.cardinality est_rows,
       p.last_output_rows a_rows,
       case when nvl(p.cardinality,0)=0 then null else round(p.last_output_rows/p.cardinality,2) end a_over_e,
       p.access_predicates,
       p.filter_predicates
from   tree t
       join plan_data p on p.id = t.id
where  t.lvl > 0
and    (p.object_name is not null or p.access_predicates is not null or p.filter_predicates is not null)
order by t.collector_id, t.lvl, t.id;

prompt
prompt --- 4) Likely misestimate suspects (leaf access with predicates, highest A/E ratio first) ---

column predicate_text format a90 word_wrapped

with plan_data as (
  select id,
         parent_id,
         operation,
         options,
         object_owner,
         object_name,
         cardinality,
         last_output_rows,
         access_predicates,
         filter_predicates
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
), collectors as (
  select id collector_id
  from   plan_data
  where  operation = 'STATISTICS COLLECTOR'
), tree (collector_id, id, parent_id, lvl) as (
  select c.collector_id, c.collector_id, p.parent_id, 0
  from   collectors c
         join plan_data p on p.id = c.collector_id
  union all
  select t.collector_id, p.id, p.parent_id, t.lvl + 1
  from   tree t
         join plan_data p
           on p.parent_id = t.id
)
select t.collector_id,
       p.id,
       p.operation,
       p.options,
       p.object_owner,
       p.object_name,
       p.cardinality est_rows,
       p.last_output_rows a_rows,
       case when nvl(p.cardinality,0)=0 then null else round(p.last_output_rows/p.cardinality,2) end a_over_e,
       coalesce(p.access_predicates, p.filter_predicates) predicate_text
from   tree t
       join plan_data p on p.id = t.id
where  t.lvl > 0
and    (p.operation like 'INDEX%' or p.operation like 'TABLE ACCESS%')
and    coalesce(p.access_predicates, p.filter_predicates) is not null
order by a_over_e desc nulls last, t.collector_id, p.id;

prompt
prompt --- Action hints ---
prompt 1) Focus first on rows under STATISTICS COLLECTOR with high A/E ratio and predicates.
prompt 2) If suspect is an index access predicate, check histogram/column group stats on predicate columns.
prompt 3) In DBMS_XPLAN adaptive output, rows with '-' were inactive (initial branch not chosen).

spool off

exit;
