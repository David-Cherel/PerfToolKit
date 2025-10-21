----------------------------------------------------------------------------------------
--
-- File name:   dbtime.sql
-- Purpose:     Find busiest time periods in AWR.
-
-- Author:      Kerry Osborne
--
-- Usage:       This scripts prompts for three values, all of which can be left blank.
--
--              instance_number: set to limit to a single instance in RAC environment
--
--              begin_snap_id: set it you want to limit to a specific range, defaults to 0
--
--              end_snap_id: set it you want to limit to a specific range, defaults to 99999999
--
--
---------------------------------------------------------------------------------------


-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : dbtime.sql 1 20976 20978
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


set serveroutput on
set sqlblanklines on
set feedback off
set lines 155
col dbtime for 999,999.99
col begin_timestamp for a40

spool dbtime.log


define instance_num = '&1'
define min_input = '&2'
define max_input = '&3'


declare
min_snap number;
max_snap number;
MYDBID number;

BEGIN

select CON_DBID into MYDBID from v$database;
dbms_output.put_line('I am connected to MYDBID : '||MYDBID);
select min(snap_id) into min_snap from CDB_HIST_SNAPSHOT SS, V$DATABASE DB where ss.DBID =DB.CON_DBID;
select max(snap_id) into max_snap from CDB_HIST_SNAPSHOT SS, V$DATABASE DB where ss.DBID =DB.CON_DBID;

dbms_output.put_line('min_snap in that DB : '||min_snap);
dbms_output.put_line('max_snap in that DB : '||max_snap);
END;
/


DECLARE
    -- Substitute values appropriately
    v_instance_num VARCHAR2(10) := NULL;   -- For "all instances" use NULL
    v_min_input    NUMBER := NULL;         -- For "minimum snap" use NULL
    v_max_input    NUMBER := NULL;         -- For "maximum snap" use NULL

    CURSOR c_snap_stats IS
        SELECT *
          FROM (
            SELECT begin_snap, end_snap, begin_timestamp, inst, dbtime_min
              FROM (
                SELECT
                    e.snap_id end_snap,
                    LAG(e.snap_id) OVER (ORDER BY e.snap_id) begin_snap,
                    LAG(s.end_interval_time) OVER (ORDER BY e.snap_id) begin_timestamp,
                    s.instance_number inst,
                    e.value,
                    NVL(e.value - LAG(e.value) OVER (ORDER BY e.snap_id),0) a,
                    NVL(e.value - LAG(e.value) OVER (ORDER BY e.snap_id),0)/1000000/60 dbtime_min
                  FROM dba_hist_sys_time_model e
                  JOIN cdb_hist_snapshot s ON e.snap_id = s.snap_id
                    AND e.instance_number = s.instance_number
                  CROSS JOIN v$database db
                 WHERE db.con_dbid = s.dbid
                   AND TO_CHAR(e.instance_number) LIKE NVL('&&instance_num', TO_CHAR(e.instance_number))
                   AND stat_name = 'DB time'
              )
             WHERE begin_snap BETWEEN NVL('&&min_input', begin_snap) 
                                  AND NVL('&&max_input', end_snap)
               AND begin_snap = end_snap - 1
             ORDER BY dbtime_min DESC
          )
         WHERE ROWNUM < 10;

    -- Variables to hold cursor data
    v_begin_snap    NUMBER;
    v_end_snap      NUMBER;
    v_timestamp     DATE;
    v_inst          NUMBER;
    v_dbtime_min    NUMBER;
BEGIN
    OPEN c_snap_stats;
    LOOP
        FETCH c_snap_stats INTO v_begin_snap, v_end_snap, v_timestamp, v_inst, v_dbtime_min;
        EXIT WHEN c_snap_stats%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(
            'Begin Snap: ' || v_begin_snap ||
            ', End Snap: ' || v_end_snap ||
            ', Timestamp: ' || TO_CHAR(v_timestamp, 'YYYY-MM-DD HH24:MI:SS') ||
            ', Instance: ' || v_inst ||
            ', DB Time (Min): ' || ROUND(v_dbtime_min, 2)
        );
    END LOOP;
    CLOSE c_snap_stats;
END;
/

-- EXECUTE IMMEDIATE 
-- q'[ select * from (
-- select begin_snap, end_snap, timestamp begin_timestamp, inst, a/1000000/60 DBtime_min from
-- (
-- select
 -- e.snap_id end_snap,
 -- lag(e.snap_id) over (order by e.snap_id) begin_snap,
 -- lag(s.end_interval_time) over (order by e.snap_id) timestamp,
 -- s.instance_number inst,
 -- e.value,
 -- nvl(value-lag(value) over (order by e.snap_id),0) a
-- from dba_hist_sys_time_model e, CDB_HIST_SNAPSHOT s, V$DATABASE DB
-- where s.snap_id = e.snap_id
 -- and e.instance_number = s.instance_number
 -- and DB.CON_DBID=s.DBID
 -- and to_char(e.instance_number) like nvl(&&instance_num,to_char(e.instance_number))
 -- and stat_name='DB time'
-- )
-- where  begin_snap between nvl(&&min_input,min_snap) and nvl(&&max_input,max_snap)
-- and begin_snap=end_snap-1
-- order by dbtime desc
-- ) where rownum < 10]'
-- into 
-- v_result ;




spool off


exit;
