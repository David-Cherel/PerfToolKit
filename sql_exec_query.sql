- #############################################################################################################
-- FILE: sql_exec_query.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Executes an input SQL statement with runtime row-source statistics enabled, then displays the last cursor execution plan with ALLSTATS/OUTLINE/PREDICATE/NOTE/ADAPTIVE sections to support immediate execution-plan diagnostics from one script run.
--
-- INPUT PARAMETERS:
-- &1 (sql_text) - STRING - SQL statement to execute (single SQL statement ending with semicolon), for example:
--                  'select /*+ gather_plan_statistics */ count(*) from dba_objects;'
--
-- OUTPUT DESCRIPTION:
-- Two outputs:
-- 1) Execution of the provided SQL statement in the current SQL*Plus session.
-- 2) DBMS_XPLAN.DISPLAY_CURSOR report for the last executed cursor, including runtime row-source statistics,
--    outline hints, predicates, notes, and adaptive plan details.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- What is the actual execution plan used by my input SQL statement?
-- What are the runtime row counts (A-Rows) versus estimated rows in the plan?
-- Which plan operations consume most resources during execution?
-- Are adaptive plan branches visible for this execution?
-- Which predicates are applied at each operation?
-- What outline hints were used by the optimizer for this execution?
-- Are there plan notes indicating dynamic statistics or feedback usage?
-- Is the chosen plan suitable for this SQL statement as executed now?
-- Can I quickly capture execution evidence before deeper diagnosis?
-- Which operation indicates potential cardinality misestimation risk?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : sql_exec_query.sql "select /*+ gather_plan_statistics */ count(*) from dba_objects;"
-- #############################################################################################################


spool sql_exec_query.log

set lines 160
set pages 999
alter session set statistics_level=all;
alter session set "_rowsource_execution_statistics"=true;

&1;

SELECT *
  FROM table(dbms_xplan.display_cursor(format => 'ALLSTATS LAST ALL +OUTLINE +PREDICATE +NOTE +ADAPTIVE'));

spool off
exit

-