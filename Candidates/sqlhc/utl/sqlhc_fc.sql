REM
REM $Header: 1366133.1 sqlhc_fc.sql 14th June 2024 $
REM
REM Copyright (c) 2020, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM
REM SCRIPT
REM   sqlhc_fc.sql: SQL Flash Cache Report.
REM
REM DESCRIPTION
REM   Produces a Flash Cache Report for Exadata.
REM
REM   Inputs: None
REM
REM   This script does not install any objects in the database.
REM   It does not perform any DDL commands.
REM   It can be used in Dataguard or any read-only database.
REM   A version of this script can also be downloaded from note  2991095.1
REM   called fc_monitor.sql This script can be used on Exadata only in relation
REM   to bug 36015805 
REM
REM PRE-REQUISITES
REM   1. Execute as SYS or user with DBA role or user with access
REM      to data dictionary views.
REM   2. It can only run from the Root Container. 
REM PARAMETERS
REM   None
REM
REM EXECUTION
REM   1. Called from SQLHC if this is Exadata
REM
REM NOTES
REM
Rem    MODIFIED   (MM/DD/YY)
REM    scharala   06/15/24 - Minor modifications
Rem    mpolaski   06/14/24 - Created
REM
@@?/rdbms/admin/sqlsessstart.sql
SET DEF '^' 
set TERM ON
set ECHO ON 
set AUTOP OFF 
set VER OFF 
set SERVEROUT ON SIZE 1000000;
DEF script = 'sqlhc_fc';
DEF method = 'SQLHC_FC';
DEF mos_doc = '1366133.1';
DEF doc_ver = '19.1.240s6914';
DEF doc_date = '2024/06/24';
--
--
-- please change the begin timestamp below if needed

set linesize 2200 
set pagesize 32000

spool sqlhc_fc.out
var dbid number
var bid number
var eid number
select name, dbid from v$pdbs;
begin
  :dbid := ^^dbid;
select min(snap_id), max(snap_id) into :bid, :eid
  from awr_pdb_snapshot
 where dbid = :dbid
   and end_interval_time > sysdate -7;
 end;
 /

-- 1. space usage for OLTP/DW+CC/NRW
-- 2. cell OLTP and Scan hit rates
-- 3. FC OLTP hits/misses ; Scan hits/misses
-- 4. smart IO disk read rate
-- 5. LW absorbed and LW rejections due to global limit
-- 6. DKWR stats

set pages 72 lines 512 trimspool on trim on
SET ECHO OFF 
SET FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 NUM 20 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF;
col spc_alloc format 999,990.0 heading 'AllocGB'
col spc_oltp format 990.0 heading '%OLTP_Alloc'
col spc_scan format 990.0 heading '%Scan_Alloc'
col spc_nrw format 990.0 heading '%WriteOnly_Alloc'

col fc_oltp_hits_v format 99,990.0 heading 'OLTP|Hits'
col fc_oltp_miss_v format 99,990.0 heading 'OLTP|Misses'
col fc_scan_hits_v format 999,990.0 heading 'Scan|Reads'
col fc_oltp_hit format 990.0 heading '%OLTP Hits'
col fc_scan_hit format 990.0 heading '%Scan Hits'

col fc_first_v format 99,990.0 heading 'First|Writes'
col fc_over_v format 99,990.0 heading 'Over|Writes'
col lw_land_v format 99,990.0 heading 'Large|Writes'
col lwrej_limit_v format 99,990.0 heading 'LW Rej|GLimit'
col ss_hd_v format 99,990.0 heading 'Smart|ScanHD'

col repl_oltp_succ_v format 99,990.0 heading 'OLTP|Succ'
col repl_oltp_fail_v format 99,990.0 heading 'OLTP|Fail'
col repl_scan_succ_v format 99,990.0 heading 'Scan|Succ'
col repl_scan_fail_v format 99,990.0 heading 'Scan|Fail'
col repl_main_v format 99,990.0 heading 'Main'
col repl_zero_v format 99,990.0 heading 'Zero'
col srch format 99,990.0 heading 'Avg|Srch'

col scan_avwt format 990.0 heading 'Scan'
col sbr_avwt format 990.0 heading 'SBR'
col rt_avwt format 990.0 heading 'Tmp|Read'
col wt_avwt format 990.0 heading 'Tmp|Write'
col dr_avwt format 990.0 heading 'Dir|Read'
col dw_avwt format 990.0 heading 'Dir|Write'

col wrq_v format 99,990.0 heading 'DKWR|Rq'
col arq_v format 99,990.0 heading 'Aging|Rq'
col dsrq_v format 99,990.0 heading 'DSync|Rq'
col lwrq_v format 99,990.0 heading 'LWDSync|Rq'
col dkwr_wmb format 99,990.0 heading 'DKWR|Mb'
col dkwr_aging_mb format 99,990.0 heading 'Aging|Mb'
col dkwr_datasync_mb format 99,990.0 heading 'DSync|Mb'
col dkwr_lwds_mb format 99,990.0 heading 'LWDSync|Mb'

with snapshots as
(select dbid, snap_id, max(end_interval_time) et,
        (cast(max(end_interval_time) as date) -
           cast(max(begin_interval_time) as date))*86400 ela_s
  from awr_pdb_snapshot
 where dbid = :dbid
   and snap_id between :bid and :eid
 group by dbid, snap_id),
wait_events as (
  select *
    from (
      select dbid, snap_id, event_name,
             case when snap_id > prev_snap + 1
                  then null
                  else sum(time_waited_micro)/
                       decode(sum(total_waits),0,null,sum(total_waits))/1000
              end avwt
        from (
          select dbid, instance_number, snap_id, event_name,
                 lag(snap_id) over (partition by dbid, instance_number, event_name
                                        order by snap_id) prev_snap,
                 greatest(0,
                   total_waits -
                     lag(total_waits) over
                       (partition by dbid, instance_number, event_name
                            order by snap_id)) total_waits,
                 greatest(0,
                   time_waited_micro -
                     lag(time_waited_micro) over
                       (partition by dbid, instance_number, event_name
                           order by snap_id)) time_waited_micro
            from awr_pdb_system_event
           where dbid = :dbid
             and snap_id between :bid and :eid
             and event_name in ('cell smart table scan',
                           'cell single block physical read',
                           'direct path read temp',
                           'direct path write temp',
                           'direct path read',
                           'direct path write'))
           group by dbid, snap_id, prev_snap, event_name)
  pivot(sum(avwt) avwt
    for event_name in
    ('cell smart table scan'  scan,
    'cell single block physical read' sbr,
    'direct path read temp' rt,
    'direct path write temp' wt,
    'direct path read' dr,
    'direct path write' dw))),
cell_global as (
  select s.dbid, s.snap_id,
         to_char(et,'mm/dd-hh24:mi') et,
         metric_id,
         -- remove first datapoint with large gaps in data
         case when s.snap_id > d.prev_snap + 1
              then null
              -- space usagge get current value
              when metric_id in (202,311,300,370,371,372)
              then sum(currval)
              else sum(delta_value/s.ela_s)
          end value
   from snapshots s,
    ( select dbid, snap_id, cell_hash, incarnation_num,
             lag(snap_id) over
               (partition by dbid, cell_hash, incarnation_num, metric_id
                    order by snap_id) prev_snap,
             metric_id,
             metric_value currval,
             metric_value -
               lag(metric_value) over
                 (partition by dbid, cell_hash, incarnation_num, metric_id
                      order by snap_id) delta_value
        from awr_pdb_cell_global
       where dbid = :dbid
         and snap_id between :bid and :eid
         and metric_id in (
             202, -- space -- alloc
             311, -- oltp
             300, -- cc
             370, -- mrw
             371, -- nrq
             372, -- row
             381, -- -- replacements -- dw failed
             382, -- oltp fail
             383, -- dw succ
             384, -- oltp succ
             385, -- main
             386, -- zero
             387, -- victim
             481, -- -- lw lwland
             476, -- lwrej global limit
             189, -- first writes
             190, -- overwrites
             200, -- oltp hits
             204, -- scan hits
             201, -- oltp misses
             206, -- scan bytes
             205, -- scan attempted
             242,-- smart scan on hd
             316, -- dkwr write reqs
             317, -- dkwr write bytes
             670, -- aging reqs
             671, -- aging bytes
             672, -- datasync reqs
             673, -- datasync bytes
             676, -- lwdsync reqs
             677  -- lwdsync bytes
             )) d
   where s.dbid = d.dbid
     and s.snap_id = d.snap_id
   group by s.dbid, s.snap_id, d.prev_snap, d.metric_id,
         to_char(et,'mm/dd-hh24:mi')),
global as (
    select dbid,snap_id, et,
           -- calculate space
           spc_alloc_v/(1024*1024*1024) spc_alloc,
           100*spc_oltp_v/spc_alloc_v spc_oltp,
           100*(spc_alloc_v - (spc_oltp_v + spc_mrw_v + spc_nrw_v + spc_row_v))/
              spc_alloc_v spc_scan,
           100*spc_nrw_v/spc_alloc_v spc_nrw,
           -- flash cache hits/misses and rates
           fc_oltp_hits_v,
           fc_oltp_miss_v,
           fc_scan_hits_v,
           100*fc_oltp_hits_v/(fc_oltp_hits_v + fc_oltp_miss_v) fc_oltp_hit,
           100*fc_scan_by_v/fc_scan_att_v fc_scan_hit,
           -- flash cache write profile
           fc_first_v,
           fc_over_v,
           lw_land_v,
           lwrej_limit_v,
           -- smart scan hard disk
           ss_hd_v/1048576 ss_hd_v,
           -- replacements
           repl_oltp_succ_v,
           repl_oltp_fail_v,
           repl_scan_succ_v,
           repl_scan_fail_v,
           repl_main_v,
           repl_zero_v,
           repl_victim_v/(repl_oltp_succ_v + repl_oltp_fail_v +
                          repl_scan_succ_v + repl_scan_fail_v) srch,
           wrq_v, arq_v, dsrq_v, lwrq_v,
           wby_v/1048576 dkwr_wmb,
           aby_v/1048576 dkwr_aging_mb,
           dsby_v/1048576 dkwr_datasync_mb,
           lwby_v/1048576 dkwr_lwds_mb
      from cell_global
      pivot(sum(value) v
           for metric_id in
           (202 spc_alloc, -- space -- alloc
            311 spc_oltp, -- oltp
            300 spc_cc ,-- cc
            370 spc_mrw, -- mrw
            371 spc_nrw, -- nrq
            372 spc_row, -- row
            381 repl_scan_fail, -- -- replacements -- dw failed
            382 repl_oltp_fail, -- oltp fail
            383 repl_scan_succ, -- dw succ
            384 repl_oltp_succ, -- oltp succ
            385 repl_main, -- main
            386 repl_zero, -- zero
            387 repl_victim, -- victim
            481 lw_land, -- -- lw lwland
            476 lwrej_limit, -- lwrej global limit
            189 fc_first, -- first writes
            190 fc_over, -- overwrites
            200 fc_oltp_hits, -- oltp hits
            204 fc_scan_hits, -- scan hits
            201 fc_oltp_miss, -- oltp misses
            206 fc_scan_by, -- scan bytes
            205 fc_scan_att, -- scan attempted
            242 ss_hd,  -- smart scan on hd
            316 wrq,    -- dkwr req
            317 wby,    -- dkwr by
            670 arq,    -- aging
            671 aby,
            672 dsrq,   -- datasync
            673 dsby,
            676 lwrq,  -- lw datasync
            677 lwby
            ))          
    )
select g.snap_id, g.et,
       scan_avwt,
       sbr_avwt,
       rt_avwt,
       wt_avwt,
       dr_avwt,
       dw_avwt,
       spc_alloc, spc_oltp, spc_scan, spc_nrw,
       fc_oltp_hits_v, fc_oltp_miss_v, fc_scan_hits_v,
       fc_oltp_hit, fc_scan_hit,
       fc_first_v, fc_over_v, lw_land_v, lwrej_limit_v,
       ss_hd_v,
       repl_oltp_succ_v, repl_oltp_fail_v, repl_scan_succ_v, repl_scan_fail_v,
       repl_main_v, repl_zero_v, srch,
       wrq_v, arq_v, dsrq_v, lwrq_v,
       dkwr_wmb, dkwr_aging_mb, dkwr_datasync_mb, dkwr_lwds_mb
  from wait_events e,
       global g
where e.dbid = g.dbid
  and e.snap_id = g.snap_id
 order by e.snap_id;
spool off 

SET LONG 90000
SET LONGCHUNKSIZE 90000
SET LINESIZE 125
SET PAGESIZE 500

@?/rdbms/admin/sqlsessend.sql
