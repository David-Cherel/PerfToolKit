-- #############################################################################################################
-- FILE: cardinality_misestimate_diagnosis.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Diagnoses cardinality misestimates for a SQL_ID from cursor cache by comparing estimated versus actual rows, listing hotspot operations, correlating predicates and stats health, and optionally gathering pending statistics for validation.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze (13 alphanumeric characters)
-- &2 (child_no) - NUMBER - Optional child cursor number; if omitted, latest active child is selected
-- &3 (apply_pending) - STRING - Optional YES/Y or NO/N flag to gather pending stats on hotspot objects
--
-- OUTPUT DESCRIPTION:
-- Multiple diagnostic result sections including selected cursor details, DBMS_XPLAN output, operation chronology, mismatch hotspots, predicate/column extraction, stats health checks, advisory commands, and pending stats visibility.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which plan operations for this SQL_ID show the largest estimated versus actual row mismatches?
-- Is real-time row-source statistics data available for the selected child cursor?
-- What are the execution profile metrics for the selected SQL child cursor?
-- Which predicates and objects are associated with cardinality hotspot operations?
-- Which implicated columns lack useful statistics or histograms?
-- Are table statistics stale or missing for impacted objects?
-- Are there existing extended statistics on impacted tables?
-- What DBMS_STATS commands are recommended to validate or improve estimates?
-- Were pending statistics gathered for hotspot objects when APPLY_PENDING is enabled?
-- Which pending statistics entries exist for implicated tables after analysis?
-- REM EMBEDDINGS END

set pages 9999
set lines 280
set long 1000000
set longchunksize 32767
set verify off
set trimspool on
set tab off
set feedback on
set termout on
set serveroutput on

whenever sqlerror exit failure rollback

define sql_id        = '&1'
define child_no      = '&2'
define apply_pending = '&3'

begin
  if '&&sql_id' is null then
    raise_application_error(-20911,
      'SQL_ID is mandatory. Usage: @cardinality_misestimate_diagnosis.sql <SQL_ID> [CHILD_NUMBER] [APPLY_PENDING]');
  end if;

  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20912, 'Invalid SQL_ID format: &&sql_id');
  end if;

  if '&&child_no' is not null and not regexp_like('&&child_no', '^[0-9]+$') then
    raise_application_error(-20913, 'CHILD_NUMBER must be numeric when provided.');
  end if;

  if upper(nvl('&&apply_pending','NO')) not in ('NO','N','YES','Y') then
    raise_application_error(-20914, 'APPLY_PENDING must be YES/Y or NO/N (or empty).');
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

column apply_mode new_value apply_mode noprint
select case when upper(nvl('&&apply_pending','NO')) in ('YES','Y') then 'YES' else 'NO' end apply_mode
from dual;

column rt_stats_available new_value rt_stats_available noprint
select case
         when exists (
           select 1
           from   v$sql_plan_statistics_all
           where  sql_id = '&&sql_id'
           and    child_number = case
                                   when nullif('&&child_no','') is not null then to_number('&&child_no')
                                   else (
                                     select child_number
                                     from   v$sql
                                     where  sql_id = '&&sql_id'
                                     order by last_active_time desc nulls last
                                     fetch first 1 row only
                                   )
                                 end
           and    last_output_rows is not null
         ) then 'YES'
         else 'NO'
       end as rt_stats_available
from dual;

spool cardinality_misestimate_diagnosis.log

prompt
prompt =========================================================================================================
prompt Cardinality misestimate diagnosis for SQL_ID=&&sql_id CHILD_NUMBER=&&chosen_child APPLY_PENDING=&&apply_mode
prompt =========================================================================================================
prompt NOTE: Cursor-cache analysis (v$sql_plan_statistics_all). APPLY_PENDING controls optional pending-gather only.

prompt
prompt --- 0) Selected cursor details ---

column sql_id                   format a13
column child_number             format 99999
column is_obsolete              format a11
column last_active_time         format a19
column parsing_schema_name      format a25
column force_matching_signature format 99999999999999999999
column plan_hash                format 9999999999
column execs                    format 999999999
column avg_ela_time_ms          format 9999990.999999
column avg_pio                  format 9999999990.99
column avg_lio                  format 9999999990.99
column avg_cpu_time_ms          format 9999999990.99
column sql_text            format a120 word_wrapped

select /* PTK */ sql_id,
       child_number,
       is_obsolete,
       to_char(last_active_time,'yyyy-mm-dd hh24:mi:ss') last_active_time,
       parsing_schema_name,
       force_matching_signature,
       plan_hash_value plan_hash,
       executions execs,
       (elapsed_time/1000)/decode(nvl(executions,0),0,1,executions) avg_ela_time_ms,
       disk_reads/decode(nvl(executions,0),0,1,executions) avg_pio,
       buffer_gets/decode(nvl(executions,0),0,1,executions) avg_lio,
       (cpu_time/1000)/decode(nvl(executions,0),0,1,executions) avg_cpu_time_ms,
       sql_text
from   v$sql s
where  s.sql_id = '&&sql_id'
and    s.child_number = to_number('&&chosen_child')
and    s.sql_text not like '%/* PTK */%'
order by avg_ela_time_ms desc, sql_id, child_number;

prompt
prompt --- 1) Full execution plan with real-time stats ---

select *
from table(
  dbms_xplan.display_cursor(
    sql_id          => '&&sql_id',
    cursor_child_no => to_number('&&chosen_child'),
    format          => 'ALLSTATS LAST ALL +OUTLINE +PREDICATE +NOTE +ADAPTIVE'
  )
);

prompt
prompt --- 1b) Real-time row-source stats availability check ---
prompt (If missing, cardinality diagnosis is limited because A-Rows are not populated.)

declare
  l_patch_name       varchar2(30);
begin
  if '&&rt_stats_available' = 'NO' then
    l_patch_name := substr('PTK_GPS_'||'&&sql_id'||'_'||'&&chosen_child',1,30);

    dbms_output.put_line('WARNING: Basic plan statistics are not available for this cursor child.');
    dbms_output.put_line('Likely causes:');
    dbms_output.put_line('  - Query not executed with hint /*+ gather_plan_statistics */');
    dbms_output.put_line('  - statistics_level not set to ALL (session/system).');
    dbms_output.put_line(' ');
    dbms_output.put_line('Recommended command (using existing helper script):');
    dbms_output.put_line('@create_sql_patch.sql '||'&&sql_id'||' "gather_plan_statistics" '||l_patch_name);
    dbms_output.put_line(' ');
    dbms_output.put_line('Equivalent direct command template (advisory, not executed):');
    dbms_output.put_line('declare v_name varchar2(30); begin');
    dbms_output.put_line('  v_name := '''||l_patch_name||''';');
    dbms_output.put_line('  dbms_output.put_line(sys.dbms_sqldiag.create_sql_patch(');
    dbms_output.put_line('    sql_id => '''||'&&sql_id'||''', hint_text => q''[gather_plan_statistics]'', name => v_name));');
    dbms_output.put_line('end;');
    dbms_output.put_line('/');
  else
    dbms_output.put_line('OK: real-time row-source statistics detected (last_output_rows populated).');
  end if;
end;
/

prompt
prompt --- 3) Cardinality misestimate hotspots (highest mismatch first) ---

column hotspots_status format a120

select case
         when '&&rt_stats_available' = 'NO' then
           'INFO: section skipped because real-time row-source stats are not available (A-Rows missing).'
         else
           'INFO: real-time stats available -> computing hotspot discrepancies.'
       end as hotspots_status
from dual;

column access_predicates format a80 word_wrapped
column filter_predicates format a80 word_wrapped

with plan_data as (
  select id,
         parent_id,
         operation,
         options,
         object_owner,
         object_name,
         object_type,
         cardinality est_rows,
         last_output_rows a_rows,
         access_predicates,
         filter_predicates
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
)
select id,
       parent_id,
       operation,
       options,
       object_owner,
       object_name,
       object_type,
       est_rows,
       a_rows,
       round(greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                      (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)), 2) as mismatch_factor,
       access_predicates,
       filter_predicates
from   plan_data
where  '&&rt_stats_available' = 'YES'
and    (access_predicates is not null or filter_predicates is not null or object_name is not null)
and    greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)) >= 5
order by mismatch_factor desc, id;

prompt
prompt --- 4) Predicate alias/column extraction for hotspot steps (best effort) ---

column alias_name  format a25
column column_name format a35
column predicate_text format a100 word_wrapped

with plan_data as (
  select id,
         parent_id,
         operation,
         options,
         object_owner,
         object_name,
         object_type,
         nvl(access_predicates, filter_predicates) as predicate_text,
         cardinality est_rows,
         last_output_rows a_rows,
         object_alias
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
), hotspots as (
  select *
  from   plan_data
  where  greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                  (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)) >= 5
  and    predicate_text is not null
), extracted as (
  select h.id,
         h.operation,
         h.options,
         h.object_owner,
         h.object_name,
         h.object_type,
         h.predicate_text,
         upper(regexp_substr(h.predicate_text, '"([^"]+)"\."([^"]+)"', 1, level, null, 1)) alias_name,
         upper(regexp_substr(h.predicate_text, '"([^"]+)"\."([^"]+)"', 1, level, null, 2)) column_name
  from   hotspots h
  connect by prior h.id = h.id
         and prior sys_guid() is not null
         and level <= regexp_count(h.predicate_text, '"([^"]+)"\."([^"]+)"')
), alias_map as (
  select distinct
         upper(regexp_substr(object_alias, '^[^@]+')) as alias_name,
         object_owner,
         object_name
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
  and    object_alias is not null
  and    object_name is not null
)
select e.id,
       e.operation,
       e.options,
       e.alias_name,
       e.column_name,
       nvl(a.object_owner, e.object_owner) as mapped_owner,
       nvl(a.object_name,  e.object_name)  as mapped_object,
       e.predicate_text
from   extracted e
       left join alias_map a
         on a.alias_name = e.alias_name
where  e.alias_name is not null
order by e.id, e.alias_name, e.column_name;

prompt
prompt --- 5) Stats health for implicated objects/columns ---

column object_type       format a20
column stats_state       format a14
column stats_status      format a14
column table_stats_state format a14
column col_stats_state   format a14
column col_stats_status  format a14
column histogram         format a15
column stale_stats       format a6

prompt --- 5a) Hotspot objects from execution plan (typed) ---

with plan_data as (
  select object_owner,
         object_name,
         object_type,
         cardinality est_rows,
         last_output_rows a_rows
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
), hotspots as (
  select distinct object_owner,
                  object_name,
                  object_type
  from   plan_data
  where  greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                  (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)) >= 5
  and    object_owner is not null
  and    object_name is not null
  and    object_type in ('TABLE','INDEX','TABLE PARTITION','INDEX PARTITION','TABLE SUBPARTITION','INDEX SUBPARTITION')
)
select object_owner as owner,
       object_name,
       object_type
from   hotspots
order by object_owner, object_type, object_name;

prompt
prompt --- 5b) Object-level stats presence (table/index) ---

with plan_data as (
  select object_owner,
         object_name,
         object_type,
         cardinality est_rows,
         last_output_rows a_rows
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
), hotspot_objects as (
  select distinct object_owner,
                  object_name,
                  object_type
  from   plan_data
  where  greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                  (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)) >= 5
  and    object_owner is not null
  and    object_name is not null
  and    object_type in ('TABLE','INDEX','TABLE PARTITION','INDEX PARTITION','TABLE SUBPARTITION','INDEX SUBPARTITION')
)
select h.object_owner as owner,
       h.object_name,
       h.object_type,
       case
         when h.object_type like 'INDEX%' then case when i.last_analyzed is null then 'MISSING' else 'OK' end
         when h.object_type like 'TABLE%' then case when t.last_analyzed is null then 'MISSING' else 'OK' end
         else 'N/A'
       end as stats_state,
       case
         when h.object_type like 'INDEX%' and i.last_analyzed is null then 'MISSING'
         when h.object_type like 'TABLE%' and t.last_analyzed is null then 'MISSING'
         when h.object_type like 'INDEX%' and i.stale_stats = 'YES' then 'STALE'
         when h.object_type like 'TABLE%' and t.stale_stats = 'YES' then 'STALE'
         when h.object_type like 'INDEX%' and i.stale_stats = 'NO' then 'FRESH'
         when h.object_type like 'TABLE%' and t.stale_stats = 'NO' then 'FRESH'
         else 'UNKNOWN'
       end as stats_status,
       case
         when h.object_type like 'INDEX%' then i.stale_stats
         when h.object_type like 'TABLE%' then t.stale_stats
         else null
       end as stale_stats,
       case
         when h.object_type like 'INDEX%' then to_char(i.last_analyzed,'yyyy-mm-dd hh24:mi:ss')
         when h.object_type like 'TABLE%' then to_char(t.last_analyzed,'yyyy-mm-dd hh24:mi:ss')
         else null
       end as last_analyzed
from   hotspot_objects h
       left join dba_tab_statistics t
         on h.object_type like 'TABLE%'
        and t.owner = h.object_owner
        and t.table_name = h.object_name
        and t.partition_name is null
       left join dba_ind_statistics i
         on h.object_type like 'INDEX%'
        and i.owner = h.object_owner
        and i.index_name = h.object_name
        and i.partition_name is null
order by h.object_owner, h.object_type, h.object_name;

prompt
prompt --- 5c) Partition stats coverage (table partitions and index partitions) ---

with plan_data as (
  select object_owner,
         object_name,
         object_type,
         cardinality est_rows,
         last_output_rows a_rows
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')),
  hotspot_tables as (select distinct object_owner as owner,
                  object_name  as table_name
  from   plan_data
  where  greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                  (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)) >= 5
  and    object_owner is not null
  and    object_name is not null
  and    object_type like 'TABLE%'), 
  hotspot_indexes as (select distinct object_owner as owner,
                  object_name  as index_name
  from   plan_data
  where  greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                  (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)) >= 5
  and    object_owner is not null
  and    object_name is not null
  and    object_type like 'INDEX%')
select t.owner,
       t.table_name as object_name,
       'TABLE PARTITION' as object_type,
       count(ts.partition_name) as partition_rows,
       sum(case when ts.last_analyzed is not null then 1 else 0 end) as partition_with_stats_rows,
       sum(case when ts.stale_stats = 'YES' then 1 else 0 end) as partition_stale_rows
from   hotspot_tables t
       left join dba_tab_statistics ts
         on ts.owner = t.owner
        and ts.table_name = t.table_name
        and ts.partition_name is not null
group by t.owner, t.table_name
union all
select i.owner,
       i.index_name as object_name,
       'INDEX PARTITION' as object_type,
       count(is2.partition_name) as partition_rows,
       sum(case when is2.last_analyzed is not null then 1 else 0 end) as partition_with_stats_rows,
       sum(case when is2.stale_stats = 'YES' then 1 else 0 end) as partition_stale_rows
from   hotspot_indexes i
       left join dba_ind_statistics is2
         on is2.owner = i.owner
        and is2.index_name = i.index_name
        and is2.partition_name is not null
group by i.owner, i.index_name
order by 1, 3, 2;

prompt
prompt --- 5d) Column stats and histograms for implicated predicate columns ---

with plan_data as (
  select id,
         nvl(access_predicates, filter_predicates) as predicate_text,
         object_owner,
         object_name,
         object_type,
         object_alias,
         cardinality est_rows,
         last_output_rows a_rows
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
), hotspots as (
  select *
  from   plan_data
  where  greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                  (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)) >= 5
), extracted as (
  select h.id,
         upper(regexp_substr(h.predicate_text, '"([^"]+)"\."([^"]+)"', 1, level, null, 1)) alias_name,
         upper(regexp_substr(h.predicate_text, '"([^"]+)"\."([^"]+)"', 1, level, null, 2)) column_name,
         h.object_owner,
         h.object_name,
         h.object_type
  from   hotspots h
  where  h.predicate_text is not null
  connect by prior h.id = h.id
         and prior sys_guid() is not null
         and level <= regexp_count(h.predicate_text, '"([^"]+)"\."([^"]+)"')
), alias_map as (
  select distinct
         upper(regexp_substr(object_alias, '^[^@]+')) as alias_name,
         object_owner,
         object_name,
         object_type
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
  and    object_alias is not null
  and    object_name is not null
), targets as (
  select distinct
         nvl(a.object_owner, e.object_owner) as owner,
         case
           when a.object_type like 'TABLE%' then a.object_name
           when e.object_type like 'TABLE%' then e.object_name
           else null
         end as table_name,
         e.column_name
  from   extracted e
         left join alias_map a
           on a.alias_name = e.alias_name
  where  e.column_name is not null
)
select t.owner,
       t.table_name,
       t.column_name,
       case when ts.last_analyzed is null then 'MISSING' else 'OK' end as table_stats_state,
       case
         when ts.last_analyzed is null then 'MISSING'
         when ts.stale_stats = 'YES' then 'STALE'
         when ts.stale_stats = 'NO' then 'FRESH'
         else 'UNKNOWN'
       end as stats_status,
       ts.stale_stats,
       to_char(ts.last_analyzed,'yyyy-mm-dd hh24:mi:ss') as table_last_analyzed,
       case when cs.last_analyzed is null then 'MISSING' else 'OK' end as col_stats_state,
       case
         when cs.last_analyzed is null then 'MISSING'
         when ts.stale_stats = 'YES' then 'STALE'
         when ts.stale_stats = 'NO' then 'FRESH'
         else 'UNKNOWN'
       end as col_stats_status,
       cs.histogram,
       cs.num_distinct,
       cs.num_buckets,
       to_char(cs.last_analyzed,'yyyy-mm-dd hh24:mi:ss') as col_last_analyzed
from   targets t
       left join dba_tab_statistics ts
         on ts.owner = t.owner
        and ts.table_name = t.table_name
        and ts.partition_name is null
       left join dba_tab_col_statistics cs
         on cs.owner = t.owner
        and cs.table_name = t.table_name
        and cs.column_name = t.column_name
where  t.table_name is not null
order by t.owner, t.table_name, t.column_name;

prompt
prompt --- 6) Existing extension stats on implicated tables ---

column extension format a90 word_wrapped

with implicated_tables as (
  select distinct object_owner owner, object_name table_name
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
  and    object_owner is not null
  and    object_name is not null
)
select e.owner,
       e.table_name,
       e.extension_name,
       e.extension
from   dba_stat_extensions e
       join implicated_tables t
         on t.owner = e.owner
        and t.table_name = e.table_name
order by e.owner, e.table_name, e.extension_name;

prompt
prompt --- 7) Advisory recommendations and generated commands (not executed) ---

column recommendation format a180 word_wrapped
column advisory_status format a120

select case
         when '&&rt_stats_available' = 'NO' then
           'INFO: section skipped because real-time row-source stats are not available (A-Rows missing).'
         else
           'INFO: real-time stats available -> generating advisory recommendations.'
       end as advisory_status
from dual;

with plan_data as (
  select id,
         operation,
         options,
         object_owner,
         object_name,
         object_type,
         cardinality est_rows,
         last_output_rows a_rows,
         nvl(access_predicates, filter_predicates) as predicate_text
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
), hotspots as (
  select *
  from   plan_data
  where  '&&rt_stats_available' = 'YES'
  and    greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                  (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)) >= 5
), hotspot_objects as (
  select distinct object_owner,
                  object_name,
                  object_type
  from   hotspots
  where  object_owner is not null
  and    object_name is not null
  and    object_type in ('TABLE','INDEX','TABLE PARTITION','INDEX PARTITION','TABLE SUBPARTITION','INDEX SUBPARTITION')
)
select 'HOTSPOT ID '||id||' -> mismatch='||
       round(greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                      (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)),2)||
       ', OP='||operation||' '||nvl(options,'')||
       ', OBJ='||nvl(object_owner||'.'||object_name,'(none)')||
       ', TYPE='||nvl(object_type,'(none)') as recommendation
from hotspots
union all
select 'COMMAND: exec dbms_stats.set_table_prefs('''||object_owner||''','''||object_name||''',''PUBLISH'',''FALSE'');'
from   hotspot_objects
where  object_type like 'TABLE%'
union all
select 'COMMAND: exec dbms_stats.gather_table_stats('''||object_owner||''','''||object_name||''', method_opt=>''FOR ALL COLUMNS SIZE AUTO'', cascade=>dbms_stats.auto_cascade, no_invalidate=>false);'
from   hotspot_objects
where  object_type like 'TABLE%'
union all
select 'COMMAND TEMPLATE (extended stats): select dbms_stats.create_extended_stats('''||object_owner||''','''||object_name||''',''(<col1>,<col2>)'') from dual;'
from   hotspot_objects
where  object_type like 'TABLE%'
union all
select 'COMMAND: exec dbms_stats.gather_index_stats('''||object_owner||''','''||object_name||''', no_invalidate=>false);'
from   hotspot_objects
where  object_type like 'INDEX%'
order by 1;

prompt
prompt --- 8) Optional APPLY_PENDING execution (pending gather only; never publish) ---

declare
  v_apply varchar2(3) := upper(nvl('&&apply_mode','NO'));
begin
  if v_apply in ('YES','Y') then
    dbms_output.put_line('APPLY_PENDING=YES -> gathering pending stats on hotspot objects...');

    for r in (
      with plan_data as (
        select object_owner,
               object_name,
               object_type,
               cardinality est_rows,
               last_output_rows a_rows
        from   v$sql_plan_statistics_all
        where  sql_id = '&&sql_id'
        and    child_number = to_number('&&chosen_child')
      ), hotspots as (
        select distinct object_owner,
                        object_name,
                        object_type
        from   plan_data
        where  greatest((nvl(a_rows,0)+1)/(nvl(est_rows,0)+1),
                        (nvl(est_rows,0)+1)/(nvl(a_rows,0)+1)) >= 5
        and    object_owner is not null
        and    object_name is not null
      )
      select h.object_owner,
             h.object_name,
             h.object_type
      from   hotspots h
      where  h.object_type in ('TABLE','INDEX')
      order by 1, 3, 2
    ) loop
      begin
        if r.object_type = 'TABLE' then
          dbms_stats.set_table_prefs(
            ownname => r.object_owner,
            tabname => r.object_name,
            pname   => 'PUBLISH',
            pvalue  => 'FALSE'
          );

          dbms_stats.gather_table_stats(
            ownname       => r.object_owner,
            tabname       => r.object_name,
            method_opt    => 'FOR ALL COLUMNS SIZE AUTO',
            cascade       => dbms_stats.auto_cascade,
            no_invalidate => false
          );

          dbms_output.put_line('  OK: pending table stats gathered for '||r.object_owner||'.'||r.object_name||' (TYPE='||r.object_type||')');
        elsif r.object_type = 'INDEX' then
          dbms_stats.gather_index_stats(
            ownname       => r.object_owner,
            indname       => r.object_name,
            no_invalidate => false
          );

          dbms_output.put_line('  OK: index stats gathered for '||r.object_owner||'.'||r.object_name||' (TYPE='||r.object_type||')');
        else
          dbms_output.put_line('  INFO: skipped unsupported object type for apply step -> '||r.object_owner||'.'||r.object_name||' (TYPE='||r.object_type||')');
        end if;
      exception
        when others then
          dbms_output.put_line('  WARN: could not gather stats for '||r.object_owner||'.'||r.object_name||' (TYPE='||r.object_type||') -> '||sqlerrm);
      end;
    end loop;
  else
    dbms_output.put_line('APPLY_PENDING=NO -> advisory mode only, no DBMS_STATS gather executed.');
  end if;
end;
/

prompt
prompt --- 9) Pending stats visibility for implicated tables ---

with implicated_tables as (
  select distinct object_owner owner, object_name table_name
  from   v$sql_plan_statistics_all
  where  sql_id = '&&sql_id'
  and    child_number = to_number('&&chosen_child')
  and    object_owner is not null
  and    object_name is not null
  and    object_type like 'TABLE%'
)
select p.owner,
       p.table_name
from   dba_tab_pending_stats p
       join implicated_tables t
         on t.owner = p.owner
        and t.table_name = p.table_name
order by p.owner, p.table_name;

prompt

prompt --- 10) Suggested validation workflow ---

declare
begin
  if '&&rt_stats_available' = 'NO' then
    dbms_output.put_line('INFO: section skipped because real-time row-source stats are not available (A-Rows missing).');
  else
    dbms_output.put_line('1) Test session with pending stats ON:');
    dbms_output.put_line('     alter session set optimizer_use_pending_statistics=true;');
    dbms_output.put_line('     -- run the target SQL with /*+ gather_plan_statistics */');
    dbms_output.put_line('     select * from table(dbms_xplan.display_cursor(null,null,''ALLSTATS LAST ALL +PREDICATE +NOTE''));');
    dbms_output.put_line('2) Baseline session with pending stats OFF:');
    dbms_output.put_line('     alter session set optimizer_use_pending_statistics=false;');
    dbms_output.put_line('     -- run same SQL and compare elapsed/cpu/buffer gets/rowsource A-rows vs E-rows');
    dbms_output.put_line('3) If validated, publish (manual command, not executed by this script):');
    dbms_output.put_line('     exec dbms_stats.publish_pending_stats(''<OWNER>'',''<TABLE_NAME>'');');
    dbms_output.put_line('NOTE: Pending stats publication applies to table stats; index stats gathered directly are immediate.');
  end if;
end;
/

spool off

exit;
