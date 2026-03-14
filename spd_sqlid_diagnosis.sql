-- #############################################################################################################
-- SQL Plan Directive diagnosis from SQL_ID
--
-- Purpose:
--   1) Verify hidden parameters related to SQL Plan Directive management/usage
--   2) Detect SQL Plan Directives potentially related to a SQL_ID
--      (V$SQL -> V$SQL_PLAN object references -> DBA_SQL_PLAN_DIR_OBJECTS / DBA_SQL_PLAN_DIRECTIVES)
--   3) If directives are found, display object/column statistics and extended statistics metadata
--
-- Usage:
--   @spd_sqlid_diagnosis.sql <SQL_ID> [CHILD_NUMBER]
--
-- Example:
--   @spd_sqlid_diagnosis.sql cm1fyt76dwbkb
--   @spd_sqlid_diagnosis.sql cm1fyt76dwbkb 0
-- #############################################################################################################

set pages 9999
set lines 260
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
    raise_application_error(-20801, 'SQL_ID is mandatory. Usage: @spd_sqlid_diagnosis.sql <SQL_ID> [CHILD_NUMBER]');
  end if;
  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20802, 'Invalid SQL_ID format: &&sql_id');
  end if;
  if '&&child_no' is not null and not regexp_like('&&child_no', '^[0-9]+$') then
    raise_application_error(-20803, 'CHILD_NUMBER must be numeric when provided.');
  end if;
end;
/

spool spd_sqlid_diagnosis.log

prompt
prompt =====================================================================================================
prompt SQL Plan Directive diagnosis for SQL_ID=&&sql_id CHILD_NUMBER=&&child_no
prompt =====================================================================================================
prompt NOTE: Read-only report. No data change is performed.

prompt
prompt --- 1) Hidden parameter checks ---

column name             format a45
column value            format a20
column isdefault        format a10
column issys_modifiable format a16

select name,
       value,
       isdefault,
       issys_modifiable,
       description
from   v$parameter
where  name in (
         '_sql_plan_directive_mgmt_control',
         '_optimizer_dsdir_usage_control',
         'optimizer_adaptive_statistics'
       )
order by name;

prompt
prompt --- 2) Candidate directives for SQL_ID (object correlation through V$SQL_PLAN) ---

column dir_id      format a20
column owner       format a20
column object_name format a35
column col_name    format a30
column object_type format a18
column type        format a20
column state       format a12
column reason      format a90 word_wrapped

with sql_obj as (
  select distinct
         s.sql_id,
         s.child_number,
         s.plan_hash_value,
         p.object_owner,
         p.object_name,
         p.object_type
  from   v$sql s
         join v$sql_plan p
           on p.sql_id = s.sql_id
          and p.child_number = s.child_number
  where  s.sql_id = '&&sql_id'
  and   (nullif('&&child_no','') is null or s.child_number = to_number(nullif('&&child_no','')))
  and    p.object_owner is not null
  and    p.object_name is not null
)
select so.sql_id,
       so.child_number,
       so.plan_hash_value,
       to_char(d.directive_id) dir_id,
       o.owner,
       o.object_name,
       o.subobject_name col_name,
       o.object_type,
       d.type,
       d.state,
       d.reason
from   sql_obj so
       join dba_sql_plan_dir_objects o
         on o.owner = so.object_owner
        and o.object_name = so.object_name
       join dba_sql_plan_directives d
         on d.directive_id = o.directive_id
order by so.child_number, so.plan_hash_value, o.owner, o.object_name, o.object_type, o.subobject_name;

prompt
prompt --- 3a) Object stats for directive-related objects ---

column stale_stats   format a6
column last_analyzed format a20
column stattype_locked format a15

with dir_objs as (
  with sql_obj as (
    select distinct
           s.sql_id,
           s.child_number,
           p.object_owner,
           p.object_name
    from   v$sql s
           join v$sql_plan p
             on p.sql_id = s.sql_id
            and p.child_number = s.child_number
    where  s.sql_id = '&&sql_id'
    and   (nullif('&&child_no','') is null or s.child_number = to_number(nullif('&&child_no','')))
    and    p.object_owner is not null
    and    p.object_name is not null
  )
  select distinct o.owner, o.object_name
  from   sql_obj so
         join dba_sql_plan_dir_objects o
           on o.owner = so.object_owner
          and o.object_name = so.object_name
)
select t.owner,
       t.table_name,
       t.num_rows,
       t.blocks,
       t.sample_size,
       t.stale_stats,
       to_char(t.last_analyzed,'yyyy-mm-dd hh24:mi:ss') last_analyzed,
       t.stattype_locked
from   dba_tab_statistics t
       join dir_objs d
         on d.owner = t.owner
        and d.object_name = t.table_name
where  t.object_type = 'TABLE'
order by t.owner, t.table_name;

prompt
prompt --- 3b) Column stats for directive-related columns ---

column column_name  format a35
column histogram    format a18
column density      format 9.999999999999

with dir_cols as (
  with sql_obj as (
    select distinct
           s.sql_id,
           s.child_number,
           p.object_owner,
           p.object_name
    from   v$sql s
           join v$sql_plan p
             on p.sql_id = s.sql_id
            and p.child_number = s.child_number
    where  s.sql_id = '&&sql_id'
    and   (nullif('&&child_no','') is null or s.child_number = to_number(nullif('&&child_no','')))
    and    p.object_owner is not null
    and    p.object_name is not null
  )
  select distinct o.owner, o.object_name, o.subobject_name column_name
  from   sql_obj so
         join dba_sql_plan_dir_objects o
           on o.owner = so.object_owner
          and o.object_name = so.object_name
  where  o.subobject_name is not null
)
select c.owner,
       c.table_name,
       c.column_name,
       c.num_distinct,
       c.num_nulls,
       c.num_buckets,
       c.histogram,
       c.density,
       to_char(c.last_analyzed,'yyyy-mm-dd hh24:mi:ss') last_analyzed
from   dba_tab_col_statistics c
       join dir_cols d
         on d.owner = c.owner
        and d.object_name = c.table_name
        and d.column_name = c.column_name
order by c.owner, c.table_name, c.column_name;

prompt
prompt --- 3c) Extended statistics metadata (column groups) for directive-related tables ---

column extension_name format a35
column extension      format a80

with dir_objs as (
  with sql_obj as (
    select distinct
           s.sql_id,
           s.child_number,
           p.object_owner,
           p.object_name
    from   v$sql s
           join v$sql_plan p
             on p.sql_id = s.sql_id
            and p.child_number = s.child_number
    where  s.sql_id = '&&sql_id'
    and   (nullif('&&child_no','') is null or s.child_number = to_number(nullif('&&child_no','')))
    and    p.object_owner is not null
    and    p.object_name is not null
  )
  select distinct o.owner, o.object_name
  from   sql_obj so
         join dba_sql_plan_dir_objects o
           on o.owner = so.object_owner
          and o.object_name = so.object_name
)
select e.owner,
       e.table_name,
       e.extension_name,
       e.extension,
       e.creator,
       e.droppable
from   dba_stat_extensions e
       join dir_objs d
         on d.owner = e.owner
        and d.object_name = e.table_name
order by e.owner, e.table_name, e.extension_name;

prompt
prompt --- Action hints ---
prompt 1) If directives are USABLE and REASON mentions missing stats/skew, review histograms and column groups.
prompt 2) If directives are SUPERSEDED, verify whether newer stats (histogram/extended stats) now cover the case.
prompt 3) Check plan note for "Sql Plan Directive used for this statement" in DBMS_XPLAN +NOTE.

spool off

exit;
