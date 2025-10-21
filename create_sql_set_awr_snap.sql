-- ################################################################################################
-- Create SQL Set from AWR reports 
-- It will take snapshot_id begin and end to capture all plans
-- there is no selection criteria except that it will exclude SYS, 
-- ORACLE_OCM and ORDSYS as a parsing schema. All plan will capture from AWR reports
-- ################################################################################################
-- SQL_Set_Name := &&1
-- begin_snap := &&2
-- end_snap := &&3
--
--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : create_sql_set_awr_snap.sql my_sal_set 25698 25950
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set feedback off
set sqlblanklines on
set verify off
set serveroutput on
set lines 180

define sql_set_name = '&1'
define snapid_begin = '&2'
define snapid_end = '&3'

declare


cur DBMS_SQLSET.SQLSET_CURSOR;
cnt_plans number;

begin




DBMS_SQLSET.CREATE_SQLSET (sqlset_name=>'&&sql_set_name',description=>'all plans snapid &&snapid_begin to &&snapid_end');

open cur for
  select value(p) from table(dbms_sqltune.select_workload_repository(
       begin_snap       => &&snapid_begin,
       end_snap         => &&snapid_end,
       basic_filter     => 'parsing_schema_name not in (''SYS'',''ORACLE_OCM'',''ORDSYS'')',
       ranking_measure1 => NULL,
       result_limit     => NULL,
       attribute_list   => 'ALL')) p;

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
