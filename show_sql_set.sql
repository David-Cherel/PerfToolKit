-- ################################################################################################
-- Display the list of SQL Sets in you Database 
-- ################################################################################################
--
--
-- 

alter session set nls_date_format='DD/MM/YYYY HH24:MI:SS';


set verify off
set serveroutput on
set lines 180

col NAME format a35
col OWNER format a25
col DESCRIPTION format a70

select NAME, OWNER, DESCRIPTION, LAST_MODIFIED from DBA_SQLSET;



exit;


