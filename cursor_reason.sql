-- ########################################
-- DPC for displaying Cursor-Not-Shared Reason
-- ########################################
-- sql_id := &&1

--

--
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : cursor_reason.sql cm1fyt76dwbkb
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set feedback off
set sqlblanklines on
set serveroutput on
set lines 180
set verify off

col reasons for a60

define sql_id ='&1'

SELECT ssc.sql_id, ssc.child_number, 
       LISTAGG(xmltab.reason_text, ', ') WITHIN GROUP (ORDER BY xmltab.reason_text) AS reasons
FROM V$SQL_SHARED_CURSOR ssc,
     XMLTABLE('/ChildNode/reason' PASSING XMLPARSE(CONTENT ssc.REASON)
              COLUMNS reason_text VARCHAR2(4000) PATH '.') xmltab
WHERE ssc.sql_id = '&&sql_id'
GROUP BY ssc.sql_id, ssc.child_number;






exit;