-- #############################################################################################################
-- Find SQL Query in in Shared Pool (Library Cache) and displays KPI's 
-- Accept an extract of sql_text as inputs (ptompted)
-- Display : inst_id, SQL_ID, CHILD,PLAN_HASH, 	EXECS ,	AVG_ETIME ,	AVG_LIO ,SQL_TEXT
-- Allows to show performance KPI's for that SQL_ID and plan_hash_value 
-- #############################################################################################################

-- Find SQL ID from SQL Test:
-- 
-- SQL> @find_sql
-- Enter value for sql_text: %skew%
-- Enter value for sql_id:
-- SQL_ID 			CHILD 	PLAN_HASH 	EXECS 	AVG_ETIME 	AVG_LIO 		SQL_TEXT
-- ------------- 	------ 	---------- 	------ 	---------- 	------------ 	-------------------------------------------------
-- 0qa98gcnnza7h 	0 		568322376 	5 		13.09 		142,646 		select avg(pk_col) from kso.skew where col1 > 0
-- 0qa98gcnnza7h 	1 		3723858078 	1 		9.80 		2,626,102 		select avg(pk_col) from kso.skew where col1 > 0
-- 
--
--
--

col obsolete format a9
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999

select /* PTK */ inst_id, sql_id, child_number, IS_OBSOLETE, plan_hash_value plan_hash, executions execs,
(elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_etime,
disk_reads/decode(nvl(executions,0),0,1,executions) avg_pio,
buffer_gets/decode(nvl(executions,0),0,1,executions) avg_lio,
cpu_time/decode(nvl(executions,0),0,1,executions) avg_cpu_time,
sql_text from gv$sql s
where upper(sql_text) like upper('%'||'&SQL_TEXT'||'%')
and sql_text not like '%from v$sql s where upper%'
and sql_text not like '%and dbms_lob.substr(txt.sql_text,3999,1) not%'
and sql_text not like '%/* PTK */%'
order by 1, 2, 3;
