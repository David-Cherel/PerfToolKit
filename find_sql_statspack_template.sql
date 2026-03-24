-- #############################################################################################################
-- FILE: find_sql_statspack_template.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Searches Statspack SQL text for a provided text extract and returns matching SQL_ID, plan hash value, and signature details to identify related historical statements.
--
-- INPUT PARAMETERS:
-- &1 (mysqltext) - STRING - SQL text extract used for Statspack search pattern (e.g., 'from orders where customer_id').
--
-- OUTPUT DESCRIPTION:
-- One result set of matching Statspack SQL entries with INSTANCE_NUMBER, SQL_TEXT, SQL_ID, PLAN_HASH_VALUE, EXACT_MATCHING_SIGNATURE, and FORCE_MATCHING_SIGNATURE.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which Statspack SQL statements contain a given SQL text extract?
-- What SQL_ID and plan hash values are associated with matched Statspack SQL text?
-- What exact/force matching signatures are associated with matched SQL entries?
-- On which instances were matched SQL statements observed?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : find_sql_statspack_template.sql "from orders where customer_id"
-- #############################################################################################################
--
set lines 180
col INSTANCE_NUMBER for 99999
col exact_matching_signature format 999999999999999999999999 
col force_matching_signature format 999999999999999999999999 

select /* PTK */ distinct sqpu.INSTANCE_NUMBER,sqltext.SQL_TEXT,  sqpu.sql_id, sqpu.plan_hash_value, summary.EXACT_MATCHING_SIGNATURE , 
summary.FORCE_MATCHING_SIGNATURE 
from stats$sql_plan_usage sqpu,  STATS$SQLTEXT sqltext, STATS$SQL_SUMMARY summary
where sqpu.SQL_ID=sqltext.SQL_ID
and summary.SQL_ID=sqpu.SQL_ID
and upper(sqltext.SQL_TEXT) like upper('%'||'&mysqltext'||'%')
and sqltext.SQL_TEXT not like '%/* PTK */%';

exit;


