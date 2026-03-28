-- #############################################################################################################
-- FILE: get_plan_rac.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Retrieves RAC-wide child cursor performance context for a SQL_ID from GV$SQL, selects a target instance/child deterministically (or by explicit input), and renders detailed DBMS_XPLAN output from that chosen instance session.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze in RAC library cache (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
-- &2 (instance_number) - NUMBER - Optional RAC instance filter; use 0 or blank for all instances and auto-selection (e.g., 2 or 0).
-- &3 (child_number) - NUMBER - Optional child cursor number; use -1 or blank for auto-selection (e.g., 1 or -1).
-- &4 (min_executions) - NUMBER - Optional minimum executions preference used by auto-selection (default 1, e.g., 5).
-- &5 (top_n) - NUMBER - Optional maximum rows returned in RAC cursor summary (default 30, e.g., 50).
--
-- OUTPUT DESCRIPTION:
-- Three sections: (1) RAC child cursor summary by instance with extended KPIs and metadata, (2) selected target instance/child resolution details, (3) DBMS_XPLAN.DISPLAY_CURSOR output for selected child (best-effort from current instance cache; rerun on selected instance if needed). Output is spooled to get_plan_rac.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- On which RAC instance is this SQL_ID most expensive per execution?
-- Which child cursor/instance combination should be investigated first?
-- How do average elapsed time, CPU, and I/O differ across RAC instances for the same SQL_ID?
-- Which parsing schema/module is associated with the expensive RAC child cursor?
-- What execution plan text is exposed for the selected RAC child cursor?
-- Is the requested child/instance absent from cache and requiring fallback to AWR?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : get_plan_rac.sql cm1fyt76dwbkb 0 -1 5 30
-- #############################################################################################################
--

-- Spool output for RAC diagnostics traceability.
spool get_plan_rac.log

-- Configure SQL*Plus output settings for wide plan text.
set pages 9999
set lines 280
set long 1000000
set longchunksize 32767
set trimspool on
set verify off
set feedback on
set tab off
set termout on

-- Stop on SQL errors to avoid partial/misleading reports.
whenever sqlerror exit failure rollback

-- Capture parameters.
define sql_id = '&1'
define instance_number = '&2'
define child_number = '&3'
define min_executions = '&4'
define top_n = '&5'

-- Normalize optional parameters.
column effective_inst new_value effective_inst noprint
select case
         when trim('&&instance_number') is null then '0'
         else trim('&&instance_number')
       end as effective_inst
from dual;

column effective_child new_value effective_child noprint
select case
         when trim('&&child_number') is null then '-1'
         else trim('&&child_number')
       end as effective_child
from dual;

column effective_min_exec new_value effective_min_exec noprint
select case
         when trim('&&min_executions') is null then '1'
         else trim('&&min_executions')
       end as effective_min_exec
from dual;

column effective_top_n new_value effective_top_n noprint
select case
         when trim('&&top_n') is null then '30'
         else trim('&&top_n')
       end as effective_top_n
from dual;

-- Validate inputs and presence in GV$SQL.
declare
  l_exists number;
begin
  if '&&sql_id' is null then
    raise_application_error(-21301, 'SQL_ID is mandatory. Usage: @get_plan_rac.sql <SQL_ID> [INSTANCE|0] [CHILD|-1] [MIN_EXEC] [TOP_N]');
  end if;

  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-21302, 'Invalid SQL_ID format: &&sql_id');
  end if;

  if to_number('&&effective_inst') < 0 then
    raise_application_error(-21303, 'INSTANCE_NUMBER must be 0 (all) or >= 1.');
  end if;

  if to_number('&&effective_child') < -1 then
    raise_application_error(-21304, 'CHILD_NUMBER must be -1 (auto) or >= 0.');
  end if;

  if to_number('&&effective_min_exec') < 0 then
    raise_application_error(-21305, 'MIN_EXECUTIONS must be >= 0.');
  end if;

  if to_number('&&effective_top_n') < 1 then
    raise_application_error(-21306, 'TOP_N must be >= 1.');
  end if;

  select count(*)
    into l_exists
    from gv$sql
   where sql_id = lower('&&sql_id')
     and (to_number('&&effective_inst') = 0 or inst_id = to_number('&&effective_inst'));

  if l_exists = 0 then
    raise_application_error(-21307, 'SQL_ID ' || lower('&&sql_id') || ' not found in GV$SQL for selected scope. Use @get_plan_awr.sql <SQL_ID> [PLAN_HASH_VALUE].');
  end if;

  if to_number('&&effective_child') >= 0 then
    select count(*)
      into l_exists
      from gv$sql
     where sql_id = lower('&&sql_id')
       and child_number = to_number('&&effective_child')
       and (to_number('&&effective_inst') = 0 or inst_id = to_number('&&effective_inst'));

    if l_exists = 0 then
      raise_application_error(-21308, 'Requested CHILD_NUMBER not found in GV$SQL for selected instance scope.');
    end if;
  end if;
end;
/

-- Resolve deterministic target instance + child.
column selected_inst new_value selected_inst noprint
column selected_child new_value selected_child noprint
select to_char(inst_id) as selected_inst,
       to_char(child_number) as selected_child
  from (
    select inst_id,
           child_number,
           nvl(executions,0) as executions,
           (elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) as avg_etime_s,
           last_active_time
      from gv$sql
     where sql_id = lower('&&sql_id')
       and (to_number('&&effective_inst') = 0 or inst_id = to_number('&&effective_inst'))
       and (to_number('&&effective_child') = -1 or child_number = to_number('&&effective_child'))
     order by case when nvl(executions,0) >= to_number('&&effective_min_exec') then 0 else 1 end,
              avg_etime_s desc,
              executions desc,
              last_active_time desc nulls last,
              inst_id,
              child_number
  )
 where rownum = 1;

prompt
prompt =====================================================================================================
prompt RAC plan extraction for SQL_ID: &&sql_id
prompt INSTANCE_FILTER=&&effective_inst CHILD_MODE=&&effective_child MIN_EXEC=&&effective_min_exec TOP_N=&&effective_top_n
prompt SELECTED_INST=&&selected_inst SELECTED_CHILD=&&selected_child
prompt =====================================================================================================
prompt NOTE: Read-only script. No data change is performed.

-- Define output formats for RAC child summary.
column last_active_time         format a19
column avg_etime_s              format 999,999,999.99999
column avg_cpu_s                format 999,999,999.99999
column avg_lio                  format 999,999,999,999.9
column avg_pio                  format 999,999,999,999.9
column avg_rows                 format 999,999,999,999.9
column avg_fetches              format 999,999,999,999.9
column parsing_schema_name      format a25
column module                   format a28
column optimizer_env_hash_value format 99999999999999999999

prompt
prompt --- 1) RAC cursor summary (instance + child execution profile) ---

-- Display RAC-wide child profile ranked by average elapsed time.
with children as (
  select inst_id,
         child_number,
         plan_hash_value,
         executions,
         to_char(last_active_time,'yyyy-mm-dd hh24:mi:ss') as last_active_time,
         (elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) as avg_etime_s,
         (cpu_time/1000000)/decode(nvl(executions,0),0,1,executions) as avg_cpu_s,
         buffer_gets/decode(nvl(executions,0),0,1,executions) as avg_lio,
         disk_reads/decode(nvl(executions,0),0,1,executions) as avg_pio,
         rows_processed/decode(nvl(executions,0),0,1,executions) as avg_rows,
         fetches/decode(nvl(executions,0),0,1,executions) as avg_fetches,
         parse_calls,
         parsing_schema_name,
         module,
         optimizer_env_hash_value,
         is_obsolete,
         row_number() over (
           order by (elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) desc,
                    nvl(executions,0) desc,
                    inst_id,
                    child_number
         ) as rn
    from gv$sql
   where sql_id = lower('&&sql_id')
     and (to_number('&&effective_inst') = 0 or inst_id = to_number('&&effective_inst'))
)
select inst_id,
       child_number,
       plan_hash_value,
       executions,
       last_active_time,
       avg_etime_s,
       avg_cpu_s,
       avg_lio,
       avg_pio,
       avg_rows,
       avg_fetches,
       parse_calls,
       parsing_schema_name,
       module,
       optimizer_env_hash_value,
       is_obsolete
  from children
 where rn <= to_number('&&effective_top_n')
 order by rn;

prompt
prompt --- 2) Execution plan for selected RAC child (rendered on selected instance) ---

-- Render plan text for selected child. DBMS_XPLAN.DISPLAY_CURSOR reads current instance cache;
-- therefore this output is most reliable when executed from selected instance session/service.
select *
from table(
  dbms_xplan.display_cursor(
    sql_id          => lower('&&sql_id'),
    cursor_child_no => to_number('&&selected_child'),
    format          => 'ALLSTATS LAST ALL +OUTLINE +PEEKED_BINDS +NOTE +ADAPTIVE +ALIAS +PROJECTION'
  )
);

prompt
prompt --- Action hints ---
prompt 1) If plan text is empty here but summary shows SELECTED_INST != local instance, reconnect to that instance/service and rerun.
prompt 2) For cross-instance historical fallback, run @get_plan_awr.sql <SQL_ID> [PLAN_HASH_VALUE].
prompt 3) Use @cursor_reason.sql &&sql_id to diagnose child proliferation.

-- End spool and terminate script.
spool off
exit;
