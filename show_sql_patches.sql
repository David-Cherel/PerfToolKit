-- #############################################################################################################
-- FILE: show_sql_patches.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays SQL Patch definitions from DBA_SQL_PATCHES, including patch name, SQL text, status, creation time, and last modification time, and writes execution output to show_sql_patches.log.
--
-- INPUT PARAMETERS:
-- None - N/A - This script does not require SQL*Plus substitution parameters.
--
-- OUTPUT DESCRIPTION:
-- One result set listing SQL patch metadata: NAME, SQL_TEXT, STATUS, CREATED, and LAST_MODIFIED; output is also spooled to show_sql_patches.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL patches currently exist in the database?
-- What SQL text is associated with each SQL patch?
-- What is the current status of each SQL patch?
-- When was each SQL patch created?
-- When was each SQL patch last modified?
-- Which SQL patches were modified recently?
-- Are there inactive SQL patches that may need review?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : show_sql_patches.sql
-- #############################################################################################################
--

set lines 160
col sql_text for a50
col created for a28
col last_modified for a16

spool show_sql_patches.log 

select sqp.name,
dbms_lob.substr(sql_text,3999,1) sql_text,
sqp.status,
to_char(sqp.created,'dd-mon-yy HH24:MI') created,
to_char(sqp.last_modified,'dd-mon-yy HH24:MI') last_modified
from dba_sql_patches sqp;

spool off
exit;

