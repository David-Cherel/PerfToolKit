-- #############################################################################################################
-- Create AWR snapshot, it is a means to push and save queries in AWR tables 
-- (avoiding risk of loosing Cursor and plan in cache)
-- #############################################################################################################

EXEC DBMS_WORKLOAD_REPOSITORY.create_snapshot;
exit;