-- #############################################################################################################
-- FILE: dbtime.old.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Reports top AWR snapshot intervals by DB Time, with optional instance and snapshot-range filters, to identify busiest historical periods.
--
-- INPUT PARAMETERS:
-- &1 (instance_number) - NUMBER - Optional RAC instance filter (e.g., 1).
-- &2 (begin_snap_id) - NUMBER - Optional begin snapshot ID (e.g., 20976).
-- &3 (end_snap_id) - NUMBER - Optional end snapshot ID (e.g., 20978).
--
-- OUTPUT DESCRIPTION:
-- One result set of top snapshot intervals ranked by DB Time (minutes), showing begin/end snapshot IDs, interval timestamp, and instance number; output is spooled to dbtime.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which AWR time intervals had the highest DB Time consumption?
-- What are the busiest periods for a specific RAC instance?
-- How does DB Time vary across a selected snapshot range?
-- Which snapshot pair should be used for deeper SQL/AWR investigation?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : dbtime.old.sql 1 20976 20978
-- #############################################################################################################
--
set lines 155
col dbtime for 999,999.99
col begin_timestamp for a40

spool dbtime.log

COLUMN myminid NEW_VALUE v_myminid
COLUMN mymaxid NEW_VALUE v_mymaxid

select min(snap_id) as myminid from CDB_HIST_SNAPSHOT SS, V$DATABASE DB where ss.DBID =DB.CON_DBID ;
select max(snap_id) as mymaxid from CDB_HIST_SNAPSHOT SS, V$DATABASE DB where ss.DBID =DB.CON_DBID;

define instance_number ='&1'
define begin_snap_id ='&2'
define end_snap_id ='&3'

select * from (
select begin_snap, end_snap, timestamp begin_timestamp, inst, a/1000000/60 DBtime from
(
select
 e.snap_id end_snap,
 lag(e.snap_id) over (order by e.snap_id) begin_snap,
 lag(s.end_interval_time) over (order by e.snap_id) timestamp,
 s.instance_number inst,
 e.value,
 nvl(value-lag(value) over (order by e.snap_id),0) a
from dba_hist_sys_time_model e, CDB_HIST_SNAPSHOT s, V$DATABASE DB
where s.snap_id = e.snap_id
 and e.instance_number = s.instance_number
 and DB.CON_DBID=s.DBID
 and to_char(e.instance_number) like nvl('&instance_number',to_char(e.instance_number))
 and stat_name='DB time'
)
where  begin_snap between nvl('&begin_snap_id',&v_myminid) and nvl('&end_snap_id',&v_mymaxid)
and begin_snap=end_snap-1
order by dbtime desc
) where rownum < 10;
spool off
exit;
