set lines 160
col sql_text for a50
col created for a28
col last_modified for a16

spool show_sql_patches.log 

select sqp.name,
dbms_lob.substr(sql_text,3999,1) sql_text,
sqp.status,
to_char(sqp.created,'dd-mon-yy HH24:MI') created,
to_char(sqp.last_modified,'dd-mon-yy HH24:MI') last_modified
from dba_sql_patches sqp;

spool off
exit;

