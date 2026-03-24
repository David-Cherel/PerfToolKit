
-- #############################################################################################################
-- FILE: create_sql_set_awr_snap.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Creates a SQL Tuning Set from AWR snapshots within a specified snapshot range, excluding selected system schemas, and loads captured statements/plans for later analysis or baseline operations.
--
-- INPUT PARAMETERS:
-- &1 (sql_set_name) - STRING - Name of the SQL Tuning Set to create.
-- &2 (snapid_begin) - NUMBER - Optional begin snapshot ID; if null, minimum snapshot ID for current DBID is used.
-- &3 (snapid_end) - NUMBER - Optional end snapshot ID; if null, maximum snapshot ID for current DBID is used.
--
-- OUTPUT DESCRIPTION:
-- Creates and loads the SQL tuning set, prints DBMS_OUTPUT details (DBID, snapshot bounds, number of plans loaded), and exits after undefining SQL*Plus variables.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I create a SQL Tuning Set from AWR snapshot history?
-- How can I capture SQL plans between two snapshot IDs into a SQL set?
-- Can I default snapshot boundaries to min/max available snapshots?
-- How can I exclude system schemas while loading SQL from AWR?
-- How many plans were loaded into the created SQL set?
-- What DBID and snapshot range were used during SQL set creation?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : create_sql_set_awr_snap.sql MY_SQLSET 20976 20978
-- #############################################################################################################
--

spool create_sql_set_awr_snap.log

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
MYDBID number;
min_snap_id number;
max_snap_id number;
adjusted_snapid_begin number;
adjusted_snapid_end number;

begin

select CON_DBID into MYDBID from v$database;
dbms_output.put_line('#########################################################################################');
dbms_output.put_line('MYDBID : '||MYDBID);
select min(snap_id), max(snap_id) into min_snap_id, max_snap_id from dba_hist_snapshot where DBID=MYDBID;
dbms_output.put_line('min_snap_id : '||min_snap_id);
dbms_output.put_line('max_snap_id : '||max_snap_id);
dbms_output.put_line('#########################################################################################');


-- Check if snapid_begin is null and set it to min_snap_id if so
IF '&snapid_begin' IS NULL THEN
    adjusted_snapid_begin := min_snap_id;
ELSE
    adjusted_snapid_begin := &snapid_begin;
END IF;

-- Check if snapid_end is null and set it to max_snap_id if so
IF '&snapid_end' IS NULL THEN
    adjusted_snapid_end := max_snap_id;
ELSE
    adjusted_snapid_end := &snapid_end;
END IF;


DBMS_SQLSET.CREATE_SQLSET (sqlset_name=>'&&sql_set_name',description=>'all plans snapid '||adjusted_snapid_begin||' to '||adjusted_snapid_end);

open cur for
  select value(p) from table(dbms_sqltune.select_workload_repository(
       begin_snap       => adjusted_snapid_begin,
       end_snap         => adjusted_snapid_end,
       basic_filter     => 'parsing_schema_name not in (''DVSYS'',''SYS'',''ORACLE_OCM'',''ORDSYS'')',
       ranking_measure1 => NULL,
       result_limit     => NULL,
       DBID             => MYDBID,
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

spool off
exit;
