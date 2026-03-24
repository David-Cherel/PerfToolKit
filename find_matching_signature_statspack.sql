
-- #############################################################################################################
-- FILE: find_matching_signature_statspack.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Finds SQL statements in Statspack snapshots that share exact or force matching signatures with an input SQL_ID by joining STATS$ SQL usage, text, and summary signature information.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID used as reference for signature matching in Statspack data (e.g., 'cm1fyt76dwbkb').
--
-- OUTPUT DESCRIPTION:
-- One result set listing matching Statspack SQL entries with INSTANCE_NUMBER, SQL_TEXT, SQL_ID, PLAN_HASH_VALUE, EXACT_MATCHING_SIGNATURE, and FORCE_MATCHING_SIGNATURE; output spooled to find_matching_signature_statspack.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which Statspack SQL statements share matching signatures with a given SQL_ID?
-- What exact and force matching signatures are associated with matching SQL entries?
-- On which instances were signature-related SQL statements observed?
-- Which plan hash values are linked to signature-related SQL entries in Statspack?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : find_matching_signature_statspack.sql cm1fyt76dwbkb
-- #############################################################################################################
--
spool find_matching_signature_statspack.log

set lines 180
set pages 999
define sql_id ='&1'



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
