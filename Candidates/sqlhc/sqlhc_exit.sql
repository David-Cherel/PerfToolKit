Rem
Rem $Header: sqlhc_exit.sql 04-aug-2024. $
Rem
Rem sqlhc_exit.sql
Rem
Rem Copyright (c) 2024, Oracle and/or its affiliates.
Rem
Rem    NAME
Rem      sqlhc_exit.sql - Exit due to error
Rem
Rem    DESCRIPTION
Rem
Rem    NOTES
Rem
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    smuthuku    10/09/24 - SQLHC version update ER 37154785
Rem    scharala    08/04/24 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
prompt Exiting due to error
exit
@?/rdbms/admin/sqlsessend.sql
