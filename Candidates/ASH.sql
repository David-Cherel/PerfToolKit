select session_id,blocking_session,blocking_session_serial#,sql_id,program,module,TO_CHAR(min(sample_time),'DD-MM-YYYY HH24:MI:SS'),TO_CHAR(max(sample_time),'DD-MM-YYYY HH24:MI:SS'), count(*)
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1395083989
 and sample_time>to_date('12.01.2018 13:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('12.01.2018 14:00:00','DD.MM.YYYY HH24:MI:SS')
 group by session_id,blocking_session,blocking_session_serial#,sql_id,program,module
 having count(*) > 10
 order by mAX(sample_time) 
;

set linesize 200
col event format a30
col program format a30

select session_id,blocking_session,blocking_session_serial#,sql_id,program,event,max(time_waited),TO_CHAR(min(sample_time),'DD-MM-YYYY HH24:MI:SS'),TO_CHAR(max(sample_time),'DD-MM-YYYY HH24:MI:SS'), count(*)
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1395083989
 and sample_time>to_date('12.01.2018 14:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('12.01.2018 14:30:00','DD.MM.YYYY HH24:MI:SS')
 group by session_id,blocking_session,blocking_session_serial#,sql_id,program,event
 having count(*) > 10
 order by mAX(sample_time) 
;

select blocking_session,count(*) 
 from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1395083989
 and sample_time>to_date('12.01.2018 14:28:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('12.01.2018 14:30:00','DD.MM.YYYY HH24:MI:SS')
 group by blocking_session
 order by count(*)
;

col program format a35
col sample_time format a30
select session_id,blocking_session,sql_id,program,event,time_waited,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1395083989
 and sample_time>to_date('12.01.2018 14:28:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('12.01.2018 14:30:00','DD.MM.YYYY HH24:MI:SS')
and session_id in ( 4610,2815,4878,7984,6152,9304,5745,10003,6676,1359,8677,1910,2459)
order by sample_time;


col program format a35
col sample_time format a30
select session_id,blocking_session,sql_id,program,event,time_waited,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1395083989
  and sample_time>to_date('12.01.2018 14:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('12.01.2018 14:30:00','DD.MM.YYYY HH24:MI:SS')
and session_id in ( 4878)
order by sample_time;

col program format a35
col sample_time format a30
select session_id,blocking_session,sql_id,program,event,time_waited,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1395083989
  and sample_time>to_date('12.01.2018 14:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('12.01.2018 14:30:00','DD.MM.YYYY HH24:MI:SS')
and session_id in ( 2459)
order by sample_time;


col program format a35
col sample_time format a30
select instance_number,session_id,blocking_session,sql_id,program,event,time_waited,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 458595820
 and sample_time>to_date('22.11.2018 09:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('22.11.2018 10:00:00','DD.MM.YYYY HH24:MI:SS')
and time_waited>1000000
order by sample_time;

select * from
DBA_HIST_MEMORY_RESIZE_OPS
where
  dbid = 1395083989;
 and start_time>to_date('12.01.2018 00:00:00','DD.MM.YYYY HH24:MI:SS') ;
 
 
col program format a35
col sample_time format a30
select instance_number,session_id,blocking_session,sql_id,program,event,time_waited,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3092142438
 and sample_time>to_date('11.04.2018 01:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('11.04.2018 01:30:00','DD.MM.YYYY HH24:MI:SS')
and time_waited>1000000
order by sample_time;

col program format a35
col sample_time format a30
select instance_number,session_id,blocking_session,sql_id,program,event,time_waited,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3893859695
 and sample_time>to_date('10.06.2018 22:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('10.06.2018 22:50:00','DD.MM.YYYY HH24:MI:SS')
 and blocking_session is not null
and time_waited>100000
order by sample_time;


col program format a35
col sample_time format a30
select instance_number,session_id,blocking_session,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3092142438
 and sample_time>to_date('11.04.2018 01:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('11.04.2018 01:30:00','DD.MM.YYYY HH24:MI:SS')
 and event = 'log file sync'
and time_waited>50000
order by sample_time;


col program format a35
col sample_time format a30
select instance_number,session_id,blocking_session,sql_id,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3893859695
 and sample_time>to_date('10.06.2018 22:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('10.06.2018 22:50:00','DD.MM.YYYY HH24:MI:SS')
and session_id in ( 16940)
order by sample_time;


col program format a35
col sample_time format a30
select instance_number,session_id,blocking_session,sql_id,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3893859695
 and sample_time>to_date('10.06.2018 22:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('10.06.2018 22:50:00','DD.MM.YYYY HH24:MI:SS')
and session_id in ( 8389)
order by sample_time;


col program format a35
col sample_time format a30
select instance_number,session_id,blocking_session,sql_id,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3893859695
 and sample_time>to_date('10.06.2018 22:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('10.06.2018 22:50:00','DD.MM.YYYY HH24:MI:SS')
and session_id in ( 16933)
order by sample_time;

col program format a35
col sample_time format a30
select instance_number,session_id,blocking_session,sql_id,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3893859695
 and sample_time>to_date('10.06.2018 22:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('10.06.2018 22:50:00','DD.MM.YYYY HH24:MI:SS')
and session_id in ( 3588)
order by sample_time;

set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session,sql_id,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3893859695
 and sample_time>to_date('10.06.2018 22:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('10.06.2018 22:50:00','DD.MM.YYYY HH24:MI:SS')
and session_id in ( 7564)
order by sample_time;

set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session,sql_id,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3893859695
 and sample_time>to_date('10.06.2018 22:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('10.06.2018 22:50:00','DD.MM.YYYY HH24:MI:SS')
and event='rdbms ipc reply'
and blocking_session=7564
order by sample_time;


set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session,sql_id,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3893859695
 and sample_time>to_date('10.06.2018 22:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('10.06.2018 22:50:00','DD.MM.YYYY HH24:MI:SS')
and blocking_session=3588
order by sample_time;


select sql_text from dba_hist_sqltext where sql_id='6pbu8vpfbchz9';
INSERT INTO "SXMSMETERAGGPART" VALUES(:A0,:A1,:A2,:A3,:A4,:A5,:A6,:A7,:A8,:A9,:A10,:A11,:A12,:A13)

Bug 21913183 - CTWR gets ORA-4031 for "ctwr dba buffer" then instance terminates with ORA-29770 (Doc ID 21913183.8)
High Waits On 'block change tracking buffer space' - Checkpoint Contention With BLOCK CHANGE TRACKING or RMAN Incremental Backup (Doc ID 2094946.1)

set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session,sql_id,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2908748683
 and sample_time>to_date('30.07.2018 21:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('30.07.2018 22:00:00','DD.MM.YYYY HH24:MI:SS')
--and event like '%TM%'
and blocking_session=413
order by sample_time;


set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session,sql_id,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2908748683
 and sample_time>to_date('30.07.2018 21:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('30.07.2018 22:00:00','DD.MM.YYYY HH24:MI:SS')
--and event like '%TM%'
and session_id=2313
order by sample_time;


set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session,sql_id,time_waited,program,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 658104099
 and sample_time>to_date('30.10.2018 17:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('30.10.2018 18:00:00','DD.MM.YYYY HH24:MI:SS')
--and event like '%TM%'
--and session_id=2313
order by sample_time;


select to_char(sample_time,'DD-MON-YYYY HH24'),COUNT(DISTINCT SESSION_ID) FROM DBA_HIST_ACTIVE_SESS_HISTORY WHERE SQL_ID='1t9tdzwmdkhvq' GROUP BY to_char(sample_time,'DD-MON-YYYY HH24');


select to_char(sample_time,'DD-MON-YYYY HH24'),COUNT(DISTINCT SESSION_ID) FROM DBA_HIST_ACTIVE_SESS_HISTORY WHERE SQL_ID='1t9tdzwmdkhvq' GROUP BY to_char(sample_time,'DD-MON-YYYY HH24') order by to_char(sample_time,'DD-MON-YYYY HH24');

SELECT TO_CHAR(sample_time,'DD-MON-YYYY HH24:MI'),
  EVENT,
  COUNT(DISTINCT SESSION_ID),
  SUM(time_waited)
FROM DBA_HIST_ACTIVE_SESS_HISTORY
WHERE SQL_ID   ='1t9tdzwmdkhvq'
AND sample_time>to_date('30.10.2018 17:00:00','DD.MM.YYYY HH24:MI:SS')
AND sample_time<to_date('30.10.2018 18:00:00','DD.MM.YYYY HH24:MI:SS')
GROUP BY TO_CHAR(sample_time,'DD-MON-YYYY HH24:MI') ,
  EVENT
ORDER BY TO_CHAR(sample_time,'DD-MON-YYYY HH24:MI'),
  EVENT;


col program format a35
col sample_time format a30
select instance_number,session_id,blocking_session,sql_id,program,event,time_waited,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 458595820
 and sample_time>to_date('22.11.2018 09:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('22.11.2018 09:45:00','DD.MM.YYYY HH24:MI:SS')
and time_waited>1000000
and instance_number=3
order by sample_time;


############# Blocker 5066

set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session,sql_id,time_waited,event,p1,p2,p3,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 458595820
 and sample_time>to_date('22.11.2018 09:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('22.11.2018 09:45:00','DD.MM.YYYY HH24:MI:SS')
--  and event like 'library cache lock'
--and blocking_session=413
and instance_number=3
and session_id=5066
order by sample_time;

############ Blocker 4705

set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session,sql_id,time_waited,event,p1,p2,p3,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 458595820
 and sample_time>to_date('22.11.2018 09:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('22.11.2018 09:45:00','DD.MM.YYYY HH24:MI:SS')
--  and event like 'library cache lock'
--and blocking_session=413
and instance_number=3
and session_id=4705
order by sample_time;


############ Blocker 2230

set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session,sql_id,time_waited,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 458595820
 and sample_time>to_date('22.11.2018 09:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('22.11.2018 09:45:00','DD.MM.YYYY HH24:MI:SS')
--and event like 'library cache lock'
--and blocking_session=413
and instance_number=4
and session_id=2230
order by sample_time;


set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session,sql_id,time_waited,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 458595820
 and sample_time>to_date('22.11.2018 09:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('22.11.2018 09:45:00','DD.MM.YYYY HH24:MI:SS')
--and event like 'library cache lock'
--and blocking_session=413
and instance_number=4
and session_id=173
order by sample_time;

select * from table(DBMS_XPLAN.DISPLAY_AWR(sql_id=>'gdyw863dq9ny1', db_id=>458595820));

SELECT SQL_ID FROM DBA_HIST_ACTIVE_SESS_HISTORY WHERE  dbid = 458595820
 and sample_time>to_date('22.11.2018 09:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('22.11.2018 09:45:00','DD.MM.YYYY HH24:MI:SS')
 AND SQL_ID IN
(SELECT SQL_ID FROM DBA_HIST_SQLTEXT WHERE (UPPER(SQL_TEXT) LIKE '%STATS%' OR UPPER(SQL_TEXT) LIKE '%ALTER%') AND dbid = 458595820);



SELECT SQL.SQL_ID,SQL_TEXT,HIS.SAMPLE_TIME FROM DBA_HIST_ACTIVE_SESS_HISTORY HIS, DBA_HIST_SQLTEXT SQL
 WHERE  SQL.dbid = 458595820 AND HIS.dbid=458595820
 and HIS.sample_time>to_date('22.11.2018 08:30:00','DD.MM.YYYY HH24:MI:SS') and  HIS.sample_time<to_date('22.11.2018 10:45:00','DD.MM.YYYY HH24:MI:SS')
 and HIS.SQL_ID=SQL.SQL_ID
 AND HIS.DBID=SQL.DBID
 AND (UPPER(SQL.SQL_TEXT) LIKE '%STATS%' OR UPPER(SQL.SQL_TEXT) LIKE '%ALTER%')
 AND HIS.INSTANCE_NUMBER=1
 ORDER BY HIS.SAMPLE_TIME;
 
 
set linesize 300
col program format a35
col sample_time format a30
col event for a40
col module for a30
col machine for a15
col program for a70
select instance_number,session_id,sql_id,sample_time,program,module, machine,pga_allocated
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 458595820
 --and sample_time>to_date('20.11.2018 17:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('20.11.2018 17:30:00','DD.MM.YYYY HH24:MI:SS')
--and event like 'library cache lock'
--and blocking_session=413
and instance_number=4
and sql_id='3cygvchg76j8k'
order by sample_time; 


set linesize 300
col program format a35
col sample_time format a30
col event for a40
col module for a40
col machine for a15
col program for a60
select instance_number,session_id,sql_id,sample_time,program,module, machine,pga_allocated
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3200312395
 and sample_time>to_date('23.09.2018 05:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('23.09.2021 06:00:00','DD.MM.YYYY HH24:MI:SS')
and pga_allocated>1000000000
and instance_number=1
order by sample_time; 

select to_char(sum(pga_allocated)) from DBA_HIST_ACTIVE_SESS_HISTORY where sample_time='20-NOV-18 05.15.03.421 PM';



set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session, BLOCKING_INST_ID,sql_id,time_waited,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 917365661
 and sample_time>to_date('07.12.2018 07:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('07.12.2018 07:50:00','DD.MM.YYYY HH24:MI:SS')
--and event like 'library cache lock'
--and blocking_session=413
and instance_number=2
order by sample_time;


set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session, BLOCKING_INST_ID,sql_id,time_waited,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 917365661
 and sample_time>to_date('07.12.2018 07:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('07.12.2018 07:50:00','DD.MM.YYYY HH24:MI:SS')
--and event like 'library cache lock'
and session_id=1895
and instance_number=2
order by sample_time;


set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session, BLOCKING_INST_ID,sql_id,time_waited,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 917365661
 and sample_time>to_date('07.12.2018 06:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('07.12.2018 07:50:00','DD.MM.YYYY HH24:MI:SS')
 and upper(sql_id) like '%ALTER%'
order by sample_time;

col ccwait_delta_tc format a20
col elapsed_time_delta_tc format a15
col buffer_gets_delta_tc format a10
select
--	s.instance_number,
  to_char(s.begin_interval_time,'DD.MM.YYYY HH24:MI:SS') "Date",  
--  sql.sql_id               ,   
  sql.plan_hash_value			 ,
  sql.executions_delta     ,
  to_char(sql.elapsed_time_delta)   elapsed_time_delta_tc,
  to_char(sql.buffer_gets_delta)    buffer_gets_delta_tc,
   trunc(sql.buffer_gets_delta/sql.executions_delta) "Gets/Exec",
   trunc(sql.disk_reads_delta/sql.executions_delta) "Reads/Exec",
   trunc(sql.rows_processed_delta/sql.executions_delta) "Rows/Exec",
  sharable_mem,
--   sql.disk_reads_delta     ,
--  sql.iowait_delta         ,
--  sql.apwait_delta         ,
--  sql.clwait_delta				 ,
--  to_char(sql.ccwait_delta) ccwait_delta_tc,
  sql.cpu_time_delta			 
--  sql.invalidations_delta  ,
--  sql.loads_delta					 ,
--  sql.version_count				 ,
--  sql.parse_calls_delta
from
   dba_hist_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and s.dbid=sql.dbid
   and s.instance_number=sql.instance_number
--   and s.dbid=917365661
--   and s.begin_interval_time > to_date('07.10.2018 06:30:00','DD.MM.YYYY HH24:MI:SS')
--     and s.begin_interval_time < to_date('10.08.2022 00:00:00','DD.MM.YYYY HH24:MI:SS')
   and sql.sql_id='3kdmd5kzwzp0v'
order by begin_interval_time
;

select * from table(DBMS_XPLAN.DISPLAY_AWR(sql_id=>'apjmmk9puqt6p'));

SET LONG 10000
select dbms_metadata.get_ddl('INDEX','IX_TINBOXTASKS_CSTATE','SEEDB') from dual;
select dbms_metadata.get_ddl('INDEX','PK_TINBOXTASKS','SEEDB') from dual;


SELECT INSTANCE_NUMBER
 ----------------------------------------------------- -------- ------------------------------------
 SNAP_ID                                               NOT NULL NUMBER
 DBID                                                  NOT NULL NUMBER
 INSTANCE_NUMBER                                       NOT NULL NUMBER
 SQL_ID                                                NOT NULL VARCHAR2(13)
 PLAN_HASH_VALUE                                       NOT NULL NUMBER
 OPTIMIZER_COST                                                 NUMBER
 OPTIMIZER_MODE                                                 VARCHAR2(10)
 OPTIMIZER_ENV_HASH_VALUE                                       NUMBER
 SHARABLE_MEM                                                   NUMBER
 LOADED_VERSIONS                                                NUMBER
 VERSION_COUNT                                                  NUMBER
 MODULE                                                         VARCHAR2(64)
 ACTION                                                         VARCHAR2(64)
 SQL_PROFILE                                                    VARCHAR2(64)
 FORCE_MATCHING_SIGNATURE                                       NUMBER
 PARSING_SCHEMA_ID                                              NUMBER
 PARSING_SCHEMA_NAME                                            VARCHAR2(128)
 PARSING_USER_ID                                                NUMBER
 FETCHES_TOTAL                                                  NUMBER
 FETCHES_DELTA                                                  NUMBER
 END_OF_FETCH_COUNT_TOTAL                                       NUMBER
 END_OF_FETCH_COUNT_DELTA                                       NUMBER
 SORTS_TOTAL                                                    NUMBER
 SORTS_DELTA                                                    NUMBER
 EXECUTIONS_TOTAL                                               NUMBER
 EXECUTIONS_DELTA                                               NUMBER
 PX_SERVERS_EXECS_TOTAL                                         NUMBER
 PX_SERVERS_EXECS_DELTA                                         NUMBER
 LOADS_TOTAL                                                    NUMBER
 LOADS_DELTA                                                    NUMBER
 INVALIDATIONS_TOTAL                                            NUMBER
 INVALIDATIONS_DELTA                                            NUMBER
 PARSE_CALLS_TOTAL                                              NUMBER
 PARSE_CALLS_DELTA                                              NUMBER
 DISK_READS_TOTAL                                               NUMBER
 DISK_READS_DELTA                                               NUMBER
 BUFFER_GETS_TOTAL                                              NUMBER
 BUFFER_GETS_DELTA                                              NUMBER
 ROWS_PROCESSED_TOTAL                                           NUMBER
 ROWS_PROCESSED_DELTA                                           NUMBER
 CPU_TIME_TOTAL                                                 NUMBER
 CPU_TIME_DELTA                                                 NUMBER
 ELAPSED_TIME_TOTAL                                             NUMBER
 ELAPSED_TIME_DELTA                                             NUMBER
 IOWAIT_TOTAL                                                   NUMBER
 IOWAIT_DELTA                                                   NUMBER
 CLWAIT_TOTAL                                                   NUMBER
 CLWAIT_DELTA                                                   NUMBER
 APWAIT_TOTAL                                                   NUMBER
 APWAIT_DELTA                                                   NUMBER
 CCWAIT_TOTAL                                                   NUMBER
 CCWAIT_DELTA                                                   NUMBER
 DIRECT_WRITES_TOTAL                                            NUMBER
 DIRECT_WRITES_DELTA                                            NUMBER
 PLSEXEC_TIME_TOTAL                                             NUMBER
 PLSEXEC_TIME_DELTA                                             NUMBER
 JAVEXEC_TIME_TOTAL                                             NUMBER
 JAVEXEC_TIME_DELTA                                             NUMBER
 IO_OFFLOAD_ELIG_BYTES_TOTAL                                    NUMBER
 IO_OFFLOAD_ELIG_BYTES_DELTA                                    NUMBER
 IO_INTERCONNECT_BYTES_TOTAL                                    NUMBER
 IO_INTERCONNECT_BYTES_DELTA                                    NUMBER
 PHYSICAL_READ_REQUESTS_TOTAL                                   NUMBER
 PHYSICAL_READ_REQUESTS_DELTA                                   NUMBER
 PHYSICAL_READ_BYTES_TOTAL                                      NUMBER
 PHYSICAL_READ_BYTES_DELTA                                      NUMBER
 PHYSICAL_WRITE_REQUESTS_TOTAL                                  NUMBER
 PHYSICAL_WRITE_REQUESTS_DELTA                                  NUMBER
 PHYSICAL_WRITE_BYTES_TOTAL                                     NUMBER
 PHYSICAL_WRITE_BYTES_DELTA                                     NUMBER
 OPTIMIZED_PHYSICAL_READS_TOTAL                                 NUMBER
 OPTIMIZED_PHYSICAL_READS_DELTA                                 NUMBER
 CELL_UNCOMPRESSED_BYTES_TOTAL                                  NUMBER
 CELL_UNCOMPRESSED_BYTES_DELTA                                  NUMBER
 IO_OFFLOAD_RETURN_BYTES_TOTAL                                  NUMBER
 IO_OFFLOAD_RETURN_BYTES_DELTA                                  NUMBER
 BIND_DATA                                                      RAW(2000)
 FLAG                                                           NUMBER
 CON_DBID                                                       NUMBER
 CON_ID                                                         NUMBER

set linesize 300
col program format a35
col sample_time format a30
col event for a40
select instance_number,session_id,blocking_session, BLOCKING_INST_ID,sql_id,time_waited,event,sample_time,program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 658104099
 and sample_time>to_date('13.12.2018 11:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('13.12.2018 11:10:00','DD.MM.YYYY HH24:MI:SS')
--and event like 'library cache lock'
and session_id=182
and instance_number=1
order by sample_time;

select * from table(DBMS_XPLAN.DISPLAY_AWR(sql_id=>'9d7s994fk7nyn',db_id=>1279924695));


set linesize 300
col program format a35
col sample_time format a30
col event for a40
select 
--instance_number,
session_id,
blocking_session, 
--BLOCKING_INST_ID,
sql_id,
time_waited,
event,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1279924695
 and sample_time>to_date('07.12.2018 01:40:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('07.12.2018 02:10:00','DD.MM.YYYY HH24:MI:SS')
--and event like 'library cache lock'
--and session_id=182
--and instance_number=1
--and program like '%TNS%'
order by sample_time;

set linesize 300
col program format a35
col sample_time format a30
col event for a40
col module for a30
col machine for a15
col program for a30
select blocking_session,session_id,sql_id,sample_time,program,module,time_waited
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1257217287
 and sample_time>to_date('07.01.2019 03:45:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('07.01.2019 04:15:00','DD.MM.YYYY HH24:MI:SS')
 and blocking_session>0
  and event like 'enq: TM%'
--and session_id=2741
--and blocking_session=413
--and instance_number=4
--and sql_id='3cygvchg76j8k'
order by sample_time; 

set linesize 300
col program format a35
col sample_time format a30
col event for a40
col module for a30
col machine for a15
col program for a30
select blocking_session,session_id,sql_id,sample_time,program,module,time_waited,event
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2566746526
-- and sample_time>to_date('07.01.2019 03:45:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('07.01.2019 04:15:00','DD.MM.YYYY HH24:MI:SS')
-- and blocking_session>0
--  and event like 'enq: TM%'
--  and session_id=1169
--and blocking_session=413
--and instance_number=4
  and sql_id='c3mj0jr2mskxa'
order by sample_time; 

select sql_id,sql_text from dba_hist_sqltext where sql_id='4ppvqzbc6795m';

SET LINESIZE 250
SET PAGESIZE 560
col ccwait_delta_tc format a20
col elapsed_time_delta_us format a15
col buffer_gets_delta_tc format a10
col sql_profile format a20
select
--	s.instance_number,
  to_char(s.begin_interval_time,'DD.MM.YYYY HH24:MI:SS') "Date",  
--  sql.sql_id               ,   
  sql.plan_hash_value			 ,
--  sql.sql_profile					,
  sql.executions_delta     ,
  to_char(sql.elapsed_time_delta)   elapsed_time_delta_us,
  to_char(sql.buffer_gets_delta)    buffer_gets_delta_tc,
  --sql.rows_processed_delta ,
  trunc(sql.elapsed_time_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta)) "Time/Exec us",
  trunc(sql.buffer_gets_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta)) "Gets/Exec",
  trunc(sql.disk_reads_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta)) "Reads/Exec",  
  trunc( sql.rows_processed_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta)) "Rows/Exec"
--  sql.disk_reads_delta     ,
--  sql.iowait_delta         ,
--  sql.apwait_delta         ,
--  sql.clwait_delta				 ,
--  to_char(sql.ccwait_delta) ccwait_delta_tc,
--  sql.cpu_time_delta,			 
--  sql.invalidations_delta  ,
--  sql.loads_delta					 ,
--  sql.version_count				 ,
--  sql.sharable_mem				 ,
--  sql.parse_calls_delta
from
   dba_hist_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and s.dbid=sql.dbid
   and s.instance_number=sql.instance_number
--   and s.dbid=917365661
--   and s.begin_interval_time > to_date('24.12.2018 06:30:00','DD.MM.YYYY HH24:MI:SS')
--   and s.begin_interval_time < to_date('29.12.2018 08:30:00','DD.MM.YYYY HH24:MI:SS')
   and sql.sql_id='7n5wpg9f09yzm'
--   and sql.plan_hash_value=3595615926
   and sql.executions_delta>0
order by begin_interval_time
;

SET LINESIZE 250
SET PAGESIZE 560
col ccwait_delta_tc format a20
col elapsed_time_delta_us format a15
col buffer_gets_delta_tc format a10
col sql_profile format a20
select
--	s.instance_number,
  to_char(s.begin_interval_time,'DD.MM.YYYY HH24:MI:SS') "Date",  
--  sql.sql_id               ,   
  sql.plan_hash_value			 ,
  sql.sql_profile					,
  sql.executions_delta     ,
  to_char(sql.elapsed_time_delta)   elapsed_time_delta_us,
  to_char(sql.buffer_gets_delta)    buffer_gets_delta_tc,
--  sql.rows_processed_delta ,
  trunc(sql.buffer_gets_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta)) "Gets/Exec",
  trunc(sql.elapsed_time_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta)) "Time/Exec us",
--  sql.disk_reads_delta     ,
--  sql.iowait_delta         ,
--  sql.apwait_delta         ,
--  sql.clwait_delta				 ,
  to_char(sql.ccwait_delta) ccwait_delta_tc,
  sql.cpu_time_delta,			 
  sql.invalidations_delta  ,
  sql.loads_delta					 ,
  sql.version_count				 ,
  sql.sharable_mem				 ,
  sql.parse_calls_delta
from
   dba_hist_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and s.dbid=sql.dbid
   and s.instance_number=sql.instance_number
--   and s.dbid=917365661
--   and s.begin_interval_time > to_date('24.12.2018 06:30:00','DD.MM.YYYY HH24:MI:SS')
--   and s.begin_interval_time < to_date('29.12.2018 08:30:00','DD.MM.YYYY HH24:MI:SS')
   and sql.sql_id='3cygvchg76j8k'
   and sql.plan_hash_value=1947186686
   and sql.executions_delta>0
order by begin_interval_time
;


SET LINESIZE 250
SET PAGESIZE 560
col ccwait_delta_tc format a20
col elapsed_time_delta_us format a15
col buffer_gets_delta_tc format a10
col sql_profile format a20
select
--	s.instance_number,
  to_char(s.begin_interval_time,'DD.MM.YYYY HH24:MI:SS') "Date",  
  sql.sql_id               ,   
  sql.plan_hash_value			 ,
  sql.sql_profile					,
  sql.executions_delta     ,
  to_char(sql.elapsed_time_delta)   elapsed_time_delta_us,
--  to_char(sql.buffer_gets_delta)    buffer_gets_delta_tc,
--  sql.rows_processed_delta ,
--  trunc(sql.buffer_gets_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta)) "Gets/Exec",
  trunc(sql.elapsed_time_delta/DECODE(sql.executions_delta,0,1,sql.executions_delta)) "Time/Exec us",
--  sql.disk_reads_delta     ,
--  sql.iowait_delta         ,
--  sql.apwait_delta         ,
--  sql.clwait_delta				 ,
--  to_char(sql.ccwait_delta) ccwait_delta_tc,
--  sql.cpu_time_delta,			 
  sql.invalidations_delta  ,
  sql.loads_delta					 ,
  sql.version_count				 ,
  sql.sharable_mem				 ,
  sql.parse_calls_delta
from
   dba_hist_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and s.dbid=sql.dbid
   and s.instance_number=sql.instance_number
--   and s.dbid=917365661
   and s.begin_interval_time > to_date('17.12.2018 06:00:00','DD.MM.YYYY HH24:MI:SS')
--   and s.begin_interval_time < to_date('29.12.2018 08:30:00','DD.MM.YYYY HH24:MI:SS')
--   and sql.sql_id='3cygvchg76j8k'
--   and sql.plan_hash_value=1947186686
--   and sql.executions_delta>0
	 and sql.invalidations_delta>0
order by begin_interval_time
;




SET LINESIZE 250
SET PAGESIZE 560
col ccwait_delta_tc format a20
col elapsed_time_delta_us format a15
col buffer_gets_delta_tc format a10
col sql_profile format a20
select
--	s.instance_number,
  sql.sql_id               ,   
  sum(sql.executions_delta)     ,
  sum(sql.elapsed_time_delta)   ,
  count(distinct sql.plan_hash_value)
  sql.parse_calls_delta
from
   dba_hist_sqlstat        sql,
order by   sum(sql.elapsed_time_delta) 
;


spool blockers.txt
set linesize 220
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
event,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1641084694
 and sample_time>to_date('18.04.2019 07:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('18.04.2019 10:00:00','DD.MM.YYYY HH24:MI:SS')
--and event like '%wait on X%'
--and session_id=182
--and instance_number=1
--and program like '%TNS%'
--and sql_id is not null
order by sample_time;


set linesize 300
col program format a35
col sample_time format a30
col event for a40
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
event,
sample_time,
program  
from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1641084694
 and sample_time>to_date('18.04.2019 07:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('18.04.2019 10:00:00','DD.MM.YYYY HH24:MI:SS')
--and event like 'library cache lock'
--and blocking_session=413
and instance_number=1
and session_id=2139
order by sample_time;


INSTANCE_NUMBER SESSION_ID BLOCKING_SESSION BLOCKING_INST_ID MODULE                                                           SQL_ID        TIME_WAITED EVENT                                    SAMPLE_TIME
--------------- ---------- ---------------- ---------------- ---------------------------------------------------------------- ------------- ----------- ---------------------------------------- ------------------------------
              1       1447              622                1 JDBC Thin Client                                                 9zg9qd9bm4spu           0 enq: HW - contention                     13-APR-19 08.36.25.328 PM
              1       1447              622                1 JDBC Thin Client                                                 9zg9qd9bm4spu           0 enq: HW - contention                     13-APR-19 08.36.35.358 PM
              1       1447              622                1 JDBC Thin Client                                                 9zg9qd9bm4spu           0 enq: HW - contention                     13-APR-19 08.36.45.398 PM
              1       1447              622                1 JDBC Thin Client                                                 9zg9qd9bm4spu           0 enq: HW - contention                     13-APR-19 08.36.55.418 PM
              1       1447              622                1 JDBC Thin Client                                                 9zg9qd9bm4spu           0 enq: HW - contention                     13-APR-19 08.37.05.520 PM

set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
event,
sample_time,
program  
from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1439486363
 and sample_time>to_date('13.04.2019 20:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('13.04.2019 21:00:00','DD.MM.YYYY HH24:MI:SS')
--and event like 'library cache lock'
--and blocking_session=413
and instance_number=1
and session_id=622
order by sample_time;

INSTANCE_NUMBER SESSION_ID BLOCKING_SESSION BLOCKING_INST_ID MODULE                                                           SQL_ID        TIME_WAITED EVENT                                    SAMPLE_TIME
--------------- ---------- ---------------- ---------------- ---------------------------------------------------------------- ------------- ----------- ---------------------------------------- ------------------------------
              1        622                                   JDBC Thin Client                                                 4dpqq0fkrk5f5           0                                          13-APR-19 08.30.04.277 PM
              1        622                                   JDBC Thin Client                                                 3v8r0mnhtjfg0           0                                          13-APR-19 08.31.34.483 PM
              1        622                                   JDBC Thin Client                                                 azwuxp2g7d781           0                                          13-APR-19 08.32.04.593 PM
              1        622                                   JDBC Thin Client                                                 9tuxcx3kkcvp8           0                                          13-APR-19 08.32.54.683 PM
              1        622                                   JDBC Thin Client                                                 bpfta2ppkh1rs           0                                          13-APR-19 08.33.24.789 PM
              1        622             1369                1 JDBC Thin Client                                                 a4wyt9zawggyy           0 buffer busy waits                        13-APR-19 08.36.05.278 PM
              1        622             1369                1 JDBC Thin Client                                                 a4wyt9zawggyy           0 buffer busy waits                        13-APR-19 08.36.15.298 PM
              1        622             1369                1 JDBC Thin Client                                                 a4wyt9zawggyy           0 buffer busy waits                        13-APR-19 08.36.25.328 PM
              1        622             1369                1 JDBC Thin Client                                                 a4wyt9zawggyy           0 buffer busy waits                        13-APR-19 08.36.35.358 PM
              1        622             1369                1 JDBC Thin Client                                                 a4wyt9zawggyy           0 buffer busy waits                        13-APR-19 08.36.45.398 PM
              1        622             1369                1 JDBC Thin Client                                                 a4wyt9zawggyy           0 buffer busy waits                        13-APR-19 08.36.55.418 PM
              1        622             1369                1 JDBC Thin Client                                                 a4wyt9zawggyy  2980969381 buffer busy waits                        13-APR-19 08.37.05.520 PM

set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col module for a20

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
time_waited,
event,
sample_time,
program  
from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3663774426
-- and sample_time>to_date('13.04.2019 20:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('13.04.2019 21:00:00','DD.MM.YYYY HH24:MI:SS')
--and event like '%TM%'
--and blocking_session=413
--and instance_number=1
and session_id=144
order by sample_time;

set linesize 250
set pagesize 500
select * from table(DBMS_XPLAN.DISPLAY_AWR(sql_id=>'5ubqapsf9ukuu', db_id=>3663774426));
9b90dcwda1rkg


set linesize 300
col program format a35
col sample_time format a30
col event for a40
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
time_waited,
event,
sample_time,
program  
from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1641084694
 and sample_time>to_date('18.04.2019 07:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('18.04.2019 10:00:00','DD.MM.YYYY HH24:MI:SS')
 and event like 'DFS lock handle'
--and blocking_session=413
--and instance_number=1
--and session_id=2139
order by sample_time;


set linesize 300
col program format a35
col sample_time format a30
col event for a40
select 
--instance_number,
session_id,
--blocking_session, 
--BLOCKING_INST_ID,
--module,
sql_id,
time_waited,
event,
sample_time,
program  
from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3555817483
-- and sample_time>to_date('18.04.2019 07:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('18.04.2019 10:00:00','DD.MM.YYYY HH24:MI:SS')
 and event like 'read by other session'
--and blocking_session=413
--and instance_number=1
--and session_id=2139
order by sample_time;




set linesize 220
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
event,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 715284169
-- and sample_time>to_date('23.04.2019 16:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('23.04.2019 17:00:00','DD.MM.YYYY HH24:MI:SS')
--and event like '%wait on X%'
--and session_id=182
--and instance_number=1
--and program like '%TNS%'
and sql_id='gvxxnbc4k8vrz'
order by sample_time;


set linesize 220
set pagesize 1000
col sample_time format a30
col event for a40
col program format a60
col module format a50
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
event,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 4117509769
-- and sample_time>to_date('23.04.2019 16:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('23.04.2019 17:00:00','DD.MM.YYYY HH24:MI:SS')
and event like '%undo%'
--and session_id=1151
--and instance_number=2
--and program like '%TNS%'
--and sql_id is not null
---order by sample_time
--and sql_id is not null
order by sql_id;

select * from table(DBMS_XPLAN.DISPLAY_AWR(sql_id=>'ggrjdrk97tm07', db_id=>4117509769));



set linesize 220
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
event,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2907843984
  and sample_time>to_date('13.05.2019 11:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('13.05.2019 12:00:00','DD.MM.YYYY HH24:MI:SS')
--and event like '%wait on X%'
and session_id=3416
and instance_number=1
--and program like '%TNS%'
--sql_id='0kugqg48477gf '
order by sample_time;


JN BH
--order by sql_id;


set linesize 220
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
event,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1231731908
 and sample_time>to_date('02.06.2019 07:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('02.06.2019 07:30:00','DD.MM.YYYY HH24:MI:SS')
--and event like '%wait on X%'
--and session_id=182
--and instance_number=1
--and program like '%TNS%'
--and sql_id='0qzw83q1njanu'
order by sample_time;

set linesize 220
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
event,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1899791176
--  and sample_time>to_date('27.06.2019 05:30:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('27.06.2019 06:00:00','DD.MM.YYYY HH24:MI:SS')
  and event like '%TM%'
--  and session_id=981
--and instance_number=1
--and program like '%TNS%'
--and sql_id='0qzw83q1njanu'
--order by sample_time
--and module = 'SQL*Plus'
order by sql_id;

set linesize 220
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
wait_time,
event,
--p1,p2,p3,
current_obj#,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3099439777
  and sample_time>to_date('21.08.2019 18:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('21.08.2019 18:30:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%TX%'
--  and session_id=40
--  and instance_number=3
--and program like '%TNS%'
--and sql_id='0qzw83q1njanu'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;


set linesize 220
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
program,
module,
sql_id,
time_waited,
wait_time,
event,
--p1,p2,p3,
current_obj#,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3099439777
  and sample_time>to_date('21.08.2019 18:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('21.08.2019 18:30:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%TX%'
  and session_id=6016
  and instance_number=2
--and program like '%TNS%'
--and sql_id='0qzw83q1njanu'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;

select * from table(DBMS_XPLAN.DISPLAY_AWR(sql_id=>'at1h2hj7jntzp', db_id=>1118034726));

set linesize 220
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
wait_time,
event,
--p1,p2,p3,
--current_obj#,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1586336247
  and sample_time>to_date('15.11.2019 13:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('15.11.2019 13:15:00','DD.MM.YYYY HH24:MI:SS')
-- and sample_time>to_date('01.11.2019 16:15:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%library cache lock%'
--  and session_id=1222
--  and instance_number=2
--and program like '%TNS%'
--and sql_id='at1h2hj7jntzp'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;
--order by sql_id;


set linesize 220
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
wait_time,
event,
--p1,p2,p3,
--current_obj#,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1586336247
  and sample_time>to_date('15.11.2019 13:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('15.11.2019 13:15:00','DD.MM.YYYY HH24:MI:SS')
-- and sample_time>to_date('01.11.2019 16:15:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%library cache lock%'
  and session_id=2067
--  and instance_number=2
--and program like '%TNS%'
--and sql_id='at1h2hj7jntzp'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;
--order by sql_id;

select * from table(DBMS_XPLAN.DISPLAY_AWR(sql_id=>'gka20t347vbn4', db_id=>1586336247));

select sql_text from dba_hist_sqltext where sql_id='gkrfz18kh6vwt';

set linesize 220
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
select  sql_id,sql_text from dba_hist_sqltext where sql_id in (
select /*+ NO_UNNEST */ distinct
sql_id
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1586336247
  and sample_time>to_date('15.11.2019 13:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('15.11.2019 13:15:00','DD.MM.YYYY HH24:MI:SS')
  and event like '%pin S wait on X%'
  and session_id=2067
--  and instance_number=2
--and program like '%TNS%'
--and sql_id='0qzw83q1njanu'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
);


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format a20

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
wait_time,
event,
to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 168145168
--  and sample_time>=to_date('30.11.2019 11:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('30.11.2019 12:00:00','DD.MM.YYYY HH24:MI:SS')
  and sample_time>=to_date('24.11.2019 00:00:00','DD.MM.YYYY HH24:MI:SS')
  and event like '%cursor:%'
--  and session_id=2067
--  and instance_number=2
--and program like '%TNS%'
--and sql_id='at1h2hj7jntzp'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;
--order by sql_id;

select * from table(DBMS_XPLAN.DISPLAY_AWR(sql_id=>'36rgarkhtjt13', db_id=>168145168));
select plan_table_output from table(DBMS_XPLAN.DISPLAY_WORKLOAD_REPOSITORY(sql_id=>'60xdfs3vj9737', dbid=>2591885155, con_dbid=>0));
select sql_text from dba_hist_sqltext where sql_id='60xdfs3vj9737';

set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format a20

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
module,
sql_id,
time_waited,
wait_time,
event,
to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3663774426
--   and sample_time>=to_date('11.11.2019 23:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('12.11.2019 03:00:00','DD.MM.YYYY HH24:MI:SS')
  and sample_time>=to_date('25.11.2019 00:00:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%TX%'
  and session_id=658
--  and instance_number=2
--and program like '%TNS%'
--and sql_id='at1h2hj7jntzp'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;
--order by sql_id;




set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format a20

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
--sql_id,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3602297620
  and sample_time>=to_date('30.11.2019 11:40:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('30.11.2019 11:50:00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time>=to_date('25.11.2019 00:00:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%TX%'
--  and session_id=3350
--  and instance_number=2
--and program like '%TNS%'
--and sql_id='at1h2hj7jntzp'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format a20
col p1 format a15

select 
instance_number,
session_id,
--blocking_session, 
--BLOCKING_INST_ID,
--module,
sql_id,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
RAWTOHEX(UTL_RAW.CAST_TO_RAW(p1)) p1,
current_obj#,
sample_time
--program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3663774426
  and sample_time>=to_date('02.12.2019 09:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('02.12.2019 18:00:00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time>=to_date('03.12.2019 08:00:00','DD.MM.YYYY HH24:MI:SS')
  and event like '%TX%'
--  and session_id=3350
--  and instance_number=2
--and program like '%TNS%'
--and sql_id='at1h2hj7jntzp'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;

select * from table(DBMS_XPLAN.DISPLAY_AWR(sql_id=>'0h6x952bcmt5q', db_id=>3663774426));
select plan_table_output from table(DBMS_XPLAN.DISPLAY_WORKLOAD_REPOSITORY(sql_id=>'0h6x952bcmt5q', dbid=>3663774426, con_dbid=>0));
select sql_text from dba_hist_sqltext where sql_id='dfn09mfp307n9';


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
--blocking_session, 
--BLOCKING_INST_ID,
--module,
sql_id,
pga_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1457735462
 and pga_allocated>500000000
--  and sample_time>=to_date('30.11.2019 11:40:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('30.11.2019 11:50:00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time>=to_date('25.11.2019 00:00:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%TX%'
--  and session_id=3350
--  and instance_number=2
--and program like '%TNS%'
--and sql_id='at1h2hj7jntzp'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;



set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2964796170
-- and pga_allocated>500000000
--  and sample_time>=to_date('30.11.2019 11:40:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('30.11.2019 11:50:00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time>=to_date('25.11.2019 00:00:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%TX%'
--  and session_id=3350
--  and instance_number=2
--and program like '%library cache lock%'
--and sql_id='31svm3qkc9hqu'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;

set long 100000
select sql_text from dba_hist_sqltext where sql_id='3mv5qxvxsp770';




set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 4071434448
-- and pga_allocated>500000000
  and sample_time>=to_date('12.03.2020 08:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('12.03.2020 08:30:00','DD.MM.YYYY HH24:MI:SS')
  and event like '%mutex X%'
--  and session_id=3350
--  and instance_number=2
--and program like '%TNS%'
--and sql_id='31svm3qkc9hqu'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;



set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2203642984
-- and pga_allocated>500000000
--  and sample_time>=to_date('18.03.2020 08:55:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('18.03.2020 09:30:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%mutex X%'
--   and session_id=6428
--  and instance_number=2
--and program like '%TNS%'
--and sql_id='31svm3qkc9hqu'
--order by sample_time
--and module = 'SQL*Plus'
-- and   blocking_session=6428
--and blocking_inst_id=2
--and session_state='ON CPU'
order by sample_time;





set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1940930378
-- and pga_allocated>500000000
  and sample_time>=to_date('16.04.2020 14:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('16.04.2020 15:00:00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time>=to_date('25.11.2019 00:00:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%TX%'
--  and session_id=3350
--  and instance_number=2
  and event like '%TX%'
--and sql_id='31svm3qkc9hqu'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;



set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999
col time_waited for a10
col temp_space for a15

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
pga_allocated,
to_char(temp_space_allocated) temp_space,
to_char(time_waited) time_waited,
--wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2716111294
 and temp_space_allocated>500000000
-- and sample_time>=to_date('08.12.2020 14:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('08.12.2020 16:00:00','DD.MM.YYYY HH24:MI:SS')
    and sample_time>=to_date('01.01.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%TX%'
--  and session_id=4199
--  and instance_number=3
--  and event like '%TX%'
-- and sql_id='049t62r350jyh'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
and temp_space_allocated is not null
order by temp_space_allocated;




select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=278322390 
and sample_time>=to_date('31.01.2024 00:00:00','dd.mm.yyyy hh24:mi:ss')
and sample_time<=to_date('31.12.2024 23:59:59','dd.mm.yyyy hh24:mi:ss')
and event like '%TX%' 
group by sql_id order by count(*);

--   and sample_time<to_date('29.09.2022 00:00:00','dd.mm.yyyy hh24:mi:ss')

select sql_text from dba_hist_sqltext where sql_id='9gmr4bguyak4h';



set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
pga_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3967622872
-- and pga_allocated>500000000
--  and sample_time>=to_date('19.04.2021 22:00:00','DD.MM.YYYY HH24:MI:SS') 
--  and  sample_time<=to_date('01.04.2021 01:30:00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time>=to_date('25.11.2019 00:00:00','DD.MM.YYYY HH24:MI:SS')
--      and event like '%gc buffer busy%'
--    and session_id=10326
--  and instance_number=4
    and event like '%log file switch completion%'
--and sql_id='31svm3qkc9hqu'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
--module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 828566891
-- and pga_allocated>500000000
  and sample_time>=to_date('20.08.2021 10.41.35','DD.MM.YYYY HH24:MI:SS') 
-- and  sample_time<=to_date('22.07.2021 20:50:00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
    and event like '%TX%'
--     and session_id=761
--  and instance_number=2
--   and event like '%TM%'
--   and sql_id='gm8jhg6wn40n0'
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;



select 
--instance_number,
--session_id,
blocking_session, 
BLOCKING_INST_ID,
count(*)
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 778893006
-- and pga_allocated>500000000
 and sample_time>=to_date('16.12.2020 12:10:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<=to_date('16.12.2020 13:00:00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time>=to_date('25.11.2019 00:00:00','DD.MM.YYYY HH24:MI:SS')
  and event like '%TX%'
--    and session_id=2583
--  and instance_number=4
--  and event like '%TX%index%'
--and sql_id='31svm3qkc9hqu'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
group by BLOCKING_INST_ID, blocking_session
order by count(*)
;



select s.sql_id,t.sql_text,s.cnt from 
(
select 
sql_id,
count(*) cnt
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2852641260
   and event like '%TM%'
group by sql_id) s,
dba_hist_sqltext t
where s.sql_id=t.sql_id(+)
order by cnt
;





set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999



set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
--temp_space_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
--module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 4244346883
-- and pga_allocated>500000000
   and sample_time>=to_date('26.10.2021 23.00.00','DD.MM.YYYY HH24:MI:SS') 
   and  sample_time<=to_date('26.10.2021 23.15.00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--     and event like '%KGAS%'
--       and session_id=812
--  and instance_number=2
--    and event like '%gc cr request%'
--   and sql_id='gm8jhg6wn40n0'
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time ;






set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
time_waited,
wait_time,
event,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2002135682
  and sample_time>=to_date('17.09.2021 10.00.00','DD.MM.YYYY HH24:MI:SS') 
   and  sample_time<=to_date('17.09.2021 10.30.00','DD.MM.YYYY HH24:MI:SS')
      and session_id=2785
order by sample_time;


select 
instance_number,
session_id,
count(*)
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2002135682
  and sample_time>=to_date('17.09.2021 10.00.00','DD.MM.YYYY HH24:MI:SS') 
   and  sample_time<=to_date('17.09.2021 10.30.00','DD.MM.YYYY HH24:MI:SS')
--      and session_id=1518
group by instance_number,
session_id
order by count(*);


set linesize 300
set pagesize 5000
col program format a35
col sample_time format a30
col event for a40
col module for a40
col machine for a15
col program for a60
select instance_number,session_id,sql_id,sample_time,program,module, machine, to_char(pga_allocated)
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3370214106
-- and sample_time>to_date('23.09.2021 05:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('23.09.2021 06:00:00','DD.MM.YYYY HH24:MI:SS')
and pga_allocated>100000000
--and instance_number=1
--and module='JDBC Thin Client'
order by pga_allocated; 

select to_char(sum(pga_allocated)) from DBA_HIST_ACTIVE_SESS_HISTORY where sample_time='20-NOV-18 05.15.03.421 PM';


select stat.sql_id,sql_text,ROWS_PROCESSED_DELTA from 
dba_hist_sqlstat stat,
dba_hist_sqltext text
where stat.dbid=191645088 and 
text.dbid=191645088
and stat.dbid=text.dbid
and stat.sql_id=text.sql_id 
and ROWS_PROCESSED_DELTA>100 
and text.sql_id='fx0hsw2c7czv7'
--and upper(sql_text) not like 'SELECT%'
order by stat.sql_id;


set linesize 250
set pagesize 5000
col ccwait_delta_tc format a20
col elapsed_time_delta_tc format a15
col buffer_gets_delta_tc format a10
col writes_delta_tc format a15

select
--	s.instance_number,
  to_char(s.begin_interval_time,'DD.MM.YYYY HH24:MI:SS') "Date",  
  sql.sql_id               ,   
  sql.plan_hash_value			 ,
  sql.executions_delta     ,
--  to_char(sql.elapsed_time_delta)   elapsed_time_delta_tc,
	to_char(BUFFER_GETS_TOTAL) buffer_gets_total,
  to_char(sql.buffer_gets_delta)    buffer_gets_delta_tc
--  to_char(sql.PHYSICAL_WRITE_BYTES_DELTA) writes_delta_tc,
--  sql.rows_processed_delta
--  trunc(sql.buffer_gets_delta/sql.executions_delta) "Gets/Exec",
--  sharable_mem,
--  sql.disk_reads_delta     ,
--  sql.iowait_delta         ,
--  sql.apwait_delta         ,
--  sql.clwait_delta				 ,
--  to_char(sql.ccwait_delta) ccwait_delta_tc,
--  sql.cpu_time_delta			 
--  sql.invalidations_delta  ,
--  sql.loads_delta					 ,
--  sql.version_count				 ,
--  sql.parse_calls_delta
from
   dba_hist_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and s.dbid=sql.dbid
   and s.instance_number=sql.instance_number
--   and s.dbid=1227710846
--   and 	sql.plan_hash_value=1991929794
--   and s.begin_interval_time > to_date('19.10.2021 13:30:00','DD.MM.YYYY HH24:MI:SS')
--   and s.begin_interval_time < to_date('10.08.2022 00:00:00','DD.MM.YYYY HH24:MI:SS')
    and sql.sql_id='3kdmd5kzwzp0v'
order by begin_interval_time
;


set linesize 250
set pagesize 5000
col ccwait_delta_tc format a20
col elapsed_time_delta_tc format a15
col buffer_gets_delta_tc format a30
col writes_delta_tc format a15

select
--	s.instance_number,
  to_char(s.begin_interval_time,'DD.MM.YYYY HH24:MI:SS') "Date",  
  sql.sql_id               ,   
   sql.plan_hash_value			 ,
  sql.executions_delta     ,
--  to_char(sql.elapsed_time_delta)   elapsed_time_delta_tc,
	to_char(BUFFER_GETS_TOTAL) buffer_gets_total,
  to_char(sql.buffer_gets_delta)    buffer_gets_delta_tc
--  to_char(sql.PHYSICAL_WRITE_BYTES_DELTA) writes_delta_tc,
--  sql.rows_processed_delta
--  trunc(sql.buffer_gets_delta/sql.executions_delta) "Gets/Exec",
--  sharable_mem,
--  sql.disk_reads_delta     ,
--  sql.iowait_delta         ,
--  sql.apwait_delta         ,
--  sql.clwait_delta				 ,
--  to_char(sql.ccwait_delta) ccwait_delta_tc,
--  sql.cpu_time_delta			 
--  sql.invalidations_delta  ,
--  sql.loads_delta					 ,
--  sql.version_count				 ,
--  sql.parse_calls_delta
from
   wrh$_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and s.dbid=sql.dbid
   and s.instance_number=sql.instance_number
   and s.dbid=1823540864
--    and 	sql.plan_hash_value=1991929794
 --   and s.begin_interval_time > to_date('08.10.2022 00:00:00','DD.MM.YYYY HH24:MI:SS')
 --  and s.begin_interval_time < to_date('09.10.2022 00:00:00','DD.MM.YYYY HH24:MI:SS')
    and sql.sql_id='79akwuzqan94u'
order by begin_interval_time
;


select
--	s.instance_number,
	s.snap_id,
  to_char(s.begin_interval_time,'DD.MM.YYYY HH24:MI:SS') "Date"
from
   dba_hist_snapshot         s
where
   s.dbid=1227710846
   and s.begin_interval_time < to_date('10.08.2022 00:00:00','DD.MM.YYYY HH24:MI:SS')
order by begin_interval_time
;


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
--temp_space_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
--module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2141883987
-- and pga_allocated>500000000
   and sample_time>=to_date('21.12.2021 16.00.00','DD.MM.YYYY HH24:MI:SS') 
   and  sample_time<=to_date('21.12.2021 17.40.00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--     and event like '%KGAS%'
--          and session_id=1418
--  and instance_number=2
--     and event like '%log file sync%'
--   and sql_id in ('33wc2ptvdru4d','2t1q6rp2g74m6')
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--  and blocking_session=1418--
--and blocking_inst_id=3
order by sample_time;



set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
event,
session_id,
count(*)
--module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 778893006
-- and pga_allocated>500000000
--   and sample_time>=to_date('26.10.2021 23.00.00','DD.MM.YYYY HH24:MI:SS') 
--   and  sample_time<=to_date('26.10.2021 23.15.00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--     and event like '%KGAS%'
--       and session_id=7606
--  and instance_number=2
   and event like '%TX%'
--   and sql_id='gm8jhg6wn40n0'
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--and blocking_session=40
--and blocking_inst_id=3
group by event,session_id
order by count(*);






****NESTLE ****

set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
--temp_space_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
--module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1004121339
-- and pga_allocated>500000000
--   and sample_time>=to_date('21.12.2021 16.00.00','DD.MM.YYYY HH24:MI:SS') 
--   and  sample_time<=to_date('21.12.2021 17.40.00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--     and event like '%KGAS%'
--          and session_id=1418
--  and instance_number=2
     and event like '%TX%'
  and sql_id in ('42mnfdsx4b3sz')
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--  and blocking_session=1418--
--and blocking_inst_id=3
order by sample_time;


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
--temp_space_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
--module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1004121339
-- and pga_allocated>500000000
--   and sample_time>=to_date('21.12.2021 16.00.00','DD.MM.YYYY HH24:MI:SS') 
--   and  sample_time<=to_date('21.12.2021 17.40.00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--     and event like '%KGAS%'
          and session_id=1552
--  and instance_number=2
--     and event like '%TX%'
--  and sql_id in ('d9fgva0ra76kr')
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--  and blocking_session=1418--
--and blocking_inst_id=3
order by sample_time;


****NESTLE ****


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
--temp_space_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
--module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 2518646563
-- and pga_allocated>500000000
--    and sample_time>=to_date('05.03.2022 12.20.00','DD.MM.YYYY HH24:MI:SS') 
    and  sample_time<=to_date('09.03.2022 12.25.00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--     and event like '%KGAS%'
--          and session_id=1418
--  and instance_number=2
      and event like '%TM%'
--   and sql_id in ('33wc2ptvdru4d','2t1q6rp2g74m6')
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--  and blocking_session=1418--
--and blocking_inst_id=3
order by sample_time;



set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
--temp_space_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
--module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
-- where dbid = 3967622872
-- and pga_allocated>500000000
    and sample_time>=to_date('27.04.2022 22.04.00','DD.MM.YYYY HH24:MI:SS') 
    and sample_time<=to_date('27.04.2022 22.12.00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--     and event like '%TX%'
--          and session_id=4589
--  and instance_number=2
--       and event like '%MC%'
--   and sql_id in ('0q6c7ddvpq59x')
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--   and blocking_session=1924
--and blocking_inst_id=3
order by sample_time;

select sql_text from dba_hist_sqltext where sql_id='bf3p2d99gmhd0';

select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=2518646563 
--and sample_time>=to_date('10.11.2021 04:00:00','dd.mm.yyyy hh24:mi:ss')
--  and sample_time<=to_date('19.08.2021 05:00:00','dd.mm.yyyy hh24:mi:ss')
and event like '%TM%' 
group by sql_id order by count(*);

select 
sql_id,
count(*)
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 588143351
-- and pga_allocated>500000000
--  and sample_time>=to_date('30.08.2021 04.02.00','DD.MM.YYYY HH24:MI:SS') 
--   and  sample_time<=to_date('30.08.2021 04.13.00','DD.MM.YYYY HH24:MI:SS')
   and event like '%gc cr disk read%'
group by sql_id order by count(*);


select 
sql_id,P1,
count(*)
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
  where dbid = 3197758891
-- and pga_allocated>500000000
     and sample_time>=to_date('25.09.2021 00.00.00','DD.MM.YYYY HH24:MI:SS') 
--    and  sample_time<=to_date('22.09.2021 00.00.00','DD.MM.YYYY HH24:MI:SS')
   and event like '%cursor: pin S wait on X%'
group by sql_id,P1 order by count(*);


select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=842684877 
--and sample_time>=to_date('30.08.2021 04:00:00','dd.mm.yyyy hh24:mi:ss')
--   and sample_time<=to_date('04.09.2021 00:00:00','dd.mm.yyyy hh24:mi:ss')
and event like '%cursor%' or event like '%library%' or event like '%latch%'
group by sql_id order by count(*);

select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=842684877 
--and sample_time>=to_date('04.09.2021 04:00:00','dd.mm.yyyy hh24:mi:ss')  
--   and sample_time<=to_date('04.09.2021 00:00:00','dd.mm.yyyy hh24:mi:ss')
and event like '%cursor: pin S wait o n X%' 
group by sql_id order by count(*);



set linesize 300
set pagesize 5000
col program format a35
col sample_time format a30
col event for a40
col module for a40
col machine for a15
col program for a30
select instance_number,session_id,sql_id,sample_time,program,module, machine, to_char(pga_allocated)
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1310123200
-- and sample_time>to_date('23.09.2021 05:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('23.09.2021 06:00:00','DD.MM.YYYY HH24:MI:SS')
and pga_allocated>1000000000
--and instance_number=1
--and module='JDBC Thin Client'
order by pga_allocated; 

set linesize 300
set pagesize 5000
col program format a35
col sample_time format a30
col event for a40
col module for a30
col machine for a15
col program for a30
select sample_time,instance_number,session_id,sql_id,program,module, machine, to_char(pga_allocated)
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1310123200
-- and sample_time>to_date('23.09.2021 05:00:00','DD.MM.YYYY HH24:MI:SS') and  sample_time<to_date('23.09.2021 06:00:00','DD.MM.YYYY HH24:MI:SS')
--and pga_allocated>100000000
--and instance_number=1
--and module='JDBC Thin Client'
and session_id=2047
order by sample_time; 









select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=3943921809 and event like '%enq: TX%' group by sql_id order by count(*);
select module,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=3943921809 and event like '%enq: TX%' group by module order by count(*);



set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col blocker_event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
--temp_space_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
--program,
module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where 
  dbid = 3742894615
-- and pga_allocated>500000000
     and sample_time>=to_date('04.10.2022 00.00.00','DD.MM.YYYY HH24:MI:SS') 
     and sample_time<=to_date('04.10.2022 01.00.00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--     and event like '%TX%'
--          and blocking_session is not null
--  and instance_number=2
--       and event like '%MC%'
-- and 
--  sql_id in ('6a6658v9p9h6r')
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--   and blocking_session=1924
--and blocking_inst_id=3
order by sample_time;

set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col blocker_event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
--temp_space_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
--program,
module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where 
  dbid = 3742894615
-- and pga_allocated>500000000
     and sample_time>=to_date('10.10.2022 17.32.00','DD.MM.YYYY HH24:MI:SS') 
     and sample_time<=to_date('10.10.2022 18.30.00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--     and event like '%TX%'
--          and blocking_session is not null
--  and instance_number=2
        and event like '%TX%'
--  and session_id=1181
--  sql_id in ('6a6658v9p9h6r')
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--   and blocking_session=1924
--and blocking_inst_id=3
order by sample_time;



set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col blocker_event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--pga_allocated,
--temp_space_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
--program,
module
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where 
  dbid = 3742894615
-- and pga_allocated>500000000
     and sample_time>=to_date('10.10.2022 17.32.00','DD.MM.YYYY HH24:MI:SS') 
     and sample_time<=to_date('10.10.2022 18.30.00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time<=to_date('16.04.2021 00:00:00','DD.MM.YYYY HH24:MI:SS')
--     and event like '%TX%'
--          and blocking_session is not null
   and instance_number=1
--        and event like '%TX%'
   and session_id=1024
--  sql_id in ('6a6658v9p9h6r')
--order by sample_time
--  and module = 'DBMS_SCHEDULER'
--   and blocking_session=1924
--and blocking_inst_id=3
order by sample_time;

select sql_text from dba_hist_sqltext where sql_id like '2btar1sbc2vh0%';

select sql_text from dba_hist_sqltext where sql_id like '4uy7xcqpv30rj%';

ccc


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999
col time_waited for a10
col temp_space for a15

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--  pga_allocated,
--to_char(temp_space_allocated) temp_space,
--to_char(time_waited) time_waited,
--wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
   where dbid = 995537182
-- and temp_space_allocated>500000000
    and sample_time>=to_date('16.12.2022 17:56:00','DD.MM.YYYY HH24:MI:SS') 
     and sample_time<=to_date('16.12.2022 20:20:00','DD.MM.YYYY HH24:MI:SS')
--  and event like '%TX%'
--   and session_id=1597
--  and instance_number=3
   and event like '%TX%'
--  sql_id='cp64434xszza7'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
--and temp_space_allocated is not null
order by sample_time;





select b_sql_id,count(*)
from
(
select 
s.instance_number,
s.session_id,
s.blocking_session, 
s.BLOCKING_INST_ID,
--module,
s.sql_id s_sql_id,
b.sql_id b_sql_id,
--pga_allocated,
--temp_space_allocated,
s.time_waited,
s.wait_time,
s.event,
b.event blocker_event,
s.session_state,
s.sample_time,
s.program
--module
	from  DBA_HIST_ACTIVE_SESS_HISTORY s, DBA_HIST_ACTIVE_SESS_HISTORY b
	where s.dbid = b.dbid
	and s.dbid=4260534502
	and s.sample_time=b.sample_time
	and s.blocking_session=b.session_id
	and s.blocking_inst_id=b.instance_number
	and s.blocking_session is not null
 	and s.sql_id in ('2njsp1nmfsnw5')
  and s.event like 'enq: TX%'
  
)
group by b_sql_id
order by count(*);


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a43
col blocker_event for a43
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
s.instance_number,
s.session_id,
s.blocking_session, 
--s.BLOCKING_INST_ID,
--module,
s.sql_id,
b.sql_id,
--pga_allocated,
--temp_space_allocated,
to_char(s.time_waited) time_waited,
s.wait_time,
s.event,
b.event blocker_event,
s.session_state,
s.sample_time
--s.program
--module
	from  DBA_HIST_ACTIVE_SESS_HISTORY s, DBA_HIST_ACTIVE_SESS_HISTORY b
	where s.dbid = b.dbid
--	and s.dbid=1313525685
	and s.sample_time=b.sample_time
	and s.blocking_session=b.session_id
	and s.blocking_inst_id=b.instance_number
	and s.blocking_session is not null
	and s.sql_id in ('gdb4ufbvcafx1')
  and s.event like 'enq: TX%'
--  and s.sample_time>=to_date('15.12.2022 14:00:05','DD.MM.YYYY HH24:MI:SS') 
--  and s.sample_time<=to_date('15.12.2022 15:00:23','DD.MM.YYYY HH24:MI:SS')  
order by sample_time;


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999
col time_waited for a10
col temp_space for a15

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--  pga_allocated,
--to_char(temp_space_allocated) temp_space,
event,
 to_char(time_waited) time_waited,
wait_time,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
   where dbid = 1852162449
-- and temp_space_allocated>500000000
--  and s.sample_time>=to_date('15.12.2022 14:00:05','DD.MM.YYYY HH24:MI:SS') 
--  and s.sample_time<=to_date('15.12.2022 15:00:23','DD.MM.YYYY HH24:MI:SS')  
   and event like '%gc current block lost%'
--       and session_id=2909
--  and instance_number=3
--   and event like '%TX%'
--  sql_id='cp64434xszza7'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
--and temp_space_allocated is not null
order by sample_time;

Interval: 15.12.2022 14:00:05-15.12.2022 15:00:23 Executions: 47 Total Execution Time: 23980.680403 s. Plan Hash Value: 3173109115. AVERAGES: Execution Time: 510.2272. Buffer Gets: 19. Disk reads: 0. CPU Time: .0439. Processed Rows: .21



select sql_text from dba_hist_sqltext where sql_id='b8n4dcp3cparh';


set linesize 250
set pagesize 5000
col ccwait_delta_tc format a20
col elapsed_time_delta_tc format a15
col buffer_gets_delta_tc format a10
col writes_delta_tc format a15

select
--	s.instance_number,
  to_char(s.begin_interval_time,'DD.MM.YYYY HH24:MI:SS') "Date",  
  sql.sql_id               ,   
  sql.plan_hash_value			 ,
  sql.executions_delta     ,
  to_char(sql.elapsed_time_delta)   elapsed_time_delta_tc,
	to_char(BUFFER_GETS_TOTAL) buffer_gets_total,
  to_char(sql.buffer_gets_delta)    buffer_gets_delta_tc,
--  to_char(sql.PHYSICAL_WRITE_BYTES_DELTA) writes_delta_tc,
  sql.rows_processed_delta
--  trunc(sql.buffer_gets_delta/sql.executions_delta) "Gets/Exec",
--  sharable_mem,
--  sql.disk_reads_delta     ,
--  sql.iowait_delta         ,
--  sql.apwait_delta         ,
--  sql.clwait_delta				 ,
--  to_char(sql.ccwait_delta) ccwait_delta_tc,
--  sql.cpu_time_delta			 
--  sql.invalidations_delta  ,
--  sql.loads_delta					 ,
--  sql.version_count				 ,
--  sql.parse_calls_delta
from
   dba_hist_sqlstat        sql,
   dba_hist_snapshot         s
where
   s.snap_id = sql.snap_id
   and s.dbid=sql.dbid
   and s.instance_number=sql.instance_number
--   and s.dbid=2955606475
--   and 	sql.plan_hash_value=1991929794
--   and s.begin_interval_time > to_date('19.10.2021 13:30:00','DD.MM.YYYY HH24:MI:SS')
--   and s.begin_interval_time < to_date('10.08.2022 00:00:00','DD.MM.YYYY HH24:MI:SS')
    and sql.sql_id='a7hffhn4wj3sr'
order by begin_interval_time
;


select trunc(sample_time),sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where
 -- sample_time>=to_date('30.05.2023 00:00:00','dd.mm.yyyy hh24:mi:ss')  
 --   and sample_time<=to_date('31.05.2023 11:00:00','dd.mm.yyyy hh24:mi:ss')
 event like '%cursor: pin S%' 
group by trunc(sample_time),sql_id order by count(*);





set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999
col time_waited for a10
col temp_space for a15

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--  pga_allocated,
--to_char(temp_space_allocated) temp_space,
event,
 to_char(time_waited) time_waited,
wait_time,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
   where 
  dbid = 3967622872
-- and temp_space_allocated>500000000
  and s.sample_time>=to_date('26.09.2023 10:45:05','DD.MM.YYYY HH24:MI:SS') 
    and s.sample_time<=to_date('26.09.2023 10:55:05','DD.MM.YYYY HH24:MI:SS') 
--   and event like '%gc cr block lost%'
--         and session_id=768
--   and instance_number=1
--    and event like '%cursor: pin S%'
--  sql_id='cp64434xszza7'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
--and temp_space_allocated is not null
order by sample_time;


select sql_text from dba_hist_sqltext where sql_id='b7naky81x7h53';
select sql_id,sql_text from dba_hist_sqltext where sql_id like '1fz%';



select module,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=1602968198 and event like '%RS%' group by module order by count(*);

select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=2852641260 and event like '%TX%' group by sql_id order by count(*);

select s.session_id,s.sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY s where s.dbid=2852641260  
  and s.sample_time>=to_date('26.09.2023 14:00:05','DD.MM.YYYY HH24:MI:SS') 
   and s.sample_time<=to_date('26.09.2023 15:00:00','DD.MM.YYYY HH24:MI:SS')
   group by s.session_id,s.sql_id
   order by count(*);

select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=1118034726 and event like '%latch: enqueue hash chains%' group by sql_id order by count(*);


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
pga_allocated,
time_waited,
wait_time,
event,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 3967622872
-- and pga_allocated>500000000
--  and sample_time>=to_date('19.04.2021 22:00:00','DD.MM.YYYY HH24:MI:SS') 
--  and  sample_time<=to_date('01.04.2021 01:30:00','DD.MM.YYYY HH24:MI:SS')
--  and sample_time>=to_date('25.11.2019 00:00:00','DD.MM.YYYY HH24:MI:SS')
--      and event like '%gc buffer busy%'
    and session_id=9355
--  and instance_number=4
--    and event like '%log file switch completion%'
--and sql_id='31svm3qkc9hqu'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
order by sample_time;


set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999
col time_waited for a10
col temp_space for a15

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--  pga_allocated,
--to_char(temp_space_allocated) temp_space,
event,
 to_char(time_waited) time_waited,
wait_time,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
   where 
  dbid = 3124639888
-- and temp_space_allocated>500000000
  and s.sample_time>=to_date('07.11.2023 21:00:05','DD.MM.YYYY HH24:MI:SS') 
    and s.sample_time<=to_date('07.11.2023 22:00:05','DD.MM.YYYY HH24:MI:SS') 
   and event like '%log file switch%'
--          and session_id=9355
--    and instance_number=1
--    and event like '%cursor: pin S%'
--  sql_id='cp64434xszza7'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
--and temp_space_allocated is not null
order by sample_time;


select event,sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=1068455562 and event like '%resmgr%' group by event,sql_id order by count(*);
..


select program,module,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=3943797976 and event like '%resmgr%' group by program,module order by count(*);
select program,module,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=3943797976 and event like '%resmgr%' and sql_id is null group by program,module order by count(*);

select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=1503659203 and event like '%db file sequen%' and sample_time>=to_date('20-11-2023','DD-MM-YYYY') group by sql_id order by count(*);

select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where dbid=1376509260 and event like '%cell list of blocks physical read%'  group by sql_id order by count(*);





set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999
col time_waited for a10
col temp_space for a15

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--  pga_allocated,
--to_char(temp_space_allocated) temp_space,
event,
 to_char(time_waited) time_waited,
wait_time,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
   where 
  dbid = 1602968198
-- and temp_space_allocated>500000000
  and s.sample_time>=to_date('19.12.2023 08:30:05','DD.MM.YYYY HH24:MI:SS') 
    and s.sample_time<=to_date('19.12.2023 08:45:05','DD.MM.YYYY HH24:MI:SS') 
      and event like '%enq%TX%'
--                  and session_id=7584
--    and instance_number=1
--    and event like '%cursor: pin S%'
--  sql_id='cp64434xszza7'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
--and temp_space_allocated is not null
order by sample_time;


select 
sql_id,
count(*)
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
 where dbid = 1118034726
-- and pga_allocated>500000000
--  and sample_time>=to_date('14.08.2021 00:00:00','DD.MM.YYYY HH24:MI:SS') 
--   and  sample_time<=to_date('26.07.2021 21:50:00','DD.MM.YYYY HH24:MI:SS')
  and event like 'library%mutex X%' 
  --and event not like 'gc%busy')
  group by sql_id
order by count(*);



set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999
col time_waited for a10
col temp_space for a15

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--  pga_allocated,
--to_char(temp_space_allocated) temp_space,
event,
 to_char(time_waited) time_waited,
wait_time,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
   where 
   dbid = 71913528
-- and temp_space_allocated>500000000
 and s.sample_time>=to_date('20.01.2024 18:20:05','DD.MM.YYYY HH24:MI:SS') 
   and s.sample_time<=to_date('20.01.2024 19:00:05','DD.MM.YYYY HH24:MI:SS') 
--      and event like '%enq%TX%'
--                     and session_id=1172
--    and instance_number=1
--    and event like '%cursor: pin S%'
-- and  sql_id='1mzxxjrvudq71'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
--and temp_space_allocated is not null
order by sample_time;





select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--  pga_allocated,
--to_char(temp_space_allocated) temp_space,
event,
 to_char(time_waited) time_waited,
wait_time,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
   where 
   dbid = 897011291
-- and temp_space_allocated>500000000
 and s.sample_time>=to_date('31.01.2024 08:15:05','DD.MM.YYYY HH24:MI:SS') 
   and s.sample_time<=to_date('15.02.2024 08:45:05','DD.MM.YYYY HH24:MI:SS') 
--      and event like '%enq%TX%'
--                     and session_id=952
--    and instance_number=1
     and event like '%TX%'
-- and  sql_id='1mzxxjrvudq71'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
--and temp_space_allocated is not null
order by sample_time;

set linesize 300
set pagesize 1000
col program format a35
col sample_time format a30
col event for a40
col program format a50
col module format a30
col pga_allocated format 99999999999
col time_waited for a10
col temp_space for a15

select 
instance_number,
session_id,
blocking_session, 
BLOCKING_INST_ID,
--module,
sql_id,
--  pga_allocated,
--to_char(temp_space_allocated) temp_space,
event,
 to_char(time_waited) time_waited,
wait_time,
--to_char(pga_allocated) pga_allocated,
--p1,p2,p3,
--current_obj#,
session_state,
sample_time,
program
  from  DBA_HIST_ACTIVE_SESS_HISTORY s
   where 
   dbid = 588143351
-- and temp_space_allocated>500000000
-- and s.sample_time>=to_date('31.01.2024 08:15:05','DD.MM.YYYY HH24:MI:SS') 
--   and s.sample_time<=to_date('15.02.2024 08:45:05','DD.MM.YYYY HH24:MI:SS') 
--      and event like '%enq%TX%'
                     and session_id=2558
--    and instance_number=1
 --     and event like '%TX%'
-- and  sql_id='1mzxxjrvudq71'
--order by sample_time
--and module = 'SQL*Plus'
--and blocking_session=40
--and blocking_inst_id=3
--and temp_space_allocated is not null
order by sample_time;

select sql_text from dba_hist_sqltext where sql_id='187c3w3mxdb4z';


2524 7y4kjjdcxn8qf

              2       4120                                   cbvpmsy8h5v9q                                          0                1273 ON CPU  21-JAN-25 05.15.58.380 PM      JDBC Thin Client
              
select sql_text from dba_hist_sqltext where sql_id like 'cbvpmsy8h5v9q';
