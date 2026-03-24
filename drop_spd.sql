
-- #############################################################################################################
-- FILE: drop_spd.sql
-- #############################################################################################################
--
-- PURPOSE:
-- Drops SQL Plan Directives linked to a specified schema object by scanning DBA_SQL_PLAN_DIR_OBJECTS, removing each directive via DBMS_SPD, then displaying remaining directives for the schema.
--
-- INPUT PARAMETERS:
-- &1 (myschema) - STRING - Schema owner name containing the target object (e.g., 'MYUSER').
-- &2 (myobject_name) - STRING - Object name associated with SQL plan directives to drop (e.g., 'OBJECT1').
--
-- OUTPUT DESCRIPTION:
-- Performs directive deletion in PL/SQL and outputs a result set listing SQL plan directives remaining for the specified schema after the drop operation.
--
-- QUESTIONS ADDRESSED BY THIS SCRIPT:
-- REM EMBEDDINGS BEG
-- How can I drop SQL Plan Directives for a specific schema object?
-- Which directive IDs are associated with an object before deletion?
-- Can I remove all directives tied to one object in a single run?
-- What SQL Plan Directives remain for the schema after deletion?
-- Did DBMS_SPD.DROP_SQL_PLAN_DIRECTIVE complete without errors?
-- REM EMBEDDINGS END
--
-- #############################################################################################################
-- EXAMPLE : drop_spd.sql MYUSER OBJECT1
-- #############################################################################################################
--
spool drop_spd.log

set pages 9999
set lines 180

define myschema ='&1'
define myobject_name ='&2'


DECLARE
    
    CURSOR c_directives IS
        select distinct(directive_id) from dba_sql_plan_dir_objects
		where owner = upper('&myschema') and object_name=upper('&myobject_name');

   
    v_directive_id NUMBER;
BEGIN
    
    OPEN c_directives;
    LOOP
        FETCH c_directives INTO v_directive_id;

spool off
        EXIT WHEN c_directives%NOTFOUND;

        DBMS_SPD.DROP_SQL_PLAN_DIRECTIVE(directive_id => v_directive_id);
    END LOOP;
    CLOSE c_directives;

EXCEPTION
    WHEN OTHERS THEN
        -- Gérez les exceptions ici
        IF c_directives%ISOPEN THEN
            CLOSE c_directives;
        END IF;
        RAISE;
END;
/


PROMPT **********************************************************
PROMPT LIST OF SQL DIRECTIVES AFTER THE DROP FOR THE SCHEMA
PROMPT **********************************************************



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
AND    o.owner = upper('&myschema') 
ORDER BY 2,3,5,4;

exit;
