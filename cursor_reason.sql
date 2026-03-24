-- #############################################################################################################
-- FILE: cursor_reason.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Displays cursor not-shared reasons for a SQL_ID by extracting V$SQL_SHARED_CURSOR XML reason details and aggregating them per child cursor.
--
-- INPUT PARAMETERS:
-- &1 (sql_id) - STRING - SQL_ID to analyze for child cursor non-sharing reasons (e.g., 'cm1fyt76dwbkb').
--
-- OUTPUT DESCRIPTION:
-- One result set with SQL_ID, CHILD_NUMBER, and aggregated non-sharing reason text for each child cursor.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Why were multiple child cursors created for this SQL_ID?
-- What non-sharing reasons are recorded for each child cursor?
-- Which child cursors share the same or different non-sharing causes?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : cursor_reason.sql cm1fyt76dwbkb
-- #############################################################################################################
--
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