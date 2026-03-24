
-- #############################################################################################################
-- FILE: show_sql_baselines_sql_handle.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays SQL Plan Baselines filtered by an input SQL_HANDLE, showing baseline identity, SQL text excerpt, status flags, and verification/execution timestamps to review plans associated with one SQL handle.
--
-- INPUT PARAMETERS:
-- &1 (sql_handle) - STRING - SQL Handle filter value (e.g., 'SQL_46ada9aadcbb946e').
--
-- OUTPUT DESCRIPTION:
-- One result set containing SQL_HANDLE, PLAN_NAME, SQL_TEXT (truncated), ENABLED, ACCEPTED, FIXED, LAST_VERIFIED, and LAST_EXECUTED for baselines matching the provided SQL handle.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL Plan Baselines exist for a specific SQL handle?
-- What plan names are associated with the provided SQL handle?
-- Which baselines for this SQL handle are enabled?
-- Which baselines for this SQL handle are accepted?
-- Which baselines for this SQL handle are fixed?
-- What SQL text is associated with each baseline for this SQL handle?
-- When was each baseline for this SQL handle last verified?
-- When was each baseline for this SQL handle last executed?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : show_sql_baselines_sql_handle.sql SQL_46ada9aadcbb946e
-- #############################################################################################################
--

spool show_sql_baselines_sql_handle.log

set lines 160
set pages 999
col sql_text for a100 trunc
col enabled for a7
col plan_name for a35 trunc
col plan_hash_value for a16 trunc
col last_verified for a16
col last_executed for a16
define sql_handle='&1'
select spb.sql_handle, spb.plan_name, 
dbms_lob.substr(sql_text,3999,1) sql_text,
spb.enabled, spb.accepted, spb.fixed,
to_char(spb.last_verified,'dd-mon-yy HH24:MI') last_verified,
to_char(spb.last_executed,'dd-mon-yy HH24:MI') last_executed
from
dba_sql_plan_baselines spb, sqlobj$ so
where spb.signature = so.signature
and spb.plan_name = so.name
and spb.sql_handle like nvl('&sql_handle',spb.sql_handle);

spool off
exit;
