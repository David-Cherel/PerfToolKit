-- #############################################################################################################
-- FILE: unlock_table_stats.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Unlocks optimizer statistics for a specified table using DBMS_STATS.UNLOCK_TABLE_STATS and verifies lock status from DBA_TAB_STATISTICS.
--
-- INPUT PARAMETERS:
-- &1 (ownname) - STRING - Table owner/schema name (e.g., 'SYS').
-- &2 (tabname) - STRING - Table name whose stats must be unlocked (e.g., 'MYTAB1').
--
-- OUTPUT DESCRIPTION:
-- Executes table stats unlock operation and prints verification query showing owner, table name, and lock status (LOCKED/UNLOCKED).
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I unlock optimizer statistics for a specific table?
-- Is the target table statistics lock status currently LOCKED or UNLOCKED?
-- Did DBMS_STATS.UNLOCK_TABLE_STATS execute successfully for the requested table?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : unlock_table_stats.sql SYS MYTAB1
-- #############################################################################################################
--
set echo off feed off
set serveroutput on size 1000000
set sqlblanklines on


define ownname ='&1'
define tabname ='&2'



set lines 200
set long 99999
SET longchunksize 99999


exec  dbms_output.put_line('==========================================================================================');
exec  dbms_output.put_line('  UnLocking Table Statistic on '||'&tabname');
exec  dbms_output.put_line('==========================================================================================');


execute dbms_stats.unlock_table_stats(upper('&ownname'),upper('&tabname'));

exec  dbms_output.put_line('==========================================================================================');
exec  dbms_output.put_line('  Verifying UnLocking Table Statistic on '||'&tabname');
exec  dbms_output.put_line('==========================================================================================');


col owner format a35
col table_name format a35
col LOCK_STATUS format a12
select  owner, table_name, 
case STATTYPE_LOCKED 
when 'ALL' then 'LOCKED'
else 'UNLOCKED'
END LOCK_STATUS
from dba_tab_statistics where table_name=upper('&tabname') and owner=upper('&ownname'); 

exit;