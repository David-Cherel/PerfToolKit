-- ##########################################################
-- Show SQL Baselines one plan  from SQL plan name input
-- ##########################################################

-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : show_sql_baselines_sql_plan.sql SQLID_cm1fyt76dwbkb_2481688974  
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



set lines 160
set pages 999
col sql_text for a100 trunc
col enabled for a7
col plan_hash_value for a16 trunc
col last_verified for a16
col last_executed for a16
col plan_name for a35 trunc
define plan_name='&1'
select spb.sql_handle, spb.plan_name, 
dbms_lob.substr(sql_text,3999,1) sql_text,
spb.enabled, spb.accepted, spb.fixed,
to_char(spb.last_verified,'dd-mon-yy HH24:MI') last_verified,
to_char(spb.last_executed,'dd-mon-yy HH24:MI') last_executed
from
dba_sql_plan_baselines spb, sqlobj$ so
where spb.signature = so.signature
and spb.plan_name = so.name
and spb.plan_name like nvl('&plan_name',spb.plan_name);

exit;

