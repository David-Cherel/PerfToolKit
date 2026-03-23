-- #############################################################################################################
-- Find SQL Query in in Shared Pool (Library Cache) and displays KPI's 
-- Accept an extract of sql_text as inputs (ptompted)
-- Display : SQL_ID, CHILD, PLAN_HASH, EXECS, AVG_ETIME, AVG_LIO, SQL_TEXT
-- Allows to show performance KPI's for that SQL_ID and plan_hash_value 
-- #############################################################################################################

-- Find SQL ID from SQL Test:
-- 
-- SQL> @find_sql
-- Enter value for sql_text: %skew%
-- Enter value for sql_id:
-- SQL_ID 			CHILD 	PLAN_HASH 	EXECS 	AVG_ETIME 	AVG_LIO 		SQL_TEXT
-- ------------- 	------ 	---------- 	------ 	---------- 	------------ 	-------------------------------------------------
-- 0qa98gcnnza7h 	0 		568322376 	5 		13.09 		142,646 		select avg(pk_col) from kso.skew where col1 > 0
-- 0qa98gcnnza7h 	1 		3723858078 	1 		9.80 		2,626,102 		select avg(pk_col) from kso.skew where col1 > 0
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
