-- #############################################################################################################
-- FILE: show_sql_profiles.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Generates a read-only SQL Profiles report from DBA_SQL_PROFILES with optional profile name filtering, detailed profile attributes, and a count summary, while spooling output to show_sql_profiles.log.
--
-- INPUT PARAMETERS:
-- &1 (profile_name) - STRING - Optional SQL Profile name filter; when null/empty, all SQL Profiles are displayed.
--
-- OUTPUT DESCRIPTION:
-- Two result sets: (1) detailed SQL Profile list with metadata and SQL text, ordered by last modification date; (2) PROFILE_COUNT summary for the selected filter. Output is also spooled.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which SQL Profiles currently exist in the database?
-- What category and status does each SQL Profile have?
-- Is force matching enabled for each SQL Profile?
-- What signature is associated with each SQL Profile?
-- What SQL text is associated with each SQL Profile?
-- When was each SQL Profile created?
-- When was each SQL Profile last modified?
-- How many SQL Profiles match a specific profile name?
-- What is the total number of SQL Profiles currently present?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : show_sql_profiles.sql PROFILE_SQLID_CM1FYT76DWBKB
-- #############################################################################################################
--

set pages 9999
set lines 220
set long 1000000
set longchunksize 32767
set trimspool on
set verify off
set feedback on
set tab off
set termout on

whenever sqlerror exit failure rollback

define profile_name ='&1'

spool show_sql_profiles.log

prompt
prompt =====================================================================================================
prompt SQL Profiles report (PROFILE_NAME filter=&&profile_name)
prompt =====================================================================================================
prompt NOTE: Read-only report. No data change is performed.

column name          format a40
column category      format a18
column status        format a10
column created       format a19
column last_modified format a19
column description   format a60 word_wrapped

select name,
       category,
       status,
       to_char(created,'yyyy-mm-dd hh24:mi:ss') created,
       to_char(last_modified,'yyyy-mm-dd hh24:mi:ss') last_modified,
       force_matching,
       type,
       signature,
       sql_text
from   dba_sql_profiles
where  nullif('&&profile_name','') is null
   or  name = '&&profile_name'
order  by last_modified desc nulls last, created desc, name;

prompt
prompt --- Count summary ---

select count(*) as profile_count
from   dba_sql_profiles
where  nullif('&&profile_name','') is null
   or  name = '&&profile_name';

spool off

exit;
