
-- #############################################################################################################
-- FILE: sql_exec_template.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Executes an input SQL statement with execution statistics enabled, then generates a SQL Monitor text report for the current session to provide quick runtime visibility (execution progress, waits, and resource usage) in one template.
--
-- INPUT PARAMETERS:
-- &1 (sql_text) - STRING - SQL statement to execute (single SQL statement ending with semicolon), for example:
--                  'select /*+ monitor */ owner, count(*) from dba_objects group by owner;'
--
-- OUTPUT DESCRIPTION:
-- Two outputs:
-- 1) Execution result of the provided SQL statement.
-- 2) DBMS_SQLTUNE.REPORT_SQL_MONITOR text report (report_level ALL) for the current session,
--    showing monitored execution details such as timing, plan steps, and activity profile.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Can I execute an ad-hoc SQL statement and immediately get a SQL Monitor report?
-- Is SQL Monitoring capturing this execution in the current session?
-- What does the monitored execution timeline look like?
-- Which execution plan steps are the most expensive in monitored output?
-- Are wait events visible in the SQL Monitor report?
-- Is the SQL statement progressing or stalled during execution?
-- Can this template be reused for rapid performance triage?
-- Does this SQL show signs of CPU-bound or I/O-bound behavior in monitor output?
-- Is the monitored execution consistent with expected runtime behavior?
-- Can I capture monitoring evidence without manual multi-step commands?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : sql_exec_template.sql "select /*+ monitor */ owner, count(*) from dba_objects group by owner;"
-- #############################################################################################################


set long 10000000 longchunksize 10000000 linesize 1000 pagesize 5000

spool sql_exec_template.log

alter session set statistics_level=all;
alter session set "_rowsource_execution_statistics"=true;

&1;

select dbms_sqltune.report_sql_monitor(
         session_id   => userenv('SID'),
         type         => 'TEXT',
         report_level => 'ALL'
       ) as report
  from dual;

spool off
