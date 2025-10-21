-- #############################################################################################################
-- Create Statspack snapshot, it is a means to push and save queries in statspack tables 
-- (avoiding risk of loosing Cursor and plan in cache)
-- #############################################################################################################

EXEC PERFSTAT.statspack.snap;
exit;