-- #############################################################################################################
-- Find other Matching Signature with a SQL_ID as input in Statspack snapshots 
-- #############################################################################################################

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : find_matching_signature_statspack.sql cm1fyt76dwbkb 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set lines 180
set pages 999
define sql_id ='&1'
spool find_matching_signature_statspack.log



set lines 180
col INSTANCE_NUMBER for 99999
col exact_matching_signature format 999999999999999999999999 
col force_matching_signature format 999999999999999999999999 

/* PTK */ select distinct sqpu.INSTANCE_NUMBER,sqltext.SQL_TEXT,  sqpu.sql_id, sqpu.plan_hash_value, sum1.EXACT_MATCHING_SIGNATURE , 
sum1.FORCE_MATCHING_SIGNATURE 
from stats$sql_plan_usage sqpu,  STATS$SQLTEXT sqltext, STATS$SQL_SUMMARY sum1, STATS$SQL_SUMMARY sum2
where sqpu.SQL_ID=sqltext.SQL_ID
and sum1.SQL_ID=sqpu.SQL_ID
and (sum1.EXACT_MATCHING_SIGNATURE=sum2.EXACT_MATCHING_SIGNATURE or sum1.FORCE_MATCHING_SIGNATURE=sum2.FORCE_MATCHING_SIGNATURE)
and sum2.SQL_ID='&sql_id';


spool off

exit;
