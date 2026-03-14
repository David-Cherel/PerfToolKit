-- #############################################################################################################
-- Find SQL plan directives associated with a schema's objects
-- 
-- #############################################################################################################


-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : find_spd.sql myuser 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

-- 
--
--
--
set pages 9999
set lines 220
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define schema = '&1'

prompt
prompt =====================================================================================================
prompt Listing SQL Plan Directives for schema: &&schema
prompt =====================================================================================================

spool find_spd.log

column dir_id       format a20
column owner        format a15
column object_name  format a32
column col_name     format a22
column object_type  format a18
column scope        format a7
column type         format a18
column state        format a12
column reason       format a80 word_wrapped

select to_char(d.directive_id) dir_id,
       o.owner,
       o.object_name,
       o.subobject_name col_name,
       o.object_type,
       case when o.subobject_name is null then 'OBJECT' else 'COLUMN' end scope,
       d.type,
       d.state,
       d.reason
from   dba_sql_plan_directives d
       join dba_sql_plan_dir_objects o
         on d.directive_id = o.directive_id
where  o.owner = upper('&&schema')
order by o.owner, o.object_name, o.object_type, o.subobject_name, d.directive_id;

prompt
prompt --------------------------------
prompt Summary for schema &&schema
prompt --------------------------------

select count(distinct d.directive_id) as nb_directives,
       count(*) as nb_object_links,
       sum(case when o.subobject_name is null then 1 else 0 end) as nb_object_level,
       sum(case when o.subobject_name is not null then 1 else 0 end) as nb_column_level
from   dba_sql_plan_directives d
       join dba_sql_plan_dir_objects o
         on d.directive_id = o.directive_id
where  o.owner = upper('&&schema');

spool off

exit;
