#############################################
How to execute perf tool kit ?
#############################################


1) set your Oracle environment  :
. oraenv <<< MYDBINSTANCE


2) Run the configuration bash script  : 
chmod +x config.sh
./config.sh



3) Execute exec perf_tool_kit.pl :
perl perf_tool_kit.pl



#############################################
How to identify SQL query  ?
#############################################


FSQ 

FSQ=> for Finding SQL query in Library Cache
FSA => for Finding SQL query in AWR Repository  
then 1 or 2 => 




#############################################
How to display SQL Plan  ?
#############################################


Library Cache :
FSQ , 1 => DPL

AWR Report :
FSQ, 2 => DPA (option 1 or 2)

In a SQL Baseline :
DPB  



#############################################
How to compare the performance from various 
Execution Plans   ?
#############################################

Library Cache :
FSQ

It shows :
It shows :
AVG_ETIME = Average Elapsed Time
AVG_LIO = Average Logical IO Blocks
AVG_PIO = Average physical IO Blocks

   INST_ID SQL_ID        CHILD_NUMBER  PLAN_HASH      EXECS  AVG_ETIME    AVG_PIO    AVG_LIO
---------- ------------- ------------ ---------- ---------- ---------- ---------- ----------
SQL_TEXT
----------------------------------------------------------------------------------------------------------------------------------------------------------------
         1 g4pkmrqrgxg3b            0 3027739212          2   ,0771685          3    17399,5
select count(*) from dba_objects



AWR Report :
FSA => DPA (option 2)

It shows :
AVG_ETIME = Average Elapsed Time
AVG_LIO = Average Logical IO Blocks
AVG_PIO = Average physical IO Blocks


   SNAP_ID   NODE BEGIN_INTERVAL_TIME            SQL_ID        PLAN_HASH_VALUE        EXECS    AVG_ETIME        AVG_LIO        AVG_PIO
---------- ------ ------------------------------ ------------- --------------- ------------ ------------ -------------- --------------
       191      1 27/01/25 06:00:55,478          g4pkmrqrgxg3b      3027739212            2         .077       17,399.5            3.0





#############################################
How to play with hints on SQL Statement  ?
#############################################


Find an original SQL execution :
FSQ
or
FSA

Create you own query while adding a hint:
ESQ

=> keep the new SQL_ID  and the new Plan_hash_value 

You can compare performance with FSQ  using the two SQL_ID 







#############################################
How to solve an Execution plan instability  ?
=> creation of a SQL Baseline 
#############################################

Find the efficient execution plan and the sub-optimal execution plan :

In AWR (if possible) : 
FSA => DPA (option 2)


In Library Cache :
FSQ


Efficient exec plan : GOOD_SQL_ID  + GOOD_PLAN_HASH_VALUE
SQL_ID to fix : TO_FIX_SQL_ID
You can also create the GOOD_SQL_ID and GOOD_PLAN_HASH_VALUE by execution your own SQL with specific hints, if you know the SQL text to fix.

Create SQL Baseline on TO_FIX_SQL_ID :

CRB :
then 
-1 for creating SQL Baselines from cursor cache
-2 for creating SQL Baselines from AWR  

Enter as SQL_ID the value from TO_FIX_SQL_ID
Enter as PLAN_HASH_VALUE the value from GOOD_PLAN_HASH_VALUE


A SQL Baseline will be created with one SQL Baseline Plan.
The SQL Baseline Plan will be given the name : SQLID_<TO_FIX_SQL_ID>_<GOOD_PLAN_HASH_VALUE>


Verify the presence of SQL Baseline for your SQL_ID :
SHB

Enter 1 for showing last created SQL Baselines during last hour : show_last_hour_sql_baselines.sql
Enter 2 for showing last created SQL Baselines during last day : show_last_day_sql_baselines.sql
Enter 3 for showing SQL Baselines with SQL Text extract inputs : show_sql_baselines_text.sql
Enter 4 for showing SQL Baselines with SQL Handle inputs : show_sql_baselines_sql_handle.sql
Enter 5 for showing SQL Baselines with SQL Plan inputs : show_sql_baselines_sql_plan.sql
Enter 6 for showing SQL Baselines with SQL Plan with format : SQLID_<sql_id>_<plan_hash_value> : show_sql_baselines_with_SQLID.sql


Example:

choice : 1
INFO :execution du sqlplus show_last_hour_sql_baselines.sql

SQL_HANDLE                     PLAN_NAME                           PLAN_HASH_VALUE
------------------------------ ----------------------------------- ----------------
SQL_TEXT                                                                                             ENABLED ACC FIX LAST_VERIFIED    LAST_EXECUTED
---------------------------------------------------------------------------------------------------- ------- --- --- ---------------- ----------------
SQL_ffcb02fef3e9294d           SQLID_56bs32ukywdsq_4273460398      1934189003
select count(*) from dba_tables                                                                      YES     YES YES




You can also display the execution plan of your SQL Baseline Plan with key SQL_HANDLE (SQL_HANDLE is the ref of a SQL Baseline that may contain several SQL Baseline Plans
For Standard Edition 2, only one plan per SQL Baseline 
