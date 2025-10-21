#!D:\oracle\product\19.3\dbhome19.3\perl\bin\perl

######################################################
## Performance tool kit 
## author : David Cherel (david.cherel@oracle.com)
## Mainly based on SQL scripts written by Kerry Osborne (http://kerryosborne.oracle-guy.com/)
## some subs coming from Bertrand Drouvot (https://bdrouvot.wordpress.com/)
## Date	  : 01/2025
## Version: 1.4
######################################################


use feature qw( say );
use feature qw( switch );
no warnings qw( experimental::smartmatch );

# #https://metacpan.org/pod/release/TPABA/Term-Screen-Uni-0.04/lib/Term/Screen/Uni.pm
# require Term::Screen::Uni;
# my $scr = new Term::Screen::Uni;

#$ORACLE_HOME='D:\oracle\product\19.3\dbhome19.3';
#$ORACLE_HOME=$ENV{ORACLE_HOME};

#$connect_string='sys/ClarisV3! as sysdba';

#open LOGFILEH, 'perf_tool_kit.log' or die $!;

# open my $logfile_name, ">>", "perf_tool_kit.log";
#open LOGDIRH, 'log' or die $!;
#open TEMPDIRH, 'temp' or die $!;
#open CURRENTDIRH, '.' or die $!;
$logfile_name='perf_tool_kit.log';
$LOG_DIR="./log";

sub prompt_for_password {
    require Term::ReadKey;

    # Tell the terminal not to show the typed chars
    Term::ReadKey::ReadMode('noecho');

    print "Entrer le mot de passe du user SYS sous oracle :\n";
    my $password = Term::ReadKey::ReadLine(0);

    # Rest the terminal to what it was previously doing
    Term::ReadKey::ReadMode('restore');

    # The one you typed didn't echo!
    print "\n";

    # get rid of that pesky line ending (and works on Windows)
    $password =~ s/\R\z//;

    # say "Password was <$password>"; # check what you are doing :)

    return $password;
}

sub say_time {
	$datestring = localtime();
    say "INFO : $datestring";
}


sub write_to_log_and_screen {
    my ($a) = @_;
    # save original settings. You could also use lexical typeglobs.
    *OLD_STDOUT = *STDOUT;
    *OLD_STDERR = *STDERR;
	say "$a";
    # reassign STDOUT, STDERR
    open my $log_fh, '>>', $logfile_name;
    *STDOUT = $log_fh;
    *STDERR = $log_fh;

    say "$a";

    # done, restore STDOUT/STDERR
    *STDOUT = *OLD_STDOUT;
    *STDERR = *OLD_STDERR;
}
sub clean 
{
my ($file_name) = @_;

	if(-e $file_name) 
	{
		unlink($file_name);
	}
	elsif (-e "$LOG_DIR/$file_name")
	{
	unlink("$LOG_DIR/$file_name");
	}

}
sub push_spool_in_mem {

}

sub exec_sql {
	my ($connect,$sql_file) = @_;
	say "INFO :execution du sqlplus $sql_file";
	#say "sqlplus -S $connect \@$sql_file";
	my $result = `$ORACLE_HOME/bin/sqlplus -L $connect \@$sql_file `;
	#my $result = qx{ $ORACLE_HOME/bin/sqlplus -S $connect \@$sql_file };
	#my $result = qx{ type $sql_file };
	return $result;
}

sub exec_sql_one_param {
	my ($connect,$sql_file,$p1) = @_;
	say "INFO :execution du sqlplus $sql_file";
	#say "sqlplus -S $connect \@$sql_file";
	my $result = `$ORACLE_HOME/bin/sqlplus -L $connect \@$sql_file $p1 `;
	#my $result = qx{ $ORACLE_HOME/bin/sqlplus -S $connect \@$sql_file };
	#my $result = qx{ type $sql_file };
	return $result;
}

sub exec_sql_two_param {
	my ($connect,$sql_file,$p1,$p2) = @_;
	say "INFO :execution du sqlplus $sql_file";
	#say "sqlplus -S $connect \@$sql_file";
	my $result = `$ORACLE_HOME/bin/sqlplus -L $connect \@$sql_file $p1 $p2 `;
	#my $result = qx{ $ORACLE_HOME/bin/sqlplus -S $connect \@$sql_file };
	#my $result = qx{ type $sql_file };
	return $result;
}

sub exec_sql_three_param {
	my ($connect,$sql_file,$p1,$p2,$p3) = @_;
	say "INFO :execution du sqlplus $sql_file";
	#say "sqlplus -S $connect \@$sql_file";
	my $result = `$ORACLE_HOME/bin/sqlplus -L $connect \@$sql_file $p1 $p2 $p3`;
	#my $result = qx{ $ORACLE_HOME/bin/sqlplus -S $connect \@$sql_file };
	#my $result = qx{ type $sql_file };
	return $result;
}

sub exec_sql_four_param {
	my ($connect,$sql_file,$p1,$p2,$p3,$p4) = @_;
	say "INFO :execution du sqlplus $sql_file";
	#say "sqlplus -S $connect \@$sql_file";
	my $result = `$ORACLE_HOME/bin/sqlplus -L $connect \@$sql_file $p1 $p2 $p3 $p4`;
	#my $result = qx{ $ORACLE_HOME/bin/sqlplus -S $connect \@$sql_file };
	#my $result = qx{ type $sql_file };
	return $result;
}

sub exec_sql_five_param {
	my ($connect,$sql_file,$p1,$p2,$p3,$p4,$p5) = @_;
	say "INFO :execution du sqlplus $sql_file";
	#say "sqlplus -S $connect \@$sql_file";
	my $result = `$ORACLE_HOME/bin/sqlplus -L $connect \@$sql_file $p1 $p2 $p3 $p4 $p5`;
	#my $result = qx{ $ORACLE_HOME/bin/sqlplus -S $connect \@$sql_file };
	#my $result = qx{ type $sql_file };
	return $result;
}

sub print_menu {
	say "MENU : Action list";
}

sub prompt_action {
	my $command;
	print("Enter a command to execute, Q to quit.\n"); 
	chomp($command = <STDIN>); 
	return  $command;
}

sub execute_sql {
say '------------------------------------------------------------';
say '- Option :  ESQ |                for Executing sql statement';
say '------------------------------------------------------------';
my $SQL_TEXT;
my $result;

clean("sql_exec_query.sql");
clean("sql_exec_query.log");



say 'Which statement/query do you want to execute ?';
chomp($SQL_TEXT = <STDIN>); 

open my $sql_exec_query, ">>", "sql_exec_query.sql";

$sql_exec_query->say ('set lines 160');
$sql_exec_query->say ('set pages 999');
$sql_exec_query->say ('spool sql_exec_query.log');
$sql_exec_query->say ('alter session set statistics_level=all;');
$sql_exec_query->say ('alter session set "_rowsource_execution_statistics"=true; ');
$sql_exec_query->say ("$SQL_TEXT");
$sql_exec_query->say ("SELECT * FROM table(dbms_xplan.display_cursor (format=>'allstats +note'));");
$sql_exec_query->say ('spool off');
$sql_exec_query->say ('exit');
close $sql_exec_query;

$result=exec_sql ($connect_string,"sql_exec_query.sql");
say ("$result");
# Plan hash value: 491101008
# SQL_ID  56bs32ukywdsq, child number 0
push_spool_in_mem('sql_exec_query.log');

}

sub awr_snapshot {
my $result_query;
$result_query=exec_sql($connect_string,'create_awr_snapshot.sql');
print $result_query;
}

sub find_sql {
say '----------------------------------------------------------------------';
say '- Option :  FSQ | for finding SQL query in Library Cache (Shared Pool)';
say '----------------------------------------------------------------------';

	clean("sql_find_query.sql");
	
	my $SQL_TEXT;
	my $result_query;
	print("Enter an extract of SQL_TEXT to find a cursor in Library Cache:\n"); 
	chomp($SQL_TEXT = <STDIN>); 
	$SQL_TEXT =~ s/'/''/g;

# unless(open $sql_find_query, '>'.sql_find_query.sql) {
    # # Die with error message 
    # # if we can't open it.
    # die "\nUnable to create sql_find_query.sql\n";
# }

open (my $sql_find_query, '>', 'sql_find_query.sql') or die "Could not open file 'sql_find_query.sql' $!";
$sql_find_query->say ('set lines 160');
$sql_find_query->say ('set pages 999');
$sql_find_query->say ('spool sql_find_query.log');
$sql_find_query->say("select inst_id, sql_id, child_number, plan_hash_value plan_hash, executions execs,");
$sql_find_query->say("(elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_etime,");
$sql_find_query->say("disk_reads/decode(nvl(executions,0),0,1,executions) avg_pio,");
$sql_find_query->say("buffer_gets/decode(nvl(executions,0),0,1,executions) avg_lio,");
$sql_find_query->say("sql_text from gv\$sql s");
$sql_find_query->say("where upper(sql_text) like upper('%'||'$SQL_TEXT'||'%')");
$sql_find_query->say("and sql_text not like '%from gv\$sql s where upper%'");
$sql_find_query->say("order by 1, 2, 3, 4;");
$sql_find_query->say("spool off");
$sql_find_query->say("exit");

close $sql_find_query;

$result_query=exec_sql($connect_string,'sql_find_query.sql');

print $result_query;
}

sub find_sql_awr {
my $choice;
my $result_query;
my $SQL_TEXT;
my $sql_id;

say '----------------------------------------------------------------------';
say '- Option :  FSA |        for finding SQL query in AWR Repository';
say '----------------------------------------------------------------------';
do{
	say ('Enter 1 for finding a SQL_ID from extract of SQL_TEXT : find_sql_awr.sql'); 
	say ('Enter 2 for finding various execution plans (PLAN_HASH_VALUE) for a SQL_ID : awr_plan_change.sql ');
	say ('Enter q for going back to main menu  ');
	chomp($choice = <STDIN>); 

if ($choice eq 1)
{

	clean("sql_find_awr_query.sql");
	clean("sql_find_awr_query.log");
	print("Enter an extract of SQL_TEXT to find a SQL in AWR reports:\n"); 
	chomp($SQL_TEXT = <STDIN>); 

	
	$SQL_TEXT =~ s/'/''/g;

open (my $sql_find_query, '>', 'sql_find_awr_query.sql') or die "Could not open file 'sql_find_awr_query.sql' $!";

$sql_find_query->say ("set long 32000");
$sql_find_query->say ("set lines 150");
$sql_find_query->say ("set pages 999");
$sql_find_query->say ("col sql_text format a60 ");
$sql_find_query->say ("col node for 99999");
$sql_find_query->say ("select distinct s.instance_number node, dbms_lob.substr(txt.sql_text,3999,1) sql_text,  s.sql_id, s.plan_hash_value");
$sql_find_query->say ("from DBA_HIST_SQLSTAT S,  dba_hist_sqltext txt");
$sql_find_query->say ("where s.sql_id=txt.sql_id");
$sql_find_query->say ("and dbms_lob.substr(txt.sql_text,3999,1) like ('%'||'$SQL_TEXT'||'%')");
$sql_find_query->say ("and dbms_lob.substr(txt.sql_text,3999,1) not like '%like%';");
$sql_find_query->say ("exit;");


close $sql_find_query;



$result_query=exec_sql($connect_string,'sql_find_awr_query.sql');
print $result_query;


}
elsif ($choice eq 2)
{



	clean("awr_plan_change.log");
	print("Enter a SQL_ID:\n"); 
	chomp($sql_id = <STDIN>);

$result_query=exec_sql_one_param($connect_string,'awr_plan_change.sql',$sql_id);
print $result_query;
}

} while ($choice ne 'q');

}

sub display_plan {
my $result_query;
my $sql_id;

	print("Enter a SQL_ID:\n"); 
	chomp($sql_id = <STDIN>);
$result_query=exec_sql_one_param($connect_string,'get_plan.sql',$sql_id);
print $result_query;
}


sub display_plan_awr {
my $result_query;
my $sql_id;
my $plan_hash_value;
	print("Enter a SQL_ID:\n"); 
	chomp($sql_id = <STDIN>);
	print("Enter a PLAN_HASH_VALUE:\n"); 
	chomp($plan_hash_value = <STDIN>);
$result_query=exec_sql_two_param($connect_string,'get_plan_awr.sql',$sql_id,$plan_hash_value);
print $result_query;
}

sub show_sql_baseline {


my $choice;
my $result_query;
my $sql_text;
my $sql_plan;
my $sql_handle;

say '----------------------------------------------------------------------';
say '- Option :  SHB  for Showing SQL Baseline';
say '----------------------------------------------------------------------';
do{
	say ('Enter 1 for showing last created SQL Baselines during last hour : show_last_hour_sql_baselines.sql '); 
	say ('Enter 2 for showing last created SQL Baselines during last day : show_last_day_sql_baselines.sql ');
	say ('Enter 3 for showing SQL Baselines with SQL Text extract inputs : show_sql_baselines_text.sql ');
	say ('Enter 4 for showing SQL Baselines with SQL Handle inputs : show_sql_baselines_sql_handle.sql');
	say ('Enter 5 for showing SQL Baselines with SQL Plan inputs : show_sql_baselines_sql_plan.sql');
	say ('Enter q for going back to main menu  ');
	chomp($choice = <STDIN>); 

if ($choice eq 1)
{
$result_query=exec_sql($connect_string,'show_last_hour_sql_baselines.sql');
print $result_query;
}
elsif ($choice eq 2)
{
$result_query=exec_sql($connect_string,'show_last_day_sql_baselines.sql');
print $result_query;
}
elsif ($choice eq 3)
{

	clean("show_sql_baselines_text.sql");
	clean("show_sql_baselines_text.log");
	print("Enter an extract of SQL_TEXT to find a SQL Baseline:\n"); 
	chomp($SQL_TEXT = <STDIN>); 
	$SQL_TEXT =~ s/'/''/g;

open (my $find_baseline_query, '>', 'show_sql_baselines_text.sql') or die "Could not open file 'show_sql_baselines_text.sql' $!";

$find_baseline_query->say ("spool show_sql_baselines_text.log");
$find_baseline_query->say ("set lines 160");
$find_baseline_query->say ("set pages 999");
$find_baseline_query->say ("col sql_text for a100 trunc");
$find_baseline_query->say ("col last_executed for a28");
$find_baseline_query->say ("col enabled for a7");
$find_baseline_query->say ("col plan_hash_value for a16 trunc");
$find_baseline_query->say ("col last_executed for a16");
$find_baseline_query->say ("select spb.sql_handle, spb.plan_name, to_char(so.plan_id) plan_hash_value,");
$find_baseline_query->say ("dbms_lob.substr(sql_text,3999,1) sql_text,");
$find_baseline_query->say ("spb.enabled, spb.accepted, spb.fixed,");
$find_baseline_query->say ("to_char(spb.last_executed,'dd-mon-yy HH24:MI') last_executed");
$find_baseline_query->say ("from");
$find_baseline_query->say ('dba_sql_plan_baselines spb, sqlobj$ so');
$find_baseline_query->say ("where spb.signature = so.signature");
$find_baseline_query->say ("and spb.plan_name = so.name");
$find_baseline_query->say ("and spb.sql_text like ('%'||'$SQL_TEXT'||'%');");
$find_baseline_query->say ("spool off");
$find_baseline_query->say ("exit;");

$result_query=exec_sql($connect_string,'show_sql_baselines_text.sql');
print $result_query;
}
elsif ($choice eq 4)
{


	print("Enter a SQL Handle:\n"); 
	chomp($sql_handle = <STDIN>);
	
$result_query=exec_sql_one_param($connect_string,'show_sql_baselines_sql_handle.sql',$sql_handle);
print $result_query;
}
elsif ($choice eq 5)
{
	print("Enter a SQL Plan:\n"); 
	chomp($sql_plan = <STDIN>);

	
$result_query=exec_sql_one_param($connect_string,'show_sql_baselines_sql_plan.sql',$sql_plan);
print $result_query;
}

} while ($choice ne 'q');


}



sub display_plan_baseline {

my $choice;
my $result_query;
my $sql_plan;


say '----------------------------------------------------------------------';
say '- Option: DPB  for Displaying Execution Plan from SQL Baseline';
say '- SQL File : get_plan_sql_baseline.sql';
say '----------------------------------------------------------------------';

	print("Enter a SQL Plan:\n"); 
	chomp($sql_plan = <STDIN>);

	
$result_query=exec_sql_one_param($connect_string,'get_plan_sql_baseline.sql',$sql_plan);
print $result_query;	

}





sub create_sql_baseline {
my $choice;
my $result_query;
my $plan_hash_value;
my $sql_id;
my $sql_plan;


say '----------------------------------------------------------------------';
say '- Option: CRB  for Creating SQL Baseline';
say '----------------------------------------------------------------------';



do	{
	say ('Enter 1 for creating SQL Baselines from cursor cache (Library Cache) : create_sql_baseline_cursor_cache.sql'); 
	say ('Enter 2 for creating SQL Baselines from AWR : create_sql_baseline_awr.sql'); 
	say ('Enter q for going back to main menu  ');
	chomp($choice = <STDIN>); 

	
	if ($choice eq 1)
		{
		print("The SQL Baseline will be set to FIXED=YES\n");
		print("Enter a SQL_ID:\n");
		chomp($sql_id = <STDIN>);
		print("Enter a Plan Hash Value:\n"); 
		chomp($plan_hash_value = <STDIN>);
		$result_query=exec_sql_four_param($connect_string,'create_sql_baseline_cursor_cache.sql',$sql_id,$plan_hash_value,'YES','YES');
		print $result_query;
		}
	elsif ($choice eq 2)
		{
		print("The SQL Baseline will be set to FIXED=YES\n");
		print("Enter a SQL_ID:\n"); 
		chomp($sql_id = <STDIN>);
		print("Enter a Plan Hash Value:\n"); 
		chomp($plan_hash_value = <STDIN>);
		$result_query=exec_sql_four_param($connect_string,'create_sql_baseline_awr.sql',$sql_id,$plan_hash_value,'YES','YES');
		print $result_query;
		}
	
	
	} while ($choice ne 'q');


}




sub add_sql_baseline {

say '------------------------------------------------------------------------------------';
say '- Option: ADB  for Adding SQL Plan to SQL Baseline from Cursor Cache (Library Cache)';
say '------------------------------------------------------------------------------------';

my $result_query;
my $plan_hash_value;
my $sql_id;
my $sql_handle;


	print("Enter a SQL_ID:\n"); 
	chomp($sql_id = <STDIN>);
	print("Enter a Plan Hash Value:\n"); 
	chomp($plan_hash_value = <STDIN>);
	print("Enter a SQL Handle:\n"); 
	chomp($sql_handle = <STDIN>);
	
$result_query=exec_sql_three_param($connect_string,'add_sql_plan_to_baseline_cursor_cache.sql',$sql_id,$plan_hash_value,$sql_handle);	
	
print $result_query;	
}


sub alter_sql_baseline {
say '----------------------------------------------------------------------';
say '- Option: ALB  for Altering SQL Plan from Baseline ';
say '----------------------------------------------------------------------';

my $result_query;
my $sql_plan;
my $sql_handle;
my $enabled;
my $fixed;

	print("Enter a SQL Handle for Baseline:\n"); 
	chomp($sql_handle = <STDIN>);
	print("Enter a SQL Plan Name:\n"); 
	chomp($sql_plan = <STDIN>);

	$result_query=exec_sql_one_param($connect_string,'show_sql_baselines_sql_plan.sql',$sql_plan);
	print $result_query;

	
	print("Enter a value for ENABLED (YES or NO):\n"); 
	chomp($enabled = <STDIN>);
	print("Enter a value for FIXED (YES or NO):\n"); 
	chomp($fixed = <STDIN>);
	
	$result_query=exec_sql_four_param($connect_string,'alter_sql_plan_from_baseline.sql',$sql_handle,$sql_plan,$fixed,$enabled);
	print $result_query;
	
	
}
sub export_sql_baseline {

say '----------------------------------------------------------------------';
say '- Option: EXB  for Exporting SQL Plan from Baseline to a file ';
say '----------------------------------------------------------------------';

my $choice;
my $result_query;
my $sql_plan;
my $file_name;
my $table_name='STG_PERFTOOL';
my $table_owner;
my $tablespace='USERS';
my $sql_handle;




do	{
	say ('Enter 1 for exporting a single SQL Plan from SQL Baseline '); 
	say ('Enter 2 for exporting All SQL Plans from a SQL Baseline'); 
	say ('Enter q for going back to main menu  ');
	chomp($choice = <STDIN>); 

	
	if ($choice eq 1)
		{

		print("Enter a SQL Plan Name:\n"); 
		chomp($sql_plan = <STDIN>);
		print("Enter a Dump file name:\n"); 
		chomp($file_name = <STDIN>);
		print("Enter a user/schema name in which staging table will be created (cannot be SYS):\n"); 
		chomp($table_owner = <STDIN>);
		$table_owner=uc($table_owner);
		print("Enter a table name for the staging table:\n"); 
		chomp($table_name = <STDIN>);
		$table_name=uc($table_name);
		print("Enter a tablespace name for that staging table: (user/schema should have privilege into that tbs) \n"); 
		chomp($tablespace = <STDIN>);
		$tablespace=uc($tablespace);
		say("Temporary table name used : $table_name");
		say("with user : $table_owner");
		say("using tablespace : $tablespace");
		say("The user : $table_owner  must have EXPORT/IMPORT privileges and the privilege to create table in tablespace : $tablespace");

		$result_query=exec_sql_five_param($connect_string,'export_sql_baseline_plan.sql',$sql_plan,$table_name,$table_owner,$tablespace,$file_name);
		print $result_query;	
		}
	elsif ($choice eq 2)
	{
		print("Enter a SQL handle for the SQL Baseline:\n"); 
		chomp($sql_handle = <STDIN>);
		print("Enter a Dump file name:\n"); 
		chomp($file_name = <STDIN>);
		$file_name=uc($file_name);
		print("Enter a user/schema name in which staging table will be created (cannot be SYS):\n"); 
		chomp($table_owner = <STDIN>);
		$table_owner=uc($table_owner);
		print("Enter a table name for the staging table:\n"); 
		chomp($table_name = <STDIN>);
		$table_name=uc($table_name);
		print("Enter a tablespace name for that staging table: (user/schema should have privilege into that tbs) \n"); 
		chomp($tablespace = <STDIN>);
		$tablespace=uc($tablespace);		
		say("Temporary table name used : $table_name");
		say("with user : $table_owner");
		say("using tablespace : $tablespace");
		say("The user : $table_owner  must have EXPORT/IMPORT privileges and the privilege to create table in tablespace : $tablespace");

		$result_query=exec_sql_five_param($connect_string,'export_sql_baseline_all_plans.sql',$sql_handle,$table_name,$table_owner,$tablespace,$file_name);
		print $result_query;	
	}
	
	
	
	} while ($choice ne 'q');


}


sub import_sql_baseline {

say '----------------------------------------------------------------------';
say '- Option: IMB  for Importing SQL Plan into a SQL Baseline  ';
say '----------------------------------------------------------------------';

my $result_query;
my $sql_handle;
my $file_name;
my $table_name='STG';
my $table_owner;
my $tablespace='USERS';


	print("Enter the Dump file name to import:\n"); 
	chomp($file_name = <STDIN>);
	$file_name=uc($file_name);
	print("Enter a SQL Handle:\n"); 
	chomp($sql_handle = <STDIN>);

	print("Enter a user/schema name in which the staging table will be created:\n"); 
	chomp($table_owner = <STDIN>);
	$table_owner=uc($table_owner);
	say("with user : $table_owner");
	say("using tablespace : $tablespace");
	say("The user : $table_owner  must have IMPORT privileges and the privilege to create table in tablespace : $tablespace");

	$result_query=exec_sql_two_param($connect_string,'import_sql_baseline_all_plans.sql',$file_name,$table_owner);
	print $result_query;

}






sub create_sql_patch {


say '----------------------------------------------------------------------';
say '- Option: CRP  for Creating SQL Patch ';
say '----------------------------------------------------------------------';


my $result_query;
my $plan_hash_value;
my $sql_id;
my $hint;
my $patchname;
		print("To create a SQL Patch, the query should be in shared_pool/library cache prior execution this command.e\n"); 
		print("If the cursor does not exist, it will fail.\n"); 
		print("(the cursor's presence is not checked by this part of the shell)\n"); 
		print("Therefore, you should have executed recently the query on which you want to create the SQL Patch\n"); 
		print("Enter a SQL_ID on which the SQL patch will be created:\n"); 
		chomp($sql_id = <STDIN>);
		print("Enter a Hint you want to put on your query:\n"); 
		chomp($hint = <STDIN>);
		print("Give a name to you SQL Patch:\n"); 
		chomp($patchname = <STDIN>);
		$result_query=exec_sql_three_param($connect_string,'create_sql_patch.sql',$sql_id,$hint,$patchname);
		print $result_query;
		
		
		
		
	clean("create_sql_patch.sql");
	clean("create_sql_patch.log");



open (my $create_sql_patch, '>', 'create_sql_patch.sql') or die "Could not open file 'create_sql_patch.sql' $!";

$create_sql_patch->say ("set feedback off");
$create_sql_patch->say ("set sqlblanklines on");
$create_sql_patch->say ("set serveroutput on");
$create_sql_patch->say ("set verify off");
$create_sql_patch->say ("spool create_sql_patch.log");
$create_sql_patch->say ("declare");
$create_sql_patch->say ("ret binary_integer;");
$create_sql_patch->say ("l_sql_id varchar2(13);");
$create_sql_patch->say ("begin");
$create_sql_patch->say ("l_sql_id := '$sql_id';");
$create_sql_patch->say ("l_name := '$patchname';");
$create_sql_patch->say ("dbms_output.put_line('SQL Patch creation ');");
$create_sql_patch->say ("ret := SYS.DBMS_SQLDIAG.create_sql_patch(");
$create_sql_patch->say ("    sql_id    => l_sql_id,");
$create_sql_patch->say ("    hint_text => '$hint',");
$create_sql_patch->say ("    name      => l_name);");
$create_sql_patch->say ("dbms_output.put_line('Return code : '||ret);");
$create_sql_patch->say ("dbms_output.put_line(' ');");
$create_sql_patch->say ("dbms_output.put_line('SQL Patch : '||l_name||' created.');");
$create_sql_patch->say ("dbms_output.put_line(' ');");
$create_sql_patch->say ("end;");
$create_sql_patch->say ("/");
$create_sql_patch->say ("spool off");
$create_sql_patch->say ("exit;");

$result_query=exec_sql($connect_string,'create_sql_patch.sql');
print $result_query;
		
		
		
		
		
		
		
}



sub show_sql_patch {

my $result_query;


say '----------------------------------------------------------------------';
say '- Option: SHP for Showing all SQL Patches';
say '- SQL File : show_sql_patches.sql';
say '----------------------------------------------------------------------';


	
$result_query=exec_sql($connect_string,'show_sql_patches.sql');
print $result_query;	

}


sub investigate {


say '----------------------------------------------------------------------';
say '- Option: INV  for Investigating general performance issues          ';
say '               Attempts to find SQL statements with plan instability ';  
say '               Search performed in AWR History Tables  ';  
say '----------------------------------------------------------------------';

my $result_query;
my $object_name;
my $sql_id;	
my $min_stddev=2;
my $min_etime=0.1;
my $days_ago;
my $object_name;

do	{
	say ('Enter 1 for scanning unstable execution plan : unstable_plans.sql'); 
	say ('Enter 2 for detecting when a plan has changed : awr_plan_change.sql '); 
	say ('Enter 3 for detecting which SQL queries have changed after a point in time (x days ago) : whats_changed.sql '); 
	say ('Enter 4 for searching any plan related to an object (ie table) : plans_for_object.sql '); 
	say ('Enter q for going back to main menu  ');
	chomp($choice = <STDIN>); 

	if ($choice eq 1)
		{
		print("Enter a standard deviation (default 2) :\n"); 
		chomp($min_stddev = <STDIN>);
		print("Enter a minimum elapsed time (default 0.1 s) :\n"); 
		chomp($min_etime = <STDIN>);
		$result_query=exec_sql_two_param($connect_string,'unstable_plans.sql',$min_stddev,$min_etime);
		print $result_query;
		}
	elsif ($choice eq 2)
		{
		clean("awr_plan_change.log");
		print("Enter a SQL_ID:\n"); 
		chomp($sql_id = <STDIN>);
		$result_query=exec_sql_one_param($connect_string,'awr_plan_change.sql',$sql_id);
		print $result_query;
		}
	elsif ($choice eq 3)
		{
		print("Define a point in time from which you want to compare performance before and after (like 2 days ago, give number of days) :\n"); 
		chomp($days_ago = <STDIN>);
		print("Enter a standard deviation (default 2) :\n"); 
		chomp($min_stddev = <STDIN>);
		print("Enter a minimum elapsed time (default 0.1 s) :\n"); 
		chomp($min_etime = <STDIN>);
		$result_query=exec_sql_three_param($connect_string,'whats_changed.sql',$days_ago,$min_stddev,$min_etime);
		print $result_query;
		}
	elsif ($choice eq 4)
		{
		print("Enter a table name on which you want to scan all queries variations :\n"); 
		chomp($object_name = <STDIN>);
		$result_query=exec_sql_one_param($connect_string,'awr_plan_change_on_object.sql',$object_name);
		print $result_query;
		}
	} while ($choice ne 'q');

	
	
}


sub parameter_check
	{
		say '----------------------------------------------------------------------';
		say '- Option: PAR  for Checking the parameters changes on the instances          ';
		say '- SQL File : parameters_mods.sql';
		say '----------------------------------------------------------------------';

my $result_query;

		$result_query=exec_sql($connect_string,'parameters_mods.sql');
		print $result_query;


	}


sub drop_baseline
	{
		say '----------------------------------------------------------------------';
		say '- Option: DRO  for Droping SQL Baseline          ';
		say '- SQL File : drop_sql_baseline.sql';
		say '----------------------------------------------------------------------';

my $result_query;
my $sql_handle;
		print("Enter a SQL Handle:\n"); 
		chomp($sql_handle = <STDIN>);
		$result_query=exec_sql_one_param($connect_string,'drop_sql_baseline.sql',$sql_handle);
		print $result_query;


	}
	
	

sub print_menu {
say '************************************************************';
say '##########  MENU ###########################################';
say '************************************************************';
say '     option: ESQ  for Executing SQL statement';
say '     option: SSQ  for Saving SQL statement (AWR SnapShot creation)';
say '     option: FSQ  for Finding SQL query in Library Cache';
say '     option: FSA  for Finding SQL query in AWR Repository';
say '     option: DPL  for Displaying Execution Plan from Library Cache';
say '     option: DPA  for Displaying Execution Plan from AWR Repository';
say '     option: DPB  for Displaying Execution Plan from SQL Baseline';
say '     option: SHB  for Showing SQL Baseline';
say '     option: CRB  for Creating SQL Baseline';
say '     option: ADB  for Adding SQL Plan to SQL Baseline';
say '     option: ALB  for Altering SQL Plan from SQL Baseline';
say '     option: EXB  for Exporting SQL Plan from SQL Baseline';
say '     option: IMB  for Importing SQL Plan into SQL Baseline';
say '     option: SHP  for Showing SQL Patch';
say '     option: CRP  for Creating SQL Patch';
say '     option: INV  for Investigating general performance issues';
say '     option: PAR  for Checking the parameters changes on the instances';
say '     option: DRO  for Droping SQL Baseline';
}

sub print_memory { }

sub clear_screen
{
if ($^O eq 'MSWin32')
{
print "\033[2J";
print "\033[0;0H"; 
`cls`;
}
else
{
print "\033[2J";
print "\033[0;0H"; 
`clear`;
}

# say 'clear screen';
#$scr->clrscr();
}

## Main

# variables locales ORACLE_HOME et ORACLE_SID
	#$ENV{ORACLE_HOME}=$ORACLE_HOME;
		$ORACLE_HOME=$ENV{ORACLE_HOME};
    require Term::ReadKey;

    # print "Entrer ORACLE_SID :\n";
    # my $ORACLE_SID = Term::ReadKey::ReadLine(0);
    # # Rest the terminal to what it was previously doing

    # # The one you typed didn't echo!
    # print "\n";
    # # get rid of that pesky line ending (and works on Windows)
    # $ORACLE_SID =~ s/\R\z//;
	$ORACLE_SID=$ENV{ORACLE_SID};
say  "Session parameter value for ORACLE_SID : $ORACLE_SID"; 
say  "Session parameter value for ORACLE_HOME : $ORACLE_HOME"; 
select STDOUT;
say 'INFO : ***********************************************************************************';
say 'INFO : Performance Tool Kit';
say 'INFO : Version 1.2 ';
say 'INFO : ***********************************************************************************';
say_time();
#$mdp = prompt_for_password();
#$connect_string = "sys/$mdp as sysdba";
#say "connect string : $connect_string";

$connect_string = "sys/ClarisV3! as sysdba";

open (my $LOGFILE, '>>',$logfile_name);
# *STDOUT = $LOGFILE;
# *STDERR = $LOGFILE;

select STDOUT;
select STDERR;

do 
{
#clear_screen();

#say '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$';

print_menu();
print_memory();
$response=prompt_action();

given($response){
     when ('ESQ') 	{  execute_sql(); }
	 when ('SSQ')   {  awr_snapshot(); }
     when ('FSQ') 	{  find_sql(); }
	 when ('FSA') 	{  find_sql_awr(); }
     when ('DPL') 	{  display_plan(); }
	 when ('DPA') 	{  display_plan_awr(); }
	 when ('DPB') 	{  display_plan_baseline(); }
	 when ('SHB') 	{  show_sql_baseline(); }
     when ('CRB') 	{  create_sql_baseline(); }
	 when ('ADB') 	{  add_sql_baseline(); }
	 when ('ALB') 	{  alter_sql_baseline(); }
	 when ('EXB')   {  export_sql_baseline(); }
	 when ('IMB')   {  import_sql_baseline(); }
	 when ('CRP') 	{  create_sql_patch(); }
	 when ('SHP') 	{  show_sql_patch(); }
	 when ('INV') 	{  investigate(); }
	 when ('PAR') 	{  parameter_check(); }
	 when ('DRO') 	{  drop_baseline(); }	 
     #default{ $response = 'Q'; }
}

} while ($response ne 'Q');



# # Creation/Preparation du fichier sql a lancer
# # nom du fichier : request.sql
# open my $of, ">", "request.sql";
# $of->say($sqlplus_settings);
# $of->say("select * from v\$instance;");
# $of->say("exit;");
# close $of;




say 'INFO : End of Performance Tool Kit';
say_time();






