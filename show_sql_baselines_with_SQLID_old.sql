-- #############################################################################################################
-- FILE: show_sql_baselines_with_SQLID_old.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays SQL Plan Baseline details for an input PLAN_NAME (legacy variant), including SQL handle, plan id/hash, SQL text, status flags, and verification/execution timestamps.
--
-- INPUT PARAMETERS:
-- &1 (plan_name) - STRING - SQL Plan Baseline plan name filter (e.g., 'SQLID_cm1fyt76dwbkb_2481688974').
--
-- OUTPUT DESCRIPTION:
-- One result set containing SQL_HANDLE, PLAN_NAME, PLAN_HASH_VALUE (from SQLOBJ$ PLAN_ID), SQL_TEXT (truncated), ENABLED, ACCEPTED, FIXED, LAST_VERIFIED, and LAST_EXECUTED.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which baseline entries match a given plan name in this legacy view script?
-- What SQL handle and plan hash/plan id are associated with the input plan name?
-- Is the matching baseline enabled, accepted, or fixed?
-- When was the matching baseline last verified and last executed?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : show_sql_baselines_with_SQLID_old.sql SQLID_cm1fyt76dwbkb_2481688974
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
select spb.sql_handle, spb.plan_name, to_char(so.plan_id) plan_hash_value,
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

