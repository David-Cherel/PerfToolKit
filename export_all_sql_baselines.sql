-- #############################################################################################################
-- FILE: export_all_sql_baselines.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Exports all SQL Plan Baselines by packing them into a staging table and exporting that table with Data Pump to a dump file in DATA_PUMP_DIR for transfer or later import.
--
-- INPUT PARAMETERS:
-- &1 (sql_handle) - STRING - ALL for all SQL Baselines.
-- &2 (table_name) - STRING - Staging table name used to pack baselines before export.
-- &3 (table_owner) - STRING - Owner/schema of the staging table.
-- &4 (tablespace) - STRING - Tablespace for staging table creation.
-- &5 (exp_file_name) - STRING - Data Pump dump filename to generate in DATA_PUMP_DIR.
--
-- OUTPUT DESCRIPTION:
-- Creates staging table, packs all baselines, runs Data Pump export of staging table, writes progress to DBMS_OUTPUT and export_sql_baseline.log, then drops staging table and reports dump/log locations.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I export all SQL Plan Baselines to a dump file?
-- Which staging table is used to pack SQL baselines before export?
-- Where is the generated dump file written?
-- Where is the Data Pump export log file written?
-- Did Data Pump export complete successfully?
-- How can I clean up staging objects after baseline export?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : export_all_sql_baselines.sql ALL STAGING OLAP USERS DUMPFILE001
-- #############################################################################################################
--
set feedback off
set sqlblanklines on
set serveroutput on
set verify off
set lines 160
spool export_sql_baseline.log
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



l_sql_handle := '&&1';
l_table_name := '&&2';
l_table_owner := '&&3';
l_tablespace := '&&4';
l_file_name := '&&5';


	
dbms_output.put_line('Creation of staging table for loading ALL SQL Baseline, table name : '||l_table_name);
dbms_spm.create_stgtab_baseline(table_name => l_table_name,table_owner => l_table_owner,tablespace_name => l_tablespace);

dbms_output.put_line('Loading ALL SQL Baseline  into staging table : '||l_table_name);
ret := dbms_spm.pack_stgtab_baseline(table_name => l_table_name,table_owner => l_table_owner,sql_handle => NULL);

dbms_output.put_line('Exporting table  : '||l_table_name);

    -- create the job...
	dbms_output.put_line('create job');
    l_dph := dbms_datapump.open(operation => 'EXPORT',job_mode => 'TABLE', job_name => 'EXPA'||l_sql_handle );
		dbms_output.put_line('METADATA_FILTER SCHEMA_LIST ');

	-- We only want objects in the specific schema
	    dbms_datapump.metadata_filter
    (
        handle => l_dph,
        name => 'SCHEMA_LIST',
        value => '''&&3'''
    );
		
	-- We only want that table 
	dbms_output.put_line('METADATA_FILTER TABLE NAME');
	dbms_datapump.METADATA_FILTER 
    (
        handle => l_dph,
        name => 'NAME_LIST',
        value => '''&&2''',
		object_path => 'TABLE'
    );
	-- We want to exclude STATISTICS 
	dbms_datapump.metadata_filter
    (
        handle => l_dph,
        name => 'EXCLUDE_PATH_EXPR',
        value => q'[= 'STATISTICS']'
    );
	
    -- Specify the name and location of the export dump file we want to create...
    dbms_output.put_line('add_file for dump file: ' ||l_file_name);
	dbms_datapump.add_file
    (
        handle => l_dph,
        filename => l_file_name,
        directory => 'DATA_PUMP_DIR', -- can use any database directory object
        filetype => dbms_datapump.ku$_file_type_dump_file,
        reusefile => 1 -- if this file already exists, overwrite it
    );
    -- ...and a log file to track the progress of the export
	dbms_output.put_line('add_file log file: perftool_exp.log');
    dbms_datapump.add_file
    (
        handle => l_dph,
        filename => 'perftool_exp.log',
        directory => 'DATA_PUMP_DIR',
        filetype => dbms_datapump.ku$_file_type_log_file,
        reusefile => 1
    );
    -- Kick off the export
	dbms_output.put_line('Starting job');
    dbms_datapump.start_job( handle => l_dph);
 
    -- ...and wait for the job to complete
	dbms_output.put_line('Waiting for end of job');
    dbms_datapump.wait_for_job( handle => l_dph, job_state => l_status);
 
    dbms_output.put_line('Export job done - status : '||l_status);
    select DIRECTORY_PATH into l_dir_path from dba_directories where DIRECTORY_NAME ='DATA_PUMP_DIR';
	dbms_output.put_line('Check log file, perftool_exp.log,  in location : '||l_dir_path);
	dbms_output.put_line('Take dump file: '||l_file_name||' from location : '||l_dir_path);
	
	dbms_output.put_line('Cleaning of staging table  ');
	EXECUTE IMMEDIATE 'DROP TABLE ' ||l_table_owner||'.'||l_table_name;	

	dbms_output.put_line('END OF :  EXPORT SQL BASELINE ALL PLANS');

end;
/

spool off
exit;