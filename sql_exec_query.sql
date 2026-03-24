-- #############################################################################################################
-- FILE: sql_exec_query.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Enables execution statistics at session level, runs a sample query, and displays last cursor execution plan with allstats/note information for quick execution-plan diagnostics.
--
-- INPUT PARAMETERS:
-- None - N/A - This script does not require SQL*Plus substitution parameters.
--
-- OUTPUT DESCRIPTION:
-- Spools execution output to sql_exec_query.log, including sample query results and DBMS_XPLAN.DISPLAY_CURSOR output with ALLSTATS +NOTE format.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I enable row-source execution statistics for my session?
-- What execution plan statistics are available for the last executed cursor?
-- Can I quickly verify allstats/note output for a test query?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : sql_exec_query.sql
-- #############################################################################################################
--

set lines 160
set pages 999
spool sql_exec_query.log
alter session set statistics_level=all;
alter session set "_rowsource_execution_statistics"=true; 
select table_name from dba_tables where table_name like 'WC_PERSON%';
SELECT * FROM table(dbms_xplan.display_cursor (format=>'allstats +note' ));
spool off
exit
