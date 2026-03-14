-- #############################################################################################################
-- Histogram advisor using SYS.COL_USAGE$ + dictionary stats
-- Goal:
--   1) Describe potential data skew and predicate usage for one column
--   2) Show missing / weak stats indicators
--   3) Propose command to gather histogram as PENDING (unpublished) stats
--   4) Provide test workflow with optimizer_use_pending_statistics=TRUE
--
-- Usage:
--   @histogram_pending_stats_advisor.sql <OWNER> <TABLE_NAME> <COLUMN_NAME> [APPLY_PENDING]
--
-- Example (advice only):
--   @histogram_pending_stats_advisor.sql SH SALES AMOUNT_SOLD NO
--
-- Example (apply pending stats):
--   @histogram_pending_stats_advisor.sql SH SALES AMOUNT_SOLD YES
-- #############################################################################################################

set pages 9999
set lines 220
set verify off
set trimspool on
set tab off
set feedback on
set termout on
set serveroutput on

whenever sqlerror exit failure rollback

define owner_name  = '&1'
define table_name  = '&2'
define column_name = '&3'
define apply_pending = '&4'

begin
  if '&&owner_name' is null or '&&table_name' is null or '&&column_name' is null then
    raise_application_error(-20301,
      'Usage: @histogram_pending_stats_advisor.sql <OWNER> <TABLE_NAME> <COLUMN_NAME> [APPLY_PENDING]');
  end if;

  if upper(nvl('&&apply_pending','NO')) not in ('NO','N','YES','Y') then
    raise_application_error(-20302, 'APPLY_PENDING must be YES/Y or NO/N (or empty).');
  end if;
end;
/

spool histogram_pending_stats_advisor.log

prompt
prompt =====================================================================================================
prompt Histogram Advisor for &&owner_name..&&table_name..&&column_name
prompt =====================================================================================================
prompt NOTE: This script is advisory by default. APPLY_PENDING=YES will gather pending stats.

column owner                 format a20
column table_name            format a30
column column_name           format a30
column histogram             format a18
column stats_status          format a18
column stale_stats           format a6
column last_analyzed         format a20
column density               format 9.999999999999
column uniform_density       format 9.999999999999
column skew_factor           format 9999990.999

prompt
prompt --- 1) Column stats and skew indicators ---

select c.owner,
       c.table_name,
       c.column_name,
       c.num_distinct,
       c.num_nulls,
       c.num_buckets,
       c.histogram,
       to_char(c.last_analyzed,'yyyy-mm-dd hh24:mi:ss') last_analyzed,
       c.density,
       case when c.num_distinct > 0 then 1/c.num_distinct end uniform_density,
       case when c.num_distinct > 0 and c.density is not null
            then c.density / (1/c.num_distinct)
       end skew_factor,
       case
         when c.last_analyzed is null then 'MISSING'
         when c.num_distinct is null then 'INCOMPLETE'
         else 'OK'
       end stats_status,
       t.stale_stats
from   dba_tab_col_statistics c
       join dba_tab_statistics t
         on t.owner = c.owner
        and t.table_name = c.table_name
where  c.owner = upper('&&owner_name')
and    c.table_name = upper('&&table_name')
and    c.column_name = upper('&&column_name');

prompt
prompt --- 1b) Predicate usage from SYS.COL_USAGE$ (workload evidence) ---

column equality_preds   format 999999999
column equijoin_preds   format 999999999
column nonequijoin_preds format 999999999
column range_preds      format 999999999
column like_preds       format 999999999
column null_preds       format 999999999
column usage_timestamp  format a30

select o.owner,
       o.object_name table_name,
       c.column_name,
       u.equality_preds,
       u.equijoin_preds,
       u.nonequijoin_preds,
       u.range_preds,
       u.like_preds,
       u.null_preds,
       to_char(u.timestamp,'yyyy-mm-dd hh24:mi:ss') usage_timestamp
from   sys.col_usage$ u
       join dba_objects o
         on o.object_id = u.obj#
       join dba_tab_cols c
         on c.owner = o.owner
        and c.table_name = o.object_name
        and c.internal_column_id = u.intcol#
where  o.object_type = 'TABLE'
and    o.owner = upper('&&owner_name')
and    o.object_name = upper('&&table_name')
and    c.column_name = upper('&&column_name');

prompt
prompt --- 2) Missing / weak stats checks ---

select case when c.last_analyzed is null then 'YES' else 'NO' end missing_stats,
       case when c.num_distinct is null then 'YES' else 'NO' end missing_num_distinct,
       case when c.histogram = 'NONE' then 'YES' else 'NO' end no_histogram,
       case when t.stale_stats = 'YES' then 'YES' else 'NO' end table_stats_stale
from   dba_tab_col_statistics c
       join dba_tab_statistics t
         on t.owner = c.owner
        and t.table_name = c.table_name
where  c.owner = upper('&&owner_name')
and    c.table_name = upper('&&table_name')
and    c.column_name = upper('&&column_name');

prompt
prompt --- 3) Proposed command (pending/unpublished histogram stats) ---

select 'exec dbms_stats.set_table_prefs('''||upper('&&owner_name')||''','''||upper('&&table_name')||''',''PUBLISH'',''FALSE'');' as cmd
from dual
union all
select 'exec dbms_stats.gather_table_stats('''||upper('&&owner_name')||''','''||upper('&&table_name')||''', method_opt=>''FOR COLUMNS SIZE AUTO "'||upper('&&column_name')||'"'', cascade=>dbms_stats.auto_cascade, no_invalidate=>false);'
from dual;

prompt
prompt --- Optional apply (only if APPLY_PENDING=YES) ---

declare
  v_apply varchar2(3) := upper(nvl('&&apply_pending','NO'));
begin
  if v_apply in ('YES','Y') then
    dbms_output.put_line('Applying PENDING stats workflow...');

    dbms_stats.set_table_prefs(
      ownname => upper('&&owner_name'),
      tabname => upper('&&table_name'),
      pname   => 'PUBLISH',
      pvalue  => 'FALSE'
    );

    dbms_stats.gather_table_stats(
      ownname       => upper('&&owner_name'),
      tabname       => upper('&&table_name'),
      method_opt    => 'FOR COLUMNS SIZE AUTO "'||upper('&&column_name')||'"',
      cascade       => dbms_stats.auto_cascade,
      no_invalidate => false
    );

    dbms_output.put_line('Pending stats gathered (not published).');
  else
    dbms_output.put_line('APPLY_PENDING is NO -> advice mode only (no stats gathered).');
  end if;
end;
/

prompt
prompt --- Pending stats visibility ---

column save_time format a22
select owner,
       table_name,
       to_char(save_time,'yyyy-mm-dd hh24:mi:ss') save_time
from   dba_tab_pending_stats
where  owner = upper('&&owner_name')
and    table_name = upper('&&table_name');

prompt
prompt --- 4) Test workflow with optimizer_use_pending_statistics ---
prompt In a dedicated TEST session only:
prompt   alter session set optimizer_use_pending_statistics=true;
prompt   explain plan for <your test query>;
prompt   select * from table(dbms_xplan.display(format=>'BASIC +PREDICATE +NOTE'));
prompt Then compare with pending stats disabled:
prompt   alter session set optimizer_use_pending_statistics=false;
prompt   explain plan for <your test query>;
prompt   select * from table(dbms_xplan.display(format=>'BASIC +PREDICATE +NOTE'));

prompt
prompt NOTE:
prompt - SYS.COL_USAGE$ is an internal table; query it read-only and prefer DBA_* views for supportability.
prompt - Gather pending stats in test windows first, then publish only after validation.

spool off

exit;
