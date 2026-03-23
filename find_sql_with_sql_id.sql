-- #############################################################################################################
-- Find SQL Query in in Shared Pool (Library Cache) and displays KPI's 
-- Accept a sql_id as inputs (prompted)
-- Display : SQL_ID, CHILD, IS_OBSOLETE, plan_hash, EXECS, AVG_ETIME, AVG_LIO, avg_cpu_time, SQL_TEXT
-- Allows to show performance KPI's for that SQL_ID and plan_hash_value 
-- #############################################################################################################


--
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
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999


spool find_sql_with_sql_id.log


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
(elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_etime,
disk_reads/decode(nvl(executions,0),0,1,executions) avg_pio,
buffer_gets/decode(nvl(executions,0),0,1,executions) avg_lio,
cpu_time/decode(nvl(executions,0),0,1,executions) avg_cpu_time,
sql_text from v$sql s
where s.sql_id='&sql_id'
order by avg_etime desc, sql_id, child_number;
PROMPT ****************************************************************************************************************

PROMPT NOTE: Rows are sorted by AVG_ETIME DESC to surface expensive child cursors first.



spool off

exit;

