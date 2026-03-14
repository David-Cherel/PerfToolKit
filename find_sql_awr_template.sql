-- #############################################################################################################
-- Find SQL Query in AWR and displays KPI's 
-- Accept an extract of sql_text or SQL_ID as inputs
-- Display : sql_id, plan_hash_value, sql_text, avg_pio, avg_lio, avg_etime, execs, rows_proc
-- Allows to show performance KPI's for that SQL_ID and plan_hash_value 
-- #############################################################################################################


set pages 9999
set long 32000
set lines 220
set verify off
set trimspool on
set tab off
set feedback on
set termout on

whenever sqlerror exit failure rollback

define sqltext = '&1'

begin
  if '&&sqltext' is null then
    raise_application_error(-20051, 'SQL text extract is mandatory. Usage: @find_sql_awr_template.sql <SQL_TEXT_EXTRACT>');
  end if;
end;
/

prompt
prompt =====================================================================================================
prompt Searching SQL in AWR history for text extract: &&sqltext
prompt =====================================================================================================

col sql_text format a70
col node for 99999
col avg_etime for 999,999.99999
col avg_lio for 999,999,999.9
col avg_pio for 999,999,999.9
col avg_cpu_time for 999,999.99999

select /* PTK */ distinct
       s.instance_number node,
       s.sql_id,
       s.plan_hash_value,
       s.executions_delta execs,
       (s.elapsed_time_delta/1000000)/decode(nvl(s.executions_delta,0),0,1,s.executions_delta) avg_etime,
       s.disk_reads_delta/decode(nvl(s.executions_delta,0),0,1,s.executions_delta) avg_pio,
       s.buffer_gets_delta/decode(nvl(s.executions_delta,0),0,1,s.executions_delta) avg_lio,
       s.cpu_time_delta/decode(nvl(s.executions_delta,0),0,1,s.executions_delta)/1000000 avg_cpu_time,
       dbms_lob.substr(txt.sql_text,3999,1) sql_text
from DBA_HIST_SQLSTAT S,  dba_hist_sqltext txt
where s.sql_id=txt.sql_id
and upper(dbms_lob.substr(txt.sql_text,3999,1)) like upper('%'||'&sqltext'||'%')
and dbms_lob.substr(txt.sql_text,3999,1) not like '%/* PTK */%'
order by avg_etime desc, s.instance_number, s.sql_id, s.plan_hash_value
/

prompt
prompt NOTE: Rows are sorted by AVG_ETIME DESC to identify high-cost historical candidates first.
