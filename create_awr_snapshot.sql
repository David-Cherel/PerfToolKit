
-- #############################################################################################################
-- FILE: create_awr_snapshot.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Creates an AWR snapshot using DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT to persist current performance data into AWR tables, helping preserve workload and execution plan information for later analysis.
--
-- INPUT PARAMETERS:
-- None - N/A - This script does not require SQL*Plus substitution parameters.
--
-- OUTPUT DESCRIPTION:
-- Executes the AWR snapshot creation PL/SQL call and returns SQL*Plus execution status (success or Oracle error message).
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I manually create an AWR snapshot now?
-- How can I persist current workload information into AWR?
-- How can I preserve execution plan evidence before it ages out of cache?
-- Can I trigger an immediate AWR capture before a change?
-- Did the AWR snapshot creation command execute successfully?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : create_awr_snapshot.sql
-- #############################################################################################################
--

spool create_awr_snapshot.log

EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;

spool off
exit;
