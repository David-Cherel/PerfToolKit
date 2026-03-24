-- #############################################################################################################
-- FILE: show_sql_baselines_sql_plan.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays SQL Plan Baselines filtered by an input PLAN_NAME, returning baseline identifiers, SQL text excerpt, status flags, and verification/execution timestamps to inspect one specific baseline plan or matching plan name pattern.
--
-- INPUT PARAMETERS:
-- &1 (plan_name) - STRING - SQL Plan Baseline plan name filter (e.g., 'SQLID_cm1fyt76dwbkb_2481688974').
--
-- OUTPUT DESCRIPTION:
-- One result set containing SQL_HANDLE, PLAN_NAME, SQL_TEXT (truncated), ENABLED, ACCEPTED, FIXED, LAST_VERIFIED, and LAST_EXECUTED for baselines matching the provided plan name.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL Plan Baseline entries match a given plan name?
-- What SQL handle is associated with the provided plan name?
-- Is the matching baseline enabled?
-- Is the matching baseline accepted?
-- Is the matching baseline fixed?
-- What SQL text corresponds to the matching baseline?
-- When was the matching baseline last verified?
-- When was the matching baseline last executed?
-- Are there multiple baseline entries matching the provided plan name pattern?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : show_sql_baselines_sql_plan.sql SQLID_cm1fyt76dwbkb_2481688974
-- #############################################################################################################
--

set lines 160
set pages 999
col sql_text for a100 trunc
col enabled for a7
col plan_hash_value for a16 trunc
col last_verified for a16
col last_executed for a16
col plan_name for a35 trunc
define plan_name='&1'
select spb.sql_handle, spb.plan_name, 
dbms_lob.substr(sql_text,3999,1) sql_text,
spb.enabled, spb.accepted, spb.fixed,
to_char(spb.last_verified,'dd-mon-yy HH24:MI') last_verified,
to_char(spb.last_executed,'dd-mon-yy HH24:MI') last_executed
from
dba_sql_plan_baselines spb, sqlobj$ so
where spb.signature = so.signature
and spb.plan_name = so.name
and spb.plan_name like nvl('&plan_name',spb.plan_name);

exit;

