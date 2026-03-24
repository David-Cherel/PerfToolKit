-- #############################################################################################################
-- FILE: create_statspack_snapshot.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Creates a Statspack snapshot using PERFSTAT.STATSPACK.SNAP to persist current performance statistics, helping preserve workload evidence and SQL execution context for later Statspack-based analysis.
--
-- INPUT PARAMETERS:
-- None - N/A - This script does not require SQL*Plus substitution parameters.
--
-- OUTPUT DESCRIPTION:
-- Executes Statspack snapshot creation and returns SQL*Plus execution status (success or Oracle error message).
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I manually create a Statspack snapshot now?
-- How can I persist current performance metrics into Statspack?
-- How can I capture workload evidence before cache objects age out?
-- Can I trigger an immediate Statspack snapshot before a change?
-- Did the Statspack snapshot command execute successfully?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : create_statspack_snapshot.sql
-- #############################################################################################################
--

EXEC PERFSTAT.statspack.snap;
exit;