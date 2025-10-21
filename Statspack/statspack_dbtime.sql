
set lines 155
col dbtime for 999,999.99
col begin_timestamp for a40

spool dbtime.log

COLUMN myminid NEW_VALUE v_myminid
COLUMN mymaxid NEW_VALUE v_mymaxid

select min(snap_id) as myminid from STATS$SYS_TIME_MODEL;
select max(snap_id) as mymaxid from STATS$SYS_TIME_MODEL;

define instance_number ='&1'
define begin_snap_id ='&2'
define end_snap_id ='&3'



select * from (
  select 
    begin_snap, 
    end_snap, 
    timestamp begin_timestamp, 
    inst, 
    a / 1000000 / 60 DBtime
  from (
    select
      e.snap_id end_snap,
      lag(e.snap_id) over (order by e.snap_id) begin_snap,
      lag(s.end_interval_time) over (order by e.snap_id) timestamp,
      s.instance_number inst,
      e.value,
      nvl(e.value - lag(e.value) over (order by e.snap_id), 0) a
    from stats$sys_time_model e, stats$snapshot s,  STATS$SYSSTAT st
    where s.snap_id = e.snap_id
      and e.instance_number = s.instance_number
      and to_char(e.instance_number) like nvl('&instance_number', to_char(e.instance_number))
      and st.name = 'DB time'
	  and st.STATISTIC#=e.STAT_ID
  )
  where begin_snap between nvl('&begin_snap_id', &v_myminid) and nvl('&end_snap_id', &v_mymaxid)
    and begin_snap = end_snap - 1
  order by dbtime desc
)
where rownum < 10;
