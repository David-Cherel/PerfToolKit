-- #############################################################################################################
-- Find other Matching Signature with a SQL_ID as input
-- #############################################################################################################

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : find_matching_signature.sql cm1fyt76dwbkb 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set lines 180
set pages 999
define sql_id ='&1'
--For 19c
spool find_matching_signature.log

col sql_text format a100 
col exact_matching_signature format 999999999999999999999999 
col force_matching_signature format 999999999999999999999999 
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999

col obsolete format a9


/* PTK */ select sq.inst_id instance, sq.sql_id sql_id, sq.child_number child_number, sq.IS_OBSOLETE obsolete, sq.EXACT_MATCHING_SIGNATURE exact_matching_signature, sq.FORCE_MATCHING_SIGNATURE force_matching_signature, sq.plan_hash_value plan_hash,
sum(sq.executions) execs,
sum(sq.elapsed_time)/1000000/decode(nvl(sum(sq.executions),0),0,1,sum(sq.executions)) avg_etime,
sum(sq.disk_reads)/decode(nvl(sum(sq.executions),0),0,1,sum(sq.executions)) avg_pio,
sum(sq.buffer_gets)/decode(nvl(sum(sq.executions),0),0,1,sum(sq.executions)) avg_lio,
sum(sq.cpu_time)/1000000/decode(nvl(sum(sq.executions),0),0,1,sum(sq.executions)) avg_cpu_time,
max(sq.sql_text) sql_text
from gv$sql sq, gv$sql ss
where ss.sql_id='&sql_id'
and (ss.EXACT_MATCHING_SIGNATURE=sq.EXACT_MATCHING_SIGNATURE or ss.FORCE_MATCHING_SIGNATURE=sq.FORCE_MATCHING_SIGNATURE)
group by sq.inst_id, sq.sql_id, sq.child_number, sq.IS_OBSOLETE, sq.EXACT_MATCHING_SIGNATURE, sq.FORCE_MATCHING_SIGNATURE, sq.plan_hash_value
order by 1, 2, 3;


spool off

exit;
