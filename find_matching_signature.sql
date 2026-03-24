
-- #############################################################################################################
-- FILE: find_matching_signature.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Finds SQL statements sharing exact or force matching signatures with an input SQL_ID using V$SQL, and reports execution performance metrics to identify related expensive statements and potential cursor/literal variations.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze for exact/force matching signatures (13 alphanumeric characters, e.g., 'cm1fyt76dwbkb').
--
-- OUTPUT DESCRIPTION:
-- One result set listing matching SQL_ID/child cursors with signature values, plan hash, executions, average elapsed time, I/O and CPU metrics, last activity time, and SQL text; output spooled to find_matching_signature.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL statements share exact or force matching signatures with a given SQL_ID?
-- What are the performance metrics of signature-related SQL statements?
-- Which matching statements are the most expensive by average elapsed time?
-- Are there multiple child cursors associated with related signatures?
-- What plan hash values are used by signature-related SQL statements?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : find_matching_signature.sql cm1fyt76dwbkb
-- #############################################################################################################
--

spool find_matching_signature.log

set pages 9999
set lines 220
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define sql_id ='&1'

begin
  if '&&sql_id' is null then
    raise_application_error(-20081, 'SQL_ID is mandatory. Usage: @find_matching_signature.sql <SQL_ID>');
  end if;
  if not regexp_like('&&sql_id', '^[[:alnum:]]{13}$') then
    raise_application_error(-20082, 'Invalid SQL_ID format: &&sql_id');
  end if;
end;
/

--For 19c

col sql_text format a100 
col exact_matching_signature format 999999999999999999999999 
col force_matching_signature format 999999999999999999999999 
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999
col last_active_time for a19

col obsolete format a9


/* PTK: Local instance scope with V$ views (no RAC-wide INST_ID dimension) */
select sq.sql_id sql_id, sq.child_number child_number, sq.IS_OBSOLETE obsolete, sq.EXACT_MATCHING_SIGNATURE exact_matching_signature, sq.FORCE_MATCHING_SIGNATURE force_matching_signature, sq.plan_hash_value plan_hash,
sum(sq.executions) execs,
sum(sq.elapsed_time)/1000000/decode(nvl(sum(sq.executions),0),0,1,sum(sq.executions)) avg_etime,
sum(sq.disk_reads)/decode(nvl(sum(sq.executions),0),0,1,sum(sq.executions)) avg_pio,
sum(sq.buffer_gets)/decode(nvl(sum(sq.executions),0),0,1,sum(sq.executions)) avg_lio,
sum(sq.cpu_time)/1000000/decode(nvl(sum(sq.executions),0),0,1,sum(sq.executions)) avg_cpu_time,
to_char(max(sq.last_active_time),'yyyy-mm-dd hh24:mi:ss') last_active_time,
max(sq.sql_text) sql_text
from v$sql sq, v$sql ss
where ss.sql_id='&sql_id'
and (ss.EXACT_MATCHING_SIGNATURE=sq.EXACT_MATCHING_SIGNATURE or ss.FORCE_MATCHING_SIGNATURE=sq.FORCE_MATCHING_SIGNATURE)
group by sq.sql_id, sq.child_number, sq.IS_OBSOLETE, sq.EXACT_MATCHING_SIGNATURE, sq.FORCE_MATCHING_SIGNATURE, sq.plan_hash_value
order by avg_etime desc, sq.sql_id, sq.child_number;

prompt
prompt NOTE: Rows are sorted by AVG_ETIME DESC; focus first on expensive signature matches.



spool off
exit;
