
-- #############################################################################################################
-- FILE: show_sql_baselines_with_SQLID.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays SQL Plan Baselines whose PLAN_NAME follows the SQLID naming pattern (SQLID_% ), showing baseline identifiers, SQL text excerpt, status flags, and last execution timestamp for SQLID-based baseline review.
--
-- INPUT PARAMETERS:
-- None - N/A - This script uses a fixed internal filter (PLAN_NAME like 'SQLID_%').
--
-- OUTPUT DESCRIPTION:
-- One result set containing SQL_HANDLE, PLAN_NAME, SQL_TEXT (truncated), ENABLED, ACCEPTED, FIXED, and LAST_EXECUTED for baselines with plan names matching SQLID_%.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL Plan Baselines have plan names starting with SQLID_?
-- What SQL handles correspond to SQLID-based baseline plan names?
-- Which SQLID-based baselines are enabled?
-- Which SQLID-based baselines are accepted?
-- Which SQLID-based baselines are fixed?
-- What SQL text is associated with each SQLID-based baseline?
-- When was each SQLID-based baseline last executed?
-- How many SQLID-based baseline entries currently exist?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : show_sql_baselines_with_SQLID.sql
-- #############################################################################################################
--

spool show_sql_baselines_with_SQLID.log

set lines 160
col sql_text for a35 trunc
col last_executed for a28
col enabled for a7
col plan_hash_value for a16
col last_executed for a16
select spb.sql_handle, spb.plan_name,
dbms_lob.substr(sql_text,100,1) sql_text,
spb.enabled, spb.accepted, spb.fixed,
to_char(spb.last_executed,'dd-mon-yy HH24:MI') last_executed
from
dba_sql_plan_baselines spb
where spb.plan_name like 'SQLID_%';

spool off
exit;
