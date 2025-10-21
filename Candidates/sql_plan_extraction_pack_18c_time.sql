!mkdir /home/oracle/sppyw/extraction_SQL
#!mkdir /bugmnt34/em/celclnx33/SR3.31069530671/user/sppyw/extraction_SQL
!mkdir -p /oraaud/sppyw/extraction_SQL

create or replace directory EXTR_SQL as '/home/oracle/sppyw/extraction_SQL';
--create or replace directory EXTR_SQL as '/bugmnt34/em/celclnx33/SR3.31069530671/user/sppyw/extraction_SQL';

drop directory EXTR_SQL;
--create directory EXTR_SQL as '/bugmnt32/em/celclnx33/SR3.30688387261/user/sppyw/extraction_SQL';

CREATE OR REPLACE PACKAGE extract_sql
AS

PROCEDURE extract_SQL_full_total(p_dbid IN NUMBER, p_total_exec_time IN NUMBER, p_min_time IN DATE, p_max_time IN DATE);
PROCEDURE extract_SQL_full_exec(p_dbid IN NUMBER, p_max_exec_time IN NUMBER, p_min_time IN DATE, p_max_time IN DATE);

END extract_sql;
/

CREATE OR REPLACE PACKAGE BODY extract_sql
AS

	CURSOR interval_per_sql_crs(v_dbid NUMBER, v_sql_id VARCHAR2, v_min_time DATE, v_max_time DATE) IS
			select
			  s.begin_interval_time,
				s.end_interval_time,
			  sql.executions_delta,
			  sql.elapsed_time_delta,
			  sql.elapsed_time_delta/GREATEST(1,sql.executions_delta) elapsed_average,
			  sql.disk_reads_delta/GREATEST(1,sql.executions_delta) reads_average,
			  sql.buffer_gets_delta/GREATEST(1,sql.executions_delta) gets_average,
			  sql.cpu_time_delta/GREATEST(1,sql.executions_delta) cpu_average,
			  sql.rows_processed_delta /GREATEST(1,sql.executions_delta) rows_average,
			  sql.plan_hash_value	
			from
			   dba_hist_sqlstat        sql,
			   dba_hist_snapshot         s
			where
			   s.snap_id = sql.snap_id
			   and s.dbid=sql.dbid
			   and s.instance_number=sql.instance_number
				 and s.dbid=v_dbid
			   and sql.sql_id=v_sql_id
 				 and s.begin_interval_time>=v_min_time and s.end_interval_time<=v_max_time			   
			order by begin_interval_time
			;
			
	CURSOR instances_crs(v_dbid NUMBER, v_sql_id VARCHAR2) IS
			select distinct instance_number
			from 
				dba_hist_sqlstat s
			where 
				s.dbid=v_dbid
				and s.sql_id=v_sql_id
			order by instance_number;
	
	CURSOR wait_events_crs(v_dbid NUMBER, v_sql_id VARCHAR2) IS
			select 
			module,
			event,
			sum(time_waited) time_waited,
			count(*) waits
			  from  DBA_HIST_ACTIVE_SESS_HISTORY s
			  where
			  s.dbid = v_dbid
			  AND
			  s.sql_id=v_sql_id
			group by module,event
			order by waits;

	CURSOR sql_text_crs(v_dbid NUMBER, v_sql_id VARCHAR2) IS
			select sql_text
			from dba_hist_sqltext
			where 
			  dbid = v_dbid
			  AND
			  sql_id=v_sql_id;
			  
PROCEDURE extract_SQL_full_total(p_dbid IN NUMBER,p_total_exec_time IN NUMBER, p_min_time IN DATE, p_max_time IN DATE)
AS
	CURSOR sqls_crs(v_dbid NUMBER, v_min_time DATE, v_max_time DATE) IS 
			select
				sql.dbid			,
				sql.con_dbid		,
			  sql.sql_id    ,
			  count(*) occurrences, 
				count(distinct plan_hash_value) execution_plan_versions,
			  sum(executions_delta) total_executions,
			  max(trunc(sql.elapsed_time_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))/1000000) max_execution_time,
				min(trunc(DECODE(sql.elapsed_time_delta,0,10000000,sql.elapsed_time_delta)/DECODE(sql.executions_delta,0,1,sql.executions_delta))/1000000) min_execution_time,
			  trunc(sum(sql.elapsed_time_delta)) total_execution_time, trunc(sum(sql.elapsed_time_delta))/sum(executions_delta) average_execution_time,
				max(trunc(sql.disk_reads_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))) max_reads,
			  trunc(sum(sql.disk_reads_delta)) total_disk_reads, trunc(sum(sql.disk_reads_delta))/sum(executions_delta) average_reads,
				max(trunc(sql.buffer_gets_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))) max_buffer_gets,
			  trunc(sum(sql.buffer_gets_delta)) total_buffer_gets, trunc(sum(sql.buffer_gets_delta))/sum(executions_delta) average_buffer_gets,	
			  max(trunc(sql.cpu_time_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))/1000000) max_cpu_time,
			  trunc(sum(sql.cpu_time_delta)) total_cpu_time, trunc(sum(sql.cpu_time_delta))/sum(executions_delta) average_cpu_time,
				max(trunc(sql.rows_processed_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))) max_rows_processed,
			  trunc(sum(sql.rows_processed_delta)) total_rows_processed, trunc(sum(sql.rows_processed_delta)/sum(executions_delta)) average_rows_processed  
			from
			   dba_hist_sqlstat        sql,
			   dba_hist_snapshot         s
			where
			   s.snap_id = sql.snap_id
			   and s.dbid=sql.dbid
			   and s.instance_number=sql.instance_number
			   and s.dbid=v_dbid
			 	 and s.begin_interval_time>=v_min_time and s.end_interval_time<=v_max_time
			group by sql.dbid,sql.con_dbid,sql.sql_id
			having sum(executions_delta)>0 and trunc(sum(sql.elapsed_time_delta)/1000000)>=p_total_exec_time
			order by 
						trunc(sum(sql.elapsed_time_delta)/1000000)
			DESC
			;
			
-- Procedure Variables		
	v_found_it BOOLEAN;
	v_cursor_no_plan BOOLEAN;
	v_exec_plan_lines NUMBER;
	v_db_name DBA_HIST_DATABASE_INSTANCE.DB_NAME%TYPE;
	v_instance_list VARCHAR2(100);

-- File Handlers:
  fHandle  UTL_FILE.FILE_TYPE;
	
BEGIN
	SELECT DISTINCT DB_NAME into v_db_name FROM DBA_HIST_DATABASE_INSTANCE WHERE dbid=p_dbid;
--	v_db_name:='CDSSPPOC';
  fHandle := UTL_FILE.FOPEN('EXTR_SQL', 'output_SQL_'||v_db_name||'_full.txt', 'w',32767);
	UTL_FILE.PUT_LINE(fHandle,'SQL report for Database '||v_db_name||' by total time.');
	UTL_FILE.PUT_LINE(fHandle,'Includes:');
	UTL_FILE.PUT_LINE(fHandle,'+ SQLs with total execution time superior to '||TO_CHAR(p_total_exec_time)||' seconds;');
	UTL_FILE.PUT_LINE(fHandle,LPAD('-',90,'-'));
	UTL_FILE.PUT_LINE(fHandle,'!!!Please note that the SQLs without a plan in AWR are very likely to be PLSQL executions!!!');
	UTL_FILE.PUT_LINE(fHandle,LPAD('-',90,'-')||chr(10));

	FOR sqls_rec IN sqls_crs(p_dbid, p_min_time, p_max_time) LOOP
		BEGIN
			UTL_FILE.PUT_LINE(fHandle,'------ Begin '||sqls_rec.sql_id||' ------');
			UTL_FILE.PUT_LINE(fHandle,'-----------------------------------------');
			v_exec_plan_lines:=0;
			FOR sql_plan_rec IN (select plan_table_output from table(DBMS_XPLAN.DISPLAY_WORKLOAD_REPOSITORY(sql_id=>sqls_rec.sql_id,dbid=>sqls_rec.dbid,con_dbid=>sqls_rec.con_dbid))) LOOP
				UTL_FILE.PUT_LINE(fHandle,sql_plan_rec.plan_table_output,true);
				v_exec_plan_lines:=v_exec_plan_lines+1;
			END LOOP;
			IF v_exec_plan_lines = 0 THEN
				UTL_FILE.PUT_LINE(fHandle,'Execution plan not found in AWR!');
				FOR sql_text_rec IN sql_text_crs(p_dbid,sqls_rec.sql_id) LOOP
					<<write_to_file>>
					BEGIN
						UTL_FILE.PUT_LINE(fHandle,sql_text_rec.sql_text,true);	
					EXCEPTION
						WHEN OTHERS THEN NULL;
					END write_to_file;
				END LOOP;
			END IF;		
			UTL_FILE.PUT_LINE(fHandle,chr(10)||'Execution intervals:');
			
			FOR interval_per_sql_rec IN interval_per_sql_crs(p_dbid,sqls_rec.sql_id,p_min_time,p_max_time) LOOP
				--Execution Time: 0. Buffer Gets: 0. Disk reads: 0. CPU Time: 0. Processed Rows: 0
				IF interval_per_sql_rec.elapsed_average>0 OR interval_per_sql_rec.gets_average>0 OR interval_per_sql_rec.reads_average>0 OR interval_per_sql_rec.cpu_average>0 THEN
					UTL_FILE.PUT_LINE(fHandle,'Interval: '||TO_CHAR(interval_per_sql_rec.begin_interval_time,'DD.MM.YYYY HH24:MI:SS')||'-'||TO_CHAR(interval_per_sql_rec.end_interval_time,'DD.MM.YYYY HH24:MI:SS')||' Executions: '||TO_CHAR(interval_per_sql_rec.executions_delta)||' Total Execution Time: '||TO_CHAR(interval_per_sql_rec.elapsed_time_delta/1000000)||' s. Plan Hash Value: '|| TO_CHAR(interval_per_sql_rec.plan_hash_value)||'. AVERAGES: Execution Time: '|| TO_CHAR(TRUNC(interval_per_sql_rec.elapsed_average/1000000,4))||'. Buffer Gets: '||TO_CHAR(TRUNC(interval_per_sql_rec.gets_average,0))||'. Disk reads: '|| TO_CHAR(TRUNC(interval_per_sql_rec.reads_average,0))||'. CPU Time: '|| TO_CHAR(TRUNC(interval_per_sql_rec.cpu_average/1000000,4))||'. Processed Rows: '||TO_CHAR(TRUNC(interval_per_sql_rec.rows_average,2)),true);
				END IF;
			END LOOP;
			UTL_FILE.PUT_LINE(fHandle,'-----------------------------------------');
			
			v_instance_list:='Instances:';
			FOR instances_rec IN instances_crs(p_dbid,sqls_rec.sql_id) LOOP
				IF v_instance_list='Instances:' THEN
					v_instance_list:=v_instance_list||instances_rec.instance_number;
				ELSE
					v_instance_list:=v_instance_list||','||instances_rec.instance_number;
				END IF;
			END LOOP;
			UTL_FILE.PUT_LINE(fHandle,chr(10)||v_instance_list);

			UTL_FILE.PUT_LINE(fHandle,chr(10)||'Minimum Execution Time/Execution:'||TO_CHAR(sqls_rec.min_execution_time)||' s.');
			UTL_FILE.PUT_LINE(fHandle,'Maximum Execution Time/Execution:'||TO_CHAR(sqls_rec.max_execution_time)||' s.');
			UTL_FILE.PUT_LINE(fHandle,'Total Executions:'||sqls_rec.total_executions);
			UTL_FILE.PUT_LINE(fHandle,'Total Execution Time:'||TO_CHAR(TRUNC(sqls_rec.total_execution_time)/1000000)||' s.');
			UTL_FILE.PUT_LINE(fHandle,'Execution Plan Versions:'||TO_CHAR(sqls_rec.execution_plan_versions));
			UTL_FILE.PUT_LINE(fHandle,'Found in:'||TO_CHAR(sqls_rec.occurrences)||' AWR reports.');
			UTL_FILE.PUT_LINE(fHandle,chr(10)||'Modules/Waits ');
			UTL_FILE.PUT_LINE(fHandle,'-----------------------------------------');
			FOR wait_events_rec IN wait_events_crs(p_dbid,sqls_rec.sql_id) LOOP
				UTL_FILE.PUT_LINE(fHandle,'Modules/Waits: '||wait_events_rec.module||'; Wait Event:'||NVL(wait_events_rec.event,'No wait')||'; Waits:'||wait_events_rec.waits||'; Time Waited:'||TO_CHAR(TRUNC(wait_events_rec.time_waited/1000000))||'.',true);
			END LOOP;
		
			UTL_FILE.PUT_LINE(fHandle,'------ End '||sqls_rec.sql_id||' ------'||chr(10));
		EXCEPTION
			WHEN OTHERS THEN
				UTL_FILE.PUT_LINE(fHandle,DBMS_UTILITY.format_error_stack);
		END;			
	END LOOP;
  UTL_FILE.FCLOSE(fHandle);
END extract_SQL_full_total;



PROCEDURE extract_SQL_full_exec(p_dbid IN NUMBER,p_max_exec_time IN NUMBER, p_min_time IN DATE, p_max_time IN DATE)
AS
	CURSOR sqls_crs(v_dbid NUMBER, v_min_time DATE, v_max_time DATE) IS 
			select
				sql.dbid			,
				sql.con_dbid		,
			  sql.sql_id    ,
			  count(*) occurrences, 
				count(distinct plan_hash_value) execution_plan_versions,
			  sum(executions_delta) total_executions,
			  min(trunc(DECODE(sql.elapsed_time_delta,0,1000000,sql.elapsed_time_delta)/DECODE(sql.executions_delta,0,1,sql.executions_delta))/1000000) min_execution_time,
			  max(trunc(sql.elapsed_time_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))/1000000) max_execution_time,
			  trunc(sum(sql.elapsed_time_delta)) total_execution_time, trunc(sum(sql.elapsed_time_delta))/sum(executions_delta) average_execution_time,
				max(trunc(sql.disk_reads_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))) max_reads,
			  trunc(sum(sql.disk_reads_delta)) total_disk_reads, trunc(sum(sql.disk_reads_delta))/sum(executions_delta) average_reads,
				max(trunc(sql.buffer_gets_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))) max_buffer_gets,
			  trunc(sum(sql.buffer_gets_delta)) total_buffer_gets, trunc(sum(sql.buffer_gets_delta))/sum(executions_delta) average_buffer_gets,	
			  max(trunc(sql.cpu_time_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))/1000000) max_cpu_time,
			  trunc(sum(sql.cpu_time_delta)) total_cpu_time, trunc(sum(sql.cpu_time_delta))/sum(executions_delta) average_cpu_time,
				max(trunc(sql.rows_processed_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))) max_rows_processed,
			  trunc(sum(sql.rows_processed_delta)) total_rows_processed, trunc(sum(sql.rows_processed_delta)/sum(executions_delta)) average_rows_processed  
			from
			   dba_hist_sqlstat        sql,
			   dba_hist_snapshot         s
			where
			   s.snap_id = sql.snap_id
			   and s.dbid=sql.dbid
			   and s.instance_number=sql.instance_number
			   and s.dbid=v_dbid
				 and s.begin_interval_time>=v_min_time and s.end_interval_time<=v_max_time
			group by sql.dbid,sql.con_dbid,sql.sql_id
			having sum(executions_delta)>0 and max(trunc(sql.elapsed_time_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))/1000000)>=p_max_exec_time
			order by 
						max(trunc(sql.elapsed_time_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta))/1000000)
			DESC
			;
			
-- Procedure Variables		
	v_found_it BOOLEAN;
	v_cursor_no_plan BOOLEAN;
	v_exec_plan_lines NUMBER;
	v_db_name DBA_HIST_DATABASE_INSTANCE.DB_NAME%TYPE;
	v_instance_list VARCHAR2(20);

-- File Handlers:
  fHandle  UTL_FILE.FILE_TYPE;
	 
BEGIN
	SELECT DISTINCT DB_NAME into v_db_name FROM DBA_HIST_DATABASE_INSTANCE WHERE dbid=p_dbid;
--	v_db_name:='CDSSPPOC';
	fHandle := UTL_FILE.FOPEN('EXTR_SQL', 'output_SQL_'||v_db_name||'_exec.txt', 'w',32767);
	UTL_FILE.PUT_LINE(fHandle,'SQL report for Database '||v_db_name||' by individual maximum time.');
	UTL_FILE.PUT_LINE(fHandle,'Includes:');
	UTL_FILE.PUT_LINE(fHandle,'+ SQLs with maximum execution time/execution superior to '||TO_CHAR(p_max_exec_time)||' seconds;');
	UTL_FILE.PUT_LINE(fHandle,LPAD('-',90,'-'));
	UTL_FILE.PUT_LINE(fHandle,'!!!Please note that the SQLs without a plan in AWR are very likely to be PLSQL executions!!!');
	UTL_FILE.PUT_LINE(fHandle,LPAD('-',90,'-')||chr(10));

	FOR sqls_rec IN sqls_crs(p_dbid,p_min_time,p_max_time) LOOP
			BEGIN
				UTL_FILE.PUT_LINE(fHandle,'------ Begin '||sqls_rec.sql_id||' ------');
				UTL_FILE.PUT_LINE(fHandle,'-----------------------------------------');
				v_exec_plan_lines:=0;
				FOR sql_plan_rec IN (select plan_table_output from table(DBMS_XPLAN.DISPLAY_WORKLOAD_REPOSITORY(sql_id=>sqls_rec.sql_id,dbid=>sqls_rec.dbid,con_dbid=>sqls_rec.con_dbid))) LOOP
					UTL_FILE.PUT_LINE(fHandle,sql_plan_rec.plan_table_output,true);
					v_exec_plan_lines:=v_exec_plan_lines+1;
				END LOOP;
				IF v_exec_plan_lines = 0 THEN
					UTL_FILE.PUT_LINE(fHandle,'Execution plan not found in AWR!');
					FOR sql_text_rec IN sql_text_crs(p_dbid,sqls_rec.sql_id) LOOP
						<<write_to_file>>
						BEGIN
							UTL_FILE.PUT_LINE(fHandle,sql_text_rec.sql_text,true);	
						EXCEPTION
							WHEN OTHERS THEN NULL;
						END write_to_file;
					END LOOP;				
				END IF;		
				UTL_FILE.PUT_LINE(fHandle,chr(10)||'Execution intervals:');
				
				FOR interval_per_sql_rec IN interval_per_sql_crs(p_dbid,sqls_rec.sql_id,p_min_time,p_max_time) LOOP
					IF interval_per_sql_rec.elapsed_average>0 OR interval_per_sql_rec.gets_average>0 OR interval_per_sql_rec.reads_average>0 OR interval_per_sql_rec.cpu_average>0 THEN 
						UTL_FILE.PUT_LINE(fHandle,'Interval: '||TO_CHAR(interval_per_sql_rec.begin_interval_time,'DD.MM.YYYY HH24:MI:SS')||'-'||TO_CHAR(interval_per_sql_rec.end_interval_time,'DD.MM.YYYY HH24:MI:SS')||' Executions: '||TO_CHAR(interval_per_sql_rec.executions_delta)||' Total Execution Time: '||TO_CHAR(interval_per_sql_rec.elapsed_time_delta/1000000)||' s. Plan Hash Value: '|| TO_CHAR(interval_per_sql_rec.plan_hash_value)||'. AVERAGES: Execution Time: '|| TO_CHAR(TRUNC(interval_per_sql_rec.elapsed_average/1000000,4))||'. Buffer Gets: '||TO_CHAR(TRUNC(interval_per_sql_rec.gets_average,0))||'. Disk reads: '|| TO_CHAR(TRUNC(interval_per_sql_rec.reads_average,0))||'. CPU Time: '|| TO_CHAR(TRUNC(interval_per_sql_rec.cpu_average/1000000,4))||'. Processed Rows: '||TO_CHAR(TRUNC(interval_per_sql_rec.rows_average,2)),true);
					END IF;
				END LOOP;
				UTL_FILE.PUT_LINE(fHandle,'-----------------------------------------');
				
				v_instance_list:='Instances:';
				FOR instances_rec IN instances_crs(p_dbid,sqls_rec.sql_id) LOOP
					IF v_instance_list='Instances:' THEN
						v_instance_list:=v_instance_list||instances_rec.instance_number;
					ELSE
						v_instance_list:=v_instance_list||','||instances_rec.instance_number;
					END IF;
				END LOOP;
				UTL_FILE.PUT_LINE(fHandle,chr(10)||v_instance_list);

				UTL_FILE.PUT_LINE(fHandle,chr(10)||'Minimum Execution Time/Execution:'||TO_CHAR(sqls_rec.min_execution_time)||' s.');
				UTL_FILE.PUT_LINE(fHandle,'Maximum Execution Time/Execution:'||TO_CHAR(sqls_rec.max_execution_time)||' s.');
				UTL_FILE.PUT_LINE(fHandle,'Total Executions:'||sqls_rec.total_executions);
				UTL_FILE.PUT_LINE(fHandle,'Total Execution Time:'||TO_CHAR(TRUNC(sqls_rec.total_execution_time)/1000000)||' s.');
				UTL_FILE.PUT_LINE(fHandle,'Execution Plan Versions:'||TO_CHAR(sqls_rec.execution_plan_versions));
				UTL_FILE.PUT_LINE(fHandle,'Found in:'||TO_CHAR(sqls_rec.occurrences)||' AWR reports.');
				UTL_FILE.PUT_LINE(fHandle,chr(10)||'Modules/Waits ');
				UTL_FILE.PUT_LINE(fHandle,'-----------------------------------------');
				FOR wait_events_rec IN wait_events_crs(p_dbid,sqls_rec.sql_id) LOOP
					UTL_FILE.PUT_LINE(fHandle,'Modules/Waits: '||wait_events_rec.module||'; Wait Event:'||NVL(wait_events_rec.event,'No wait')||'; Waits:'||wait_events_rec.waits||'; Time Waited:'||TO_CHAR(TRUNC(wait_events_rec.time_waited/1000000))||'.',true);
				END LOOP;
			
				UTL_FILE.PUT_LINE(fHandle,'------ End '||sqls_rec.sql_id||' ------'||chr(10));
			EXCEPTION
				WHEN OTHERS THEN
					UTL_FILE.PUT_LINE(fHandle,DBMS_UTILITY.format_error_stack);
			END;
	END LOOP;
  UTL_FILE.FCLOSE(fHandle);
END extract_SQL_full_exec;

END extract_sql;
/

BEGIN
	extract_sql.extract_SQL_full_total(2757464810,p_total_exec_time=>10,p_min_time=>to_date('11.11.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'), p_max_time=>to_date('13.11.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'));
	extract_sql.extract_SQL_full_exec(2757464810,p_max_exec_time=>1, p_min_time=>to_date('11.11.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'), p_max_time=>to_date('13.11.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'));
END;
/


BEGIN
	extract_sql.extract_SQL_full_total(3376684672,p_total_exec_time=>10,p_min_time=>to_date('02.06.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'), p_max_time=>to_date('13.06.2024 03:00:00','dd.mm.yyyy hh24:mi:ss'));
	extract_sql.extract_SQL_full_exec(3376684672,p_max_exec_time=>10, p_min_time=>to_date('02.06.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'), p_max_time=>to_date('13.06.2024 03:00:00','dd.mm.yyyy hh24:mi:ss'));
END;
/

BEGIN
	extract_sql.extract_SQL_full_total(3265954359,p_total_exec_time=>100,p_min_time=>to_date('11.10.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'), p_max_time=>to_date('20.10.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'));
	extract_sql.extract_SQL_full_exec(3265954359,p_max_exec_time=>10, p_min_time=>to_date('11.10.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'), p_max_time=>to_date('20.10.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'));
END;
/

BEGIN
	extract_sql.extract_SQL_full_total(3173536249,p_total_exec_time=>10,p_min_time=>to_date('19.10.2024 10:56:00','dd.mm.yyyy hh24:mi:ss'), p_max_time=>to_date('19.10.2024 15:02:00','dd.mm.yyyy hh24:mi:ss'));
	extract_sql.extract_SQL_full_exec(3173536249,p_max_exec_time=>10, p_min_time=>to_date('19.10.2024 10:56:00','dd.mm.yyyy hh24:mi:ss'), p_max_time=>to_date('19.10.2024 15:02:00','dd.mm.yyyy hh24:mi:ss'));
END;
/


BEGIN
	extract_sql.extract_SQL_full_total(2707072167,p_total_exec_time=>10,p_min_time=>to_date('27.09.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'), p_max_time=>to_date('10.10.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'));
	extract_sql.extract_SQL_full_exec(2707072167,p_max_exec_time=>10, p_min_time=>to_date('27.09.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'), p_max_time=>to_date('10.10.2024 00:00:00','dd.mm.yyyy hh24:mi:ss'));
END;
/

alter user test rename to dick identified by values '3DCFE76EA7D55A80';