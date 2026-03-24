
-- #############################################################################################################
-- FILE: show_sql_set.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays SQL Tuning Sets available in the database from DBA_SQLSET, including name, owner, description, and last modification date, after setting session NLS date format for readable timestamp output.
--
-- INPUT PARAMETERS:
-- None - N/A - This script does not require SQL*Plus substitution parameters.
--
-- OUTPUT DESCRIPTION:
-- One result set listing SQL tuning set metadata: NAME, OWNER, DESCRIPTION, and LAST_MODIFIED from DBA_SQLSET.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL tuning sets currently exist in the database?
-- Who owns each SQL tuning set?
-- What description is defined for each SQL tuning set?
-- When was each SQL tuning set last modified?
-- Are there SQL tuning sets with missing or generic descriptions?
-- Which SQL tuning sets were modified most recently?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : show_sql_set.sql
-- #############################################################################################################
--

spool show_sql_set.log

alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS';


set verify off
set serveroutput on
set lines 180

col NAME format a35
col OWNER format a25
col DESCRIPTION format a70

select NAME, OWNER, DESCRIPTION, LAST_MODIFIED from DBA_SQLSET;



spool off
exit;
