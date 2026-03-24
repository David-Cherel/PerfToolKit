-- #############################################################################################################
-- FILE: create_sql_set_library_cache.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Creates a SQL Tuning Set from current library cache statements, excluding selected system schemas, and loads captured SQL/plans with full attributes for later tuning, analysis, or baseline management operations.
--
-- INPUT PARAMETERS:
-- &1 (sql_set_name) - STRING - Name of the SQL Tuning Set to create from library cache content.
--
-- OUTPUT DESCRIPTION:
-- Creates and loads the SQL tuning set, prints DBMS_OUTPUT execution context and total number of plans loaded, and exits after undefining SQL*Plus variables.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I create a SQL Tuning Set from current library cache SQL?
-- How can I capture library cache SQL while excluding system schemas?
-- How many plans were loaded into the created SQL set?
-- Can I include recursive SQL when building a SQL set from library cache?
-- What SQL set name was used for the library cache capture?
-- Did SQL set creation and load complete successfully?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : create_sql_set_library_cache.sql MY_SQLSET_LIBCACHE
-- #############################################################################################################
--

set feedback off
set sqlblanklines on
set verify off
set serveroutput on
set lines 180

define sql_set_name = '&1'


declare


cur DBMS_SQLSET.SQLSET_CURSOR;
cnt_plans number;


begin


dbms_output.put_line('#########################################################################################');
dbms_output.put_line('SQL Set from Library Cache,  attribute_list=> ALL, percent=100% , HAS_RECURSIVE_SQL ');
dbms_output.put_line('#########################################################################################');



DBMS_SQLSET.CREATE_SQLSET (sqlset_name=>'&&sql_set_name',description=>'all plans from Library Cache');

open cur for
  select value(p) from table(DBMS_SQLTUNE.select_cursor_cache(
                    basic_filter      => 'parsing_schema_name not in (''DVSYS'',''SYS'',''ORACLE_OCM'',''ORDSYS'')',
					object_filter     => NULL,
                    ranking_measure1 => NULL, 
					ranking_measure2 => NULL, 
					ranking_measure3 => NULL,
					result_percentage => 1,
					result_limit      => NULL, 
					attribute_list    => 'ALL',
					recursive_sql     => 'HAS_RECURSIVE_SQL')) p;

  dbms_sqltune.load_sqlset('&&sql_set_name', cur);
  
close cur;

select count(*) into cnt_plans from TABLE(DBMS_SQLSET.SELECT_SQLSET (sqlset_name=>'&&sql_set_name')) ;
dbms_output.put_line('');
dbms_output.put_line('');
dbms_output.put_line('#########################################################################################');
dbms_output.put_line('Number of plans loaded : '||to_char(cnt_plans)||' in the SQL set: '||'&&sql_set_name');
dbms_output.put_line('#########################################################################################');
dbms_output.put_line('');
dbms_output.put_line('');

END;
/



undef cur
undef sql_set_name

exit;
