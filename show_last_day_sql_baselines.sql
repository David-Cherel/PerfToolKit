-- #############################################################################################################
-- FILE: show_last_day_sql_baselines.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays SQL Plan Baselines created during the last day, including SQL handle, plan name, SQL text, status flags, and verification/execution timestamps.
--
-- INPUT PARAMETERS:
-- None - N/A - This script does not require SQL*Plus substitution parameters.
--
-- OUTPUT DESCRIPTION:
-- One result set listing recently created baselines (last 24h) with SQL text snippet, ENABLED/ACCEPTED/FIXED flags, last verified time, and last executed time.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL baselines were created in the last 24 hours?
-- What status flags (enabled/accepted/fixed) do recent baselines have?
-- When were recent baselines last verified or executed?
-- Which SQL text is associated with each newly created baseline?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : show_last_day_sql_baselines.sql
-- #############################################################################################################
--
set lines 160
set pages 999
col sql_text for a100 trunc
col plan_name for a35 trunc
col enabled for a7
col plan_hash_value for a16 trunc
col last_verified for a16
col last_executed for a16
select spb.sql_handle, spb.plan_name, 
dbms_lob.substr(sql_text,3999,1) sql_text,
spb.enabled, spb.accepted, spb.fixed,
to_char(spb.last_verified,'dd-mon-yy HH24:MI') last_verified,
to_char(spb.last_executed,'dd-mon-yy HH24:MI') last_executed
from
dba_sql_plan_baselines spb, sqlobj$ so
where spb.signature = so.signature
and spb.plan_name = so.name
and spb.created > sysdate-(1);

exit;

