-- #############################################################################################################
-- FILE: find_sql_template.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Searches SQL statements in library cache (V$SQL) using an input SQL text extract and reports SQL_ID, child cursor, plan hash, and key performance metrics to identify expensive candidates.
--
-- INPUT PARAMETERS:
-- &1 (sql_text) - STRING - SQL text extract used as search pattern in V$SQL (e.g., 'skew').
--
-- OUTPUT DESCRIPTION:
-- One result set of matching library cache SQL with SQL_ID, child number, obsolete flag, last active time, force matching signature, plan hash, executions, average elapsed/CPU time, average I/O metrics, and SQL text.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL statements in library cache contain a given text extract?
-- What SQL_ID, child cursors, and plan hash values match the searched SQL text?
-- Which matching statements are most expensive by average elapsed time?
-- What average logical/physical I/O and CPU metrics are observed per matching cursor?
-- Are matching cursors obsolete or recently active?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : find_sql_template.sql skew
-- #############################################################################################################
--

set pages 9999
set lines 220
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define SQL_TEXT = '&1'

begin
  if '&&SQL_TEXT' is null then
    raise_application_error(-20041, 'SQL_TEXT extract is mandatory. Usage: @find_sql_template.sql <SQL_TEXT_EXTRACT>');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Searching SQL in library cache for text extract: &&SQL_TEXT
prompt =====================================================================================================

col obsolete format a9
col last_active_time format a19
col avg_etime_ms for 999,999.99
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time_ms for 999,999.99
col force_matching_signature format 999999999999999999999999

/* PTK: Local instance scope with V$SQL (no INST_ID dimension) */
select sql_id,
child_number,
is_obsolete,
to_char(last_active_time,'yyyy-mm-dd hh24:mi:ss') last_active_time,
force_matching_signature,
plan_hash_value plan_hash,
executions execs,
(elapsed_time/1000)/decode(nvl(executions,0),0,1,executions) avg_etime_ms,
disk_reads/decode(nvl(executions,0),0,1,executions) avg_pio,
buffer_gets/decode(nvl(executions,0),0,1,executions) avg_lio,
(cpu_time/1000)/decode(nvl(executions,0),0,1,executions) avg_cpu_time_ms,
sql_text from v$sql s
where upper(sql_text) like upper('%'||'&SQL_TEXT'||'%')
and sql_text not like '%from v$sql s where upper%'
and sql_text not like '%and dbms_lob.substr(txt.sql_text,3999,1) not%'
and sql_text not like '%/* PTK */%'
order by avg_etime_ms desc, sql_id, child_number;

prompt
prompt NOTE: Rows are sorted by AVG_ETIME DESC to surface expensive candidates first.
