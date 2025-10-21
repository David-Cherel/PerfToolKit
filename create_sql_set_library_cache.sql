-- ################################################################################################
-- Create SQL Set from Library cache  
-- It will capture all plans without "ranking_measure" 
-- there is no selection criteria except that it will exclude SYS, 
-- ORACLE_OCM and ORDSYS as a parsing schema. 
-- ################################################################################################
-- SQL_Set_Name := &&1

--
--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : create_sql_set_library_cache.sql my_sal_set 25698 25950
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


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




DBMS_SQLSET.CREATE_SQLSET (sqlset_name=>'&&sql_set_name',description=>'all plans from Library Cache');

open cur for
  select value(p) from table(DBMS_SQLTUNE.select_cursor_cache(
                    basic_filter      => 'parsing_schema_name not in (''SYS'',''ORACLE_OCM'',''ORDSYS'')',
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
undef snapid_begin
undef snapid_end

exit;
