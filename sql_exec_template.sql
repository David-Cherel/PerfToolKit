SET LONG 10000000 LONGCHUNKSIZE 10000000 LINESIZE 1000 PAGESIZE 5000

spool sql_exec_query.log
alter session set statistics_level=all;
alter session set "_rowsource_execution_statistics"=true; 

-- votre SQL  --- 


SELECT DBMS_SQLTUNE.report_sql_monitor(session_id=>userenv('SID'), type => 'TEXT',report_level=>'ALL') AS report FROM dual;

spool off

