-- Restore statistics for a table (and columns and indexes associated) within a schema to a certain date , format : DD/MM/YYYY-HH24-MI-SS
-- 
-- ownname := &&1
-- tabname := &&2
-- old_date := &&3
-- execute dbms_stats.restore_table_stats(ownname,tabname,to_date(old_date,'DD/MM/YYYY-HH24-MI-SS'))
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : restore_table_stats.sql SYS MYTAB1 06/02/2025-17-10-32
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


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