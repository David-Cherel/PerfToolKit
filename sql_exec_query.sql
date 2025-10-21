set lines 160
set pages 999
spool sql_exec_query.log
alter session set statistics_level=all;
alter session set "_rowsource_execution_statistics"=true; 
select table_name from dba_tables where table_name like 'WC_PERSON%';
SELECT * FROM table(dbms_xplan.display_cursor (format=>'allstats +note' ));
spool off
exit
