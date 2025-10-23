-- ##########################################################
-- import All SQL Plans from dump file (exported earlier)
-- ##########################################################
-- exp_file_name := &&1
-- table_owner := &&2

-- WARNING : This script imports the table from the Data Pump Dump file
-- WARNING : It will then assume that the last table created in the last minute is the Staging Table
-- WARNING : Only the table_owner is required to detect the table freshly imported
-- WARNING : "select object_name into l_table_name from dba_objects where owner=l_table_owner
-- WARNING : and object_type='TABLE' and created>sysdate-(2/24/60);"
-- WARNING : THEN THIS SCRIPT CANNOT BE USED IN PARALLEL OF OTHER TABLE DDL,  OR THIS SCRIPT
-- WARNING : COULD NOT BE USED BY OTHER SESSION IN PARALLEL



--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : import_sql_baseline_all_plans.sql exp_perftool.dmp OLAP
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

-- Logfile here : Directory DATA_PUMP_DIR/perftool_exp.log
-- Dumpfile here : Directory DATA_PUMP_DIR/&&1 (parameter 1)

set feedback off
set sqlblanklines on
set serveroutput on
set verify off
set lines 160
spool import_sql_baseline.log
declare


l_sql_handle varchar2(40);
l_table_name varchar2(40);
l_table_owner varchar2(12);
l_tablespace varchar2(15);

ret number;
l_dph number; -- The datapump job handle
l_status varchar2(4000); -- terminating status of the job
l_file_name varchar2(30);

l_dir_path varchar2(4000);





begin

l_file_name := '&1';
l_table_owner := '&2';



	

dbms_output.put_line('Start of Import procedure from dump : '||l_file_name);

    -- create the job...
	dbms_output.put_line('Create IMPORT job');
    l_dph := dbms_datapump.open(operation => 'IMPORT',job_mode => 'TABLE', job_name => 'IMPA'||l_file_name );
		dbms_output.put_line('METADATA_FILTER SCHEMA_LIST ');

	-- We only want objects in the specific schema
	    dbms_datapump.metadata_filter
    (
        handle => l_dph,
        name => 'SCHEMA_LIST',
        value => '''&&2'''
    );
		
	-- We want to exclude STATISTICS 
	dbms_output.put_line('METADATA_FILTER TABLE EXCLUDE_PATH_EXPR STATISTICS');
	dbms_datapump.metadata_filter
    (
        handle => l_dph,
        name => 'EXCLUDE_PATH_EXPR',
        value => q'[= 'STATISTICS']'
    );
	-- If we find a table that already exists in the target
    -- schema then overwrite it..
	dbms_output.put_line('set_parameter : TABLE_EXISTS_ACTION / REPLACE');
	dbms_datapump.set_parameter
    (
        handle => l_dph,
        name => 'TABLE_EXISTS_ACTION',
        value => 'REPLACE'
    );	
    -- Specify the name and location of the dump file we want to import...
    dbms_output.put_line('add_file for dump file: ' ||l_file_name);
	dbms_datapump.add_file
    (
        handle => l_dph,
        filename => l_file_name,
        directory => 'DATA_PUMP_DIR', -- can use any database directory object
        filetype => dbms_datapump.ku$_file_type_dump_file
        
    );
    -- ...and a log file to track the progress of the export
	dbms_output.put_line('add_file for log file: perftool_exp.log');
    dbms_datapump.add_file
    (
        handle => l_dph,
        filename => 'perftool_imp.log',
        directory => 'DATA_PUMP_DIR',
        filetype => dbms_datapump.ku$_file_type_log_file,
        reusefile => 1
    );
	
	-- log the start time...
    dbms_datapump.log_entry
    (
        handle => l_dph,
        message => 'Import Job starting at '||to_char(sysdate, 'HH24:MI:SS')
    );
    -- Kick off the export
	dbms_output.put_line('Starting import job');
    dbms_datapump.start_job( handle => l_dph);
 
    -- ...and wait for the job to complete
	dbms_output.put_line('Waiting for end of job');
    dbms_datapump.wait_for_job( handle => l_dph, job_state => l_status);
 
    dbms_output.put_line('Import Job finished');
	select DIRECTORY_PATH into l_dir_path from dba_directories where DIRECTORY_NAME ='DATA_PUMP_DIR';
	dbms_output.put_line('Check log file, perftool_exp.log,  in location : '||l_dir_path);
	
	dbms_output.put_line('Looking for the imported staging table containing SQL Baseline ...');
	select object_name into l_table_name from dba_objects where owner=l_table_owner
	and object_type='TABLE' and created>sysdate-(2/24/60);
	dbms_output.put_line('Table found : '||l_table_name);
	dbms_output.put_line('Uploading in SPM ALL SQL Plans from Staging table : '||l_table_name);
	ret := dbms_spm.unpack_stgtab_baseline(table_name => l_table_name,table_owner => l_table_owner);
 
    dbms_output.put_line('Uploading done ');
	dbms_output.put_line('Cleaning of staging table ');
	EXECUTE IMMEDIATE 'DROP TABLE ' ||l_table_owner||'.'||l_table_name;	

	dbms_output.put_line('END OF :  IMPORT SQL BASELINE ALL PLANS FROM DUMP');

end;
/

spool off
exit;