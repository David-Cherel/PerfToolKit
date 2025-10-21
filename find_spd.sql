-- #############################################################################################################
-- Find SQL plan directives associated with a schema's objects
-- 
-- #############################################################################################################


-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
-- Example : find_spd.sql myuser 
-- $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

-- 
--
--
--

set pages 9999
set lines 180

define schema ='&1'

spool find_spd.log


COLUMN dir_id FORMAT A20
COLUMN owner FORMAT A10
col object_type FORMAT a11
col type FORMAT a17
col state FORMAT a8
COLUMN object_name FORMAT A25
COLUMN col_name FORMAT A15

SELECT TO_CHAR(d.directive_id) dir_id, o.owner, o.object_name, 
       o.subobject_name col_name, o.object_type, d.type, d.state, d.reason
FROM   dba_sql_plan_directives d, dba_sql_plan_dir_objects o
WHERE  d.directive_id=o.directive_id
AND    o.owner = upper('&schema') 
ORDER BY 2,3,5,4;

spool off

exit;
