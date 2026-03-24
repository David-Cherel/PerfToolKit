
-- #############################################################################################################
-- FILE: parameters_mods.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Lists AWR-recorded initialization parameter value changes over time (including hidden parameters), showing previous and new values per instance/container and snapshot.
--
-- INPUT PARAMETERS:
-- None (script currently reports all detected changes; no substitution variable required).
--
-- OUTPUT DESCRIPTION:
-- One result set of parameter changes with instance, container, snapshot, time, parameter name, old value, and new value; output is spooled to parameters_mods.log.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- Which initialization parameters changed over the retained AWR period?
-- When did each parameter value change occur?
-- What were the previous and new values for each change?
-- On which instance/container did each parameter change happen?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : parameters_mods.sql
-- #############################################################################################################
--
spool parameters_mods.log

set linesize 180
set pages 999
col time for a20
col parameter_name format a40
col old_value format a25
col new_value format a25

break on instance skip 3
select instance_number instance, con_id container, snap_id, time, parameter_name, old_value, new_value 
from (select a.con_id, a.snap_id,to_char(end_interval_time,'DD-MON-YY HH24:MI') TIME,  a.instance_number, parameter_name, value new_value, 
lag(parameter_name,1) over (partition by parameter_name, a.instance_number order by a.snap_id) old_pname,
lag(value,1) over (partition by parameter_name, a.instance_number  order by a.snap_id) old_value ,
decode(substr(parameter_name,1,2),'__',2,1) calc_flag
from dba_hist_parameter a, dba_Hist_snapshot b , v$instance v
where a.snap_id=b.snap_id 
and a.instance_number=b.instance_number 
and a.con_id=b.con_id) 
where 
new_value != old_value
and calc_flag not in (decode('N','Y',3,2))
order by 1,2
/


spool off
exit;
