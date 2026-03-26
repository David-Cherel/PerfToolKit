-- #############################################################################################################
-- FILE: mcp_smoke_test.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Executes a minimal Oracle query to validate MCP-driven SQL execution flow, confirming database connectivity, statement execution, and result retrieval using a simple DUAL-based select statement without input parameters.
--
-- INPUT PARAMETERS:
-- None - N/A - This script does not require SQL*Plus substitution parameters.
--
-- OUTPUT DESCRIPTION:
-- One result set with two columns: CURRENT_USER from USERENV context and CURRENT_TS from SYSTIMESTAMP, confirming successful execution and database response formatting.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Can the MCP SQL execution server connect to the Oracle database?
-- Can the MCP SQL execution server run a simple SELECT statement?
-- Does the execution output include rows and column metadata?
-- Is the current Oracle user visible from the MCP execution context?
-- Is Oracle returning a valid current timestamp from this session?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : mcp_smoke_test.sql
-- #############################################################################################################

select
  sys_context('USERENV','SESSION_USER') as current_user,
  to_char(systimestamp, 'YYYY-MM-DD HH24:MI:SS.FF3 TZH:TZM') as current_ts
from dual;
