-- UnLock table statistics 
-- 
-- ownname := &&1
-- tabname := &&2
-- execute dbms_stats.unlock_table_stats(ownname,tabname)
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : unlock_table_stats.sql SYS MYTAB1
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


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