
-- #############################################################################################################
-- FILE: export_sql_baseline_plan.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Exports one specific SQL Plan Baseline plan by PLAN_NAME by packing it into a staging table and exporting that table through Data Pump to a dump file.
--
-- INPUT PARAMETERS:
-- &1 (plan_name) - STRING - SQL Plan Baseline plan name to export (e.g., 'SQLID_auy3f5g7da1_2481688974').
-- &2 (table_name) - STRING - Staging table name used to pack the selected baseline plan.
-- &3 (table_owner) - STRING - Owner/schema of the staging table.
-- &4 (tablespace) - STRING - Tablespace for staging table creation.
-- &5 (exp_file_name) - STRING - Data Pump dump filename to generate in DATA_PUMP_DIR (e.g., 'exp_perftool.dmp').
--
-- OUTPUT DESCRIPTION:
-- Creates staging table, packs the selected baseline plan, exports staging table with Data Pump, writes progress to export_sql_baseline.log and perftool_exp.log, then drops staging table.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I export a single SQL Plan Baseline by plan name?
-- Which plan name is being exported?
-- Which staging table is used during export?
-- Where are the Data Pump dump and log files generated?
-- Did the single-plan export job complete successfully?
-- How can I clean up staging objects after export?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : export_sql_baseline_plan.sql SQLID_auy3f5g7da1_2481688974 STAGING_PERF OLAP USERS exp_perftool.dmp
-- #############################################################################################################
--
spool export_sql_baseline_plan.log

set feedback off
set sqlblanklines on
set serveroutput on
set verify off
set lines 160
declare


l_plan_name varchar2(40);
l_table_name varchar2(40);
l_table_owner varchar2(12);
l_tablespace varchar2(15);

ret number;
l_dph number; -- The datapump job handle
l_status varchar2(4000); -- terminating status of the job
l_file_name varchar2(30);

l_dir_path varchar2(4000);





begin



l_plan_name := '&&1';
l_table_name := '&&2';
l_table_owner := '&&3';
l_tablespace := '&&4';
l_file_name := '&&5';



dbms_output.put_line('Creation of staging table for loading SQL Plan from Baseline, table name : '||l_table_name);
dbms_spm.create_stgtab_baseline(table_name => l_table_name,table_owner => l_table_owner,tablespace_name => l_tablespace);

dbms_output.put_line('Loading SQL Plan : '||l_plan_name||' into staging table : '||l_table_name);
ret := dbms_spm.pack_stgtab_baseline(table_name => l_table_name,table_owner => l_table_owner,plan_name => l_plan_name);

dbms_output.put_line('Exporting table  : '||l_table_name);

    -- create the job...
	dbms_output.put_line('create job');
    l_dph := dbms_datapump.open(operation => 'EXPORT',job_mode => 'TABLE', job_name => 'EXP'||l_plan_name );
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
	
	dbms_output.put_line('Cleaning of staging table');
	EXECUTE IMMEDIATE 'DROP TABLE ' ||l_table_owner||'.'||l_table_name;	

	dbms_output.put_line('END OF :  EXPORT SQL BASELINE (SINGLE PLAN)');

end;
/

spool off
exit;
