-- #############################################################################################################
-- Show SQL Profiles
-- Enhanced: safer SQL*Plus runtime, optional NAME filter, contextual columns
-- #############################################################################################################

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : show_sql_profiles.sql
--           show_sql_profiles.sql MY_PROFILE_NAME
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

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
