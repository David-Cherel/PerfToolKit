-- #############################################################################################################
-- FILE: restore_table_stats.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Restores table statistics (including related column/index stats) to a specified historical timestamp using DBMS_STATS.RESTORE_TABLE_STATS.
--
-- INPUT PARAMETERS:
-- &1 (ownname) - STRING - Table owner/schema name (e.g., 'SYS').
-- &2 (tabname) - STRING - Table name whose stats must be restored (e.g., 'MYTAB1').
-- &3 (old_date) - STRING - Restore timestamp in format DD/MM/YYYY-HH24-MI-SS (e.g., '06/02/2025-17-10-32').
--
-- OUTPUT DESCRIPTION:
-- Executes DBMS_STATS.RESTORE_TABLE_STATS for the specified table and date and prints DBMS_OUTPUT progress banners.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I roll back table statistics to a known historical timestamp?
-- Can I restore table, column, and index stats in one operation?
-- Which owner/table and restore date are used for stats rollback?
-- Did the restore operation execute successfully?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : restore_table_stats.sql SYS MYTAB1 06/02/2025-17-10-32
-- #############################################################################################################
--
set echo off feed off
set serveroutput on size 1000000
set sqlblanklines on


define ownname ='&1'
define tabname ='&2'
define old_date ='&3'


set lines 200
set long 99999
SET longchunksize 99999


exec  dbms_output.put_line('==========================================================================================');
--exec  dbms_output.put_line('  Restore Table Statistics (with index and columns statistics) to this date : '||&old_date);
exec  dbms_output.put_line('==========================================================================================');


execute dbms_stats.restore_table_stats(upper('&ownname'),upper('&tabname'),to_date('&old_date','DD/MM/YYYY-HH24-MI-SS'));



exit;