-- Showing tables statistics versions on all tables related to a SQL_ID  
-- 
-- sql_id := &&1

--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : stats_his.sql f3gyxvq104jgd
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set echo off feed off
set serveroutput on size 1000000
set sqlblanklines on


define sql_id ='&1'



set lines 200

col OBJECT_NAME format a35
col owner  format a25
col SAVTIME format a35

INSERT INTO plan_table (object_type, object_owner, object_name)
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = '&&sql_id'
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE  sql_id = '&&sql_id'
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
)
SELECT 'TABLE', t.owner, t.table_name
  FROM dba_tab_statistics t, -- include fixed objects
       object o
 WHERE t.owner = o.owner
   AND t.table_name = o.name
 UNION
SELECT 'TABLE', i.table_owner, i.table_name
  FROM dba_indexes i,
       object o
 WHERE i.owner = o.owner
   AND i.index_name = o.name;
   

commit;
   



SELECT *
  FROM (
WITH object AS (
SELECT /*+ MATERIALIZE */
       object_owner owner, object_name name
  FROM gv$sql_plan
 WHERE inst_id IN (SELECT inst_id FROM gv$instance)
   AND sql_id = '&&sql_id'
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 UNION
SELECT object_owner owner, object_name name
  FROM dba_hist_sql_plan
 WHERE 
    sql_id = '&&sql_id'
   AND object_owner IS NOT NULL
   AND object_name IS NOT NULL
 ), plan_tables AS (
 SELECT /*+ MATERIALIZE */
        'TABLE' object_type, t.owner object_owner, t.table_name object_name
   FROM dba_tab_statistics t, -- include fixed objects
        object o
  WHERE t.owner = o.owner
    AND t.table_name = o.name
  UNION
 SELECT 'TABLE' object_type, i.table_owner object_owner, i.table_name object_name
   FROM dba_indexes i,
        object o
  WHERE i.owner = o.owner
    AND i.index_name = o.name
)
SELECT *
  FROM (
SELECT /*+ NO_MERGE LEADING(pt s t m) */
       t.table_name object_name,
       t.owner,
           'CURRENT' version_type,
       NULL savtime,
           t.last_analyzed analyzetime,
           t.num_rows rowcnt,
           t.sample_size samplesize,
           CASE WHEN t.num_rows > 0 THEN TO_CHAR(ROUND(t.sample_size * 100 / t.num_rows, 1), '99999990D0') END perc,
           t.blocks blkcnt,
           t.avg_row_len avgrln
  FROM plan_tables pt,
       dba_tables t
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.table_name
UNION ALL
SELECT /*+ NO_MERGE LEADING(pt s t m) */
       t.object_name,
       t.owner,
           'HISTORY' version_type,
       h.savtime,
           h.analyzetime,
           h.rowcnt,
           h.samplesize,
           CASE WHEN h.rowcnt > 0 THEN TO_CHAR(ROUND(h.samplesize * 100 / h.rowcnt, 1), '99999990D0') END perc,
           h.blkcnt,
           h.avgrln
  FROM plan_tables pt,
       dba_objects t,
           sys.WRI$_OPTSTAT_TAB_HISTORY h
 WHERE pt.object_type = 'TABLE'
   AND pt.object_owner = t.owner
   AND pt.object_name = t.object_name
   AND t.object_id = h.obj#
   AND t.object_type = 'TABLE')
 ORDER BY
       object_name,
       owner,
           savtime DESC NULLS FIRST) v;
		   
		   
		   
exit;
		   