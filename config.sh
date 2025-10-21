#!/bin/bash
# Perf Tool Kit CONFIGURATION shell
# It will set environment variables to execute smoothly Perf Tool Kit with the right version of Perl (the one embedded in RDBMS Oracle Home)
# It will test if the database is a multitenant Database , if so, then it requests the PDB Name 
# It will show if the DIAG PACK is available 
# environment variables will be set accordingly :
# PTK_MULTITENANT_DB
# PTK_STATSPACK
# PTK_EDITION
# PTK_DIAG_PACK

# default :
export PTK_DIAG_PACK=NO
export PTK_MULTITENANT_DB=NO
export PTK_STATSPACK=NO
export PTK_EDITION=ENTERPRISE

# init of parameter file : 
> PerfToolKit_parameters.conf 

CONNECT_STRING="/ as sysdba"
# Path to the Perl script
PERL_SCRIPT="perf_tool_kit.pl"

# Check if the ORACLE_HOME environment variable is set
if [ -z "$ORACLE_HOME" ]; then
  echo "ORACLE_HOME is not defined"
  exit 1
fi


# Check if the ORACLE_SID environment variable is set
if [ -z "$ORACLE_SID" ]; then
  echo "ORACLE_SID is not defined"
  exit 1
fi



# Check if the Perl script exists
if [ ! -f "$PERL_SCRIPT" ]; then
  echo "Perl script $PERL_SCRIPT does not exist."
  exit 1
fi

chmod +x $PERL_SCRIPT

# New shebang with ORACLE_HOME
NEW_SHEBANG="#!$ORACLE_HOME/perl/bin/perl"

# Update the shebang in the Perl script
sed -i "1s;^#!.*$;$NEW_SHEBANG;" "$PERL_SCRIPT"


# Function to check if the database is up
PMON_PROCESS=$(ps -ef | grep "ora_pmon_$ORACLE_SID" | grep -v "grep")

if [ -n "$PMON_PROCESS" ]; then
    echo "Oracle Database instance $ORACLE_SID is up (PMON process is running)."
    
else
    echo "Oracle Database instance $ORACLE_SID is down (PMON process is not running)."
    exit 1
fi

PATH=$ORACLE_HOME/perl/bin:$PATH
export PATH

# SQL query to get the edition
SQL_QUERY="SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT BANNER
FROM V\$VERSION
WHERE BANNER LIKE '%Edition%';"

# Execute the SQL query using sqlplus
EDITION=$(sqlplus -s  / as sysdba <<EOF
$SQL_QUERY
EXIT;
EOF
)

if [[ "$EDITION" =~ [Ee]nterprise ]]; then
    echo "Database in Enterprise Edition"
	export PTK_EDITION=ENTERPRISE
	echo "our \$PTK_EDITION='ENTERPRISE';" >> PerfToolKit_parameters.conf
elif [[ "$EDITION" =~ [Ss]tandard ]]; then
    echo "Database in Standard Edition"
	export PTK_EDITION=STANDARD
	echo "our \$PTK_EDITION='STANDARD';" >> PerfToolKit_parameters.conf
fi



# SQL query to get the diagnostics pack or not 
DIAG_PACK="SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT value 
FROM v$parameter 
WHERE name = 'control_management_pack_access';"
# Execute the SQL query using sqlplus
MANAGEMENT_PACK_ACCESS=$(sqlplus -s  / as sysdba <<EOF
$DIAG_PACK
EXIT;
EOF
)

if [[ "$MANAGEMENT_PACK_ACCESS" =~ DIAGNOSTIC ]]; then
    echo "Database has the Diagnostic Pack license (DIAG PACK)"
	export PTK_DIAG_PACK=YES
	echo "our \$PTK_DIAG_PACK='YES';" >> PerfToolKit_parameters.conf
	

fi




# SQL query to get the DATABASE_UNIQUENAME
SQL_QUERY="SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT DB_UNIQUE_NAME
FROM V\$DATABASE;"

# Execute the SQL query using sqlplus
DATABASE_UNIQUENAME=$(sqlplus -s  / as sysdba <<EOF
$SQL_QUERY
EXIT;
EOF
)






## IF CDB=YES then display the PDBs
## Prompt which PDB to choose
## Then export ORACLE_PDB_SID=<PDBS_NAME>;


IS_MULTITENANT="SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT CDB
FROM V\$DATABASE;"

# Execute the SQL query using sqlplus
CDB=$(sqlplus -s  / as sysdba <<EOF
$IS_MULTITENANT
EXIT;
EOF
)

SQL_SHOW_PDBS="SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
show pdbs;"

# Execute the SQL query using sqlplus
SHOW_PDBS=$(sqlplus -s  / as sysdba <<EOF
$SQL_SHOW_PDBS
EXIT;
EOF
)




if [ "$CDB" == "YES" ]; then
    export PTK_MULTITENANT_DB=YES
	echo "our \$PTK_MULTITENANT_DB='YES';" >> PerfToolKit_parameters.conf
	echo "Oracle Instance $ORACLE_SID is a Multitenant CDB."
	echo "Here is the list of PDBs : "
    echo "$SHOW_PDBS"
	read -p "Choose the PDB (or the CDB Root) to connect to : " pdb_choice
    
        # Exporter la variable ORACLE_PDB_SID
        export ORACLE_PDB_SID=$pdb_choice
		echo "our \$ORACLE_PDB_SID='${pdb_choice}';" >> PerfToolKit_parameters.conf
        
 
result=$(sqlplus -S /nolog <<EOF
connect / as sysdba
set heading off;
set feedback off;
select count(*) from dba_users where username = 'PERFSTAT';
exit;
EOF
)


    if [[ "$result" -eq 1 ]]; then
        echo "STATSPACK is installed in PDB : $pdb_choice."
		export PTK_STATSPACK=YES
		echo "our \$PTK_STATSPACK='YES';" >> PerfToolKit_parameters.conf
    else
        echo "STATSPACK is not installed in PDB : $pdb_choice."
		export PTK_STATSPACK=NO
		echo "our \$PTK_STATSPACK='NO';" >> PerfToolKit_parameters.conf
    fi

elif [ "$CDB" == "NO" ]; then
export PTK_MULTITENANT_DB=NO
echo "our \$PTK_MULTITENANT_DB='NO';" >> PerfToolKit_parameters.conf
 
fi


## Test if DIAG PACK 

## Test if Statspack installed 



echo "####################################################################################"
echo "Oracle Instance Name: $ORACLE_SID"
echo "Oracle Database Unique Name: $DATABASE_UNIQUENAME"
echo "Oracle Database Edition: $EDITION"
echo "Multitenant Database: $PTK_MULTITENANT_DB"
if [[ PTK_MULTITENANT_DB=="YES" ]]; then 
echo "PDB Database target: $ORACLE_PDB_SID"
	if [[ PTK_STATSPACK=="YES" ]]; then
	echo "Statspack installed in the PDB "	
	fi

fi


echo "Oracle Connect String will be $CONNECT_STRING"
echo "=> change \$connect_string in $PERL_SCRIPT if you have to"

echo "------------------------------------------------------------------------------------"
echo "You can now run Perf Tool Kit with these commands : "
echo "export path=$PATH"
if [[ PTK_MULTITENANT_DB=="YES" ]]; then 
echo "export ORACLE_PDB_SID=$pdb_choice "
fi
echo "perl perf_tool_kit.pl  "
echo "------------------------------------------------------------------------------------"
echo "####################################################################################"


