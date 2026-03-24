
-- #############################################################################################################
-- FILE: find_sql_with_sql_id.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays library cache cursor details and performance metrics for a specific SQL_ID from V$SQL, including child cursors, plan hash values, activity timestamps, and average execution/I/O/CPU indicators.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze in library cache (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
--
-- OUTPUT DESCRIPTION:
-- One result set listing SQL_ID child cursors with obsolete flag, last active time, force matching signature, plan hash, executions, average elapsed time, average physical/logical I/O, average CPU time, and SQL text; output spooled.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which child cursors currently exist in library cache for a given SQL_ID?
-- What plan hash values are associated with the SQL_ID?
-- Which child cursors are obsolete versus active?
-- What are average elapsed time, I/O, and CPU metrics for each child cursor?
-- When was each child cursor last active?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : find_sql_with_sql_id.sql cm1fyt76dwbkb
-- #############################################################################################################
--

spool find_sql_with_sql_id.log

define sql_id ='&1'
set pages 9999
set lines 220
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

begin
  if '&&sql_id' is null then
    raise_application_error(-20061, 'SQL_ID is mandatory. Usage: @find_sql_with_sql_id.sql <SQL_ID>');
  end if;
  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20062, 'Invalid SQL_ID format: &&sql_id');
  end if;
end;
/

col obsolete format a9
col last_active_time format a19
col force_matching_signature format 999999999999999999999999
col avg_ela_time_ms for 999,999.99
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time_ms for 999,999.99




PROMPT ****************************************************************************************************************
PROMPT In Library Cache :
PROMPT ****************************************************************************************************************
/* PTK: Local instance scope with V$SQL (no INST_ID dimension) */
select sql_id,
child_number,
is_obsolete,
to_char(last_active_time,'yyyy-mm-dd hh24:mi:ss') last_active_time,
force_matching_signature,
plan_hash_value plan_hash,
executions execs,
(elapsed_time/1000)/decode(nvl(executions,0),0,1,executions) avg_ela_time_ms,
disk_reads/decode(nvl(executions,0),0,1,executions) avg_pio,
buffer_gets/decode(nvl(executions,0),0,1,executions) avg_lio,
(cpu_time/1000)/decode(nvl(executions,0),0,1,executions) avg_cpu_time_ms,
sql_text from v$sql s
where s.sql_id='&sql_id'
order by avg_etime desc, sql_id, child_number;
PROMPT ****************************************************************************************************************

PROMPT NOTE: Rows are sorted by AVG_ETIME DESC to surface expensive child cursors first.




spool off
exit;
