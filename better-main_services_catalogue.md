# PerfToolKit Services Catalogue (better-main)

Classification basis: **full extended header analysis** (PURPOSE + INPUT PARAMETERS + OUTPUT DESCRIPTION + QUESTIONS), with weighted intent scoring.

- SQL files scanned in `better-main`: **74**
- Services catalogued (compliant extended PURPOSE found): **73**
- Files skipped (missing compliant extended PURPOSE header): **1**

## IDN — Identify SQL_ID from text/signature/source

| SQL File | Service (from PURPOSE line) |
|---|---|
| `cursor_reason.sql` | Displays cursor not-shared reasons for a SQL_ID by extracting V$SQL_SHARED_CURSOR XML reason details and aggregating them per child cursor. |
| `find_matching_signature.sql` | Finds SQL statements sharing exact or force matching signatures with an input SQL_ID using V$SQL, and reports execution performance metrics to identify related expensive statements and potential cursor/literal variations. |
| `find_matching_signature_statspack.sql` | Finds SQL statements in Statspack snapshots that share exact or force matching signatures with an input SQL_ID by joining STATS$ SQL usage, text, and summary signature information. |
| `find_spd.sql` | Lists SQL Plan Directives associated with a specified schema from DBA_SQL_PLAN_DIRECTIVES and DBA_SQL_PLAN_DIR_OBJECTS, and provides a summary of directive/object and column-level links. |
| `find_sql_awr_template.sql` | Searches AWR history for SQL statements containing an input SQL text extract and reports SQL_ID, plan hash value, and key performance metrics to identify costly historical statements. |
| `find_sql_in_sql_set.sql` | Finds a specific SQL_ID inside a given SQL Tuning Set and lists associated plan hash values and execution metrics from DBMS_SQLTUNE.SELECT_SQLSET. |
| `find_sql_statspack_template.sql` | Searches Statspack SQL text for a provided text extract and returns matching SQL_ID, plan hash value, and signature details to identify related historical statements. |
| `find_sql_template.sql` | Searches SQL statements in library cache (V$SQL) using an input SQL text extract and reports SQL_ID, child cursor, plan hash, and key performance metrics to identify expensive candidates. |
| `find_sql_with_sql_id.sql` | Displays library cache cursor details and performance metrics for a specific SQL_ID from V$SQL, including child cursors, plan hash values, activity timestamps, and average execution/I/O/CPU indicators. |
| `plan_change_statspack.sql` | Analyzes Statspack history for a SQL_ID to display performance metrics by instance and plan hash value, helping identify plan-related performance differences. |
| `rsm_html.sql` | Generates an HTML SQL Monitor report for a specified SQL_ID using DBMS_SQL_MONITOR.REPORT_SQL_MONITOR and writes it to a local SQL*Plus spool file. |
| `spd_sqlid_diagnosis.sql` | Diagnoses SQL Plan Directive relevance for a SQL_ID (optionally one child cursor), correlating plan objects with directives and showing related object/column statistics and extended stats metadata. |
| `suppress_cursor_from_lib_cache.sql` | Purges a parent cursor from library cache for a given SQL_ID by deriving ADDRESS/HASH_VALUE and invoking DBMS_SHARED_POOL.PURGE. |

## ANL — Analyze execution plans and plan sources

| SQL File | Service (from PURPOSE line) |
|---|---|
| `adaptive_plan_sqlid_diagnosis.sql` | Diagnoses adaptive execution plan behavior for a SQL_ID (optionally a child cursor), showing full adaptive plan and analyzing STATISTICS COLLECTOR branches to identify likely cardinality misestimate suspects. |
| `cardinality_misestimate_diagnosis.sql` | Diagnoses cardinality misestimates for a SQL_ID from cursor cache by comparing estimated versus actual rows, identifying hotspot operations, correlating predicates/statistics health, and optionally gathering pending statistics for validation. |
| `dynamic_stats_diagnosis.sql` | Diagnoses dynamic statistics usage for a SQL_ID/child cursor by reading DBMS_XPLAN note text, extracting sampling level, and correlating results with session optimizer environment values. |
| `get_plan.sql` | Retrieves execution plan information from library cache for a SQL_ID, including cursor performance summary and detailed DBMS_XPLAN output with runtime statistics and outline/adaptive details. |
| `get_plan_awr.sql` | Retrieves execution plan details from AWR for a SQL_ID (optionally filtered by PLAN_HASH_VALUE), including historical performance summary and DBMS_XPLAN workload repository plan output. |
| `get_plan_statspack.sql` | Displays execution plan lines from Statspack plan repository for a specified PLAN_HASH_VALUE using DBMS_XPLAN.DISPLAY on PERFSTAT.STATS$SQL_PLAN. |
| `ses_optimizer_env_by_sid.sql` | Displays optimizer environment settings for a specific session SID from V$SES_OPTIMIZER_ENV, including parameter value, default flag, and related SQL feature context. |
| `sql_exec_query.sql` | Enables execution statistics at session level, runs a sample query, and displays last cursor execution plan with allstats/note information for quick execution-plan diagnostics. |
| `stats_feedback_diagnosis.sql` | Diagnoses statistics/cardinality feedback behavior for a SQL_ID (optionally child cursor), checking feedback parameter state, cursor reoptimization indicators, plan notes, and reoptimization hints. |

## HIS — Investigate history / instability / regressions

| SQL File | Service (from PURPOSE line) |
|---|---|
| `awr_plan_change.sql` | Analyzes AWR history for a SQL_ID to identify plan hash changes and performance evolution over time, and lists other SQL_IDs sharing the same force matching signature. |
| `awr_plan_change_on_object.sql` | Analyzes AWR history for SQL statements referencing a specific object name, showing plan hash performance evolution and summary metrics to detect plan changes and regressions linked to that object. |
| `create_awr_snapshot.sql` | Creates an AWR snapshot using DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT to persist current performance data into AWR tables, helping preserve workload and execution plan information for later analysis. |
| `create_statspack_snapshot.sql` | Creates a Statspack snapshot using PERFSTAT.STATSPACK.SNAP to persist current performance statistics, helping preserve workload evidence and SQL execution context for later Statspack-based analysis. |
| `dbtime.old.sql` | Reports top AWR snapshot intervals by DB Time, with optional instance and snapshot-range filters, to identify busiest historical periods. |
| `dbtime.sql` | Reports top AWR snapshot intervals by DB Time with optional instance and snapshot-range filters, helping identify busiest periods for targeted performance investigation. |
| `find_sql_with_sql_id_awr.sql` | Analyzes AWR history for a specific SQL_ID, showing snapshot-level performance metrics and a plan-hash summary to identify execution behavior and elapsed-time variability over time. |
| `parameters_mods.sql` | Lists AWR-recorded initialization parameter value changes over time (including hidden parameters), showing previous and new values per instance/container and snapshot. |
| `restore_table_stats.sql` | Restores table statistics (including related column/index stats) to a specified historical timestamp using DBMS_STATS.RESTORE_TABLE_STATS. |
| `stats_hist.sql` | Displays current and historical table statistics versions for objects referenced by a SQL_ID, combining cursor/AWR object references and optimizer stats history metadata. |
| `table_stats_complete.sql` | Produces a comprehensive table statistics report for a specified owner/table, including structure, current stats, history diff, partition/index details, and column-level statistics/histograms support data. |
| `unstable_plans.sql` | Identifies SQL statements with potential execution-plan instability in AWR by comparing average elapsed time across plans and ranking SQL_IDs by normalized standard deviation. |
| `unstable_plans_statspack.sql` | Identifies SQL statements with potential execution-plan instability from Statspack data by comparing average elapsed time across plans and ranking SQL_IDs by normalized standard deviation. |
| `whats_changed.sql` | Identifies SQL statements whose average elapsed time changed significantly before versus after a reference date (SYSDATE-days_ago) using AWR history, returning slower/faster SQL candidates ranked by normalized variability and execution impact. |

## FIX — Stabilize with Baseline / Patch / Profile

| SQL File | Service (from PURPOSE line) |
|---|---|
| `add_sql_plan_to_baseline_cursor_cache.sql` | Adds a plan from cursor cache into an existing SQL baseline (SQL handle), then renames the newly loaded plan to SQLID_<SQL_ID>_<PLAN_HASH_VALUE> for easier baseline identification. |
| `alter_sql_plan_from_baseline.sql` | Alters attributes of an existing SQL Plan Baseline plan (FIXED and ENABLED flags) for a specified SQL handle and plan name using DBMS_SPM.ALTER_SQL_PLAN_BASELINE. |
| `create_sql_baseline_awr.sql` | Creates a SQL Plan Baseline from AWR for a specified SQL_ID and PLAN_HASH_VALUE, loads it through a temporary SQL tuning set, renames the baseline, and optionally sets FIXED and ENABLED attributes. |
| `create_sql_baseline_cursor_cache.sql` | Creates a SQL Plan Baseline from cursor cache for a given SQL_ID and PLAN_HASH_VALUE, optionally sets FIXED and ENABLED flags, then renames the created baseline to SQLID_<SQL_ID>_<PLAN_HASH_VALUE>. |
| `create_sql_patch.sql` | Creates a SQL Patch for a specified SQL_ID using provided optimizer hint text and patch name through SYS.DBMS_SQLDIAG.CREATE_SQL_PATCH, and logs execution output to create_sql_patch.log. |
| `create_sql_profile.sql` | Creates or replaces a SQL Profile from a SQL Tuning Advisor task using DBMS_SQLTUNE.ACCEPT_SQL_PROFILE, with input validation, configurable FORCE_MATCH behavior, and post-creation profile detail reporting. |
| `create_sql_set_awr_snap.sql` | Creates a SQL Tuning Set from AWR snapshots within a specified snapshot range, excluding selected system schemas, and loads captured statements/plans for later analysis or baseline operations. |
| `create_sql_set_library_cache.sql` | Creates a SQL Tuning Set from current library cache statements, excluding selected system schemas, and loads captured SQL/plans with full attributes for later tuning, analysis, or baseline management operations. |
| `drop_sql_baseline.sql` | Drops all SQL Plan Baselines associated with a specified SQL handle from the SQL Plan Management repository using DBMS_SPM.DROP_SQL_PLAN_BASELINE. |
| `drop_sql_patch.sql` | Drops a SQL Patch by name using SYS.DBMS_SQLDIAG.DROP_SQL_PATCH and logs execution output for operational traceability. |
| `drop_sql_plan.sql` | Drops a specific SQL Plan Baseline by PLAN_NAME from the SQL Plan Management repository using DBMS_SPM.DROP_SQL_PLAN_BASELINE. |
| `drop_sql_profile.sql` | Drops a SQL Profile by name using DBMS_SQLTUNE.DROP_SQL_PROFILE, with input validation, safe SQL*Plus runtime settings, and post-drop verification query against DBA_SQL_PROFILES. |
| `drop_sql_set.sql` | Drops a SQL Tuning Set by name using DBMS_SQLSET.DROP_SQLSET and cleans SQL*Plus substitution variables at script end. |
| `export_all_sql_baselines.sql` | Exports all SQL Plan Baselines by packing them into a staging table and exporting that table with Data Pump to a dump file in DATA_PUMP_DIR for transfer or later import. |
| `export_sql_baseline_all_plans.sql` | Exports all plans for a specific SQL handle from SQL Plan Baselines by packing them into a staging table and exporting that table through Data Pump to a dump file. |
| `export_sql_baseline_plan.sql` | Exports one specific SQL Plan Baseline plan by PLAN_NAME by packing it into a staging table and exporting that table through Data Pump to a dump file. |
| `export_sql_set.sql` | Exports a SQL Tuning Set by packing it into a staging table and exporting that table with Data Pump to a dump file for transfer or later import. |
| `get_plan_sql_baseline.sql` | Displays the execution plan stored in SQL Plan Baseline repository for a given baseline PLAN_NAME using DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE. |
| `import_sql_baseline_all_plans.sql` | Imports SQL Baseline staging data from a Data Pump dump file, identifies the freshly imported staging table, unpacks all baseline plans into SPM, then drops the staging table. |
| `monitor_sql.sql` | Creates a SQL Patch with MONITOR hint for a specified SQL_ID using DBMS_SQLDIAG.CREATE_SQL_PATCH to force SQL Monitoring for that statement. |
| `show_last_day_sql_baselines.sql` | Displays SQL Plan Baselines created during the last day, including SQL handle, plan name, SQL text, status flags, and verification/execution timestamps. |
| `show_last_hour_sql_baselines.sql` | Displays SQL Plan Baselines created during the last hour, including SQL handle, plan name, SQL text, status flags, and verification/execution timestamps. |
| `show_sql_baselines.sql` | Displays SQL Plan Baselines with SQL handle, plan name, SQL text excerpt, status flags (enabled/accepted/fixed), and last execution timestamp by joining DBA_SQL_PLAN_BASELINES with SQL metadata. |
| `show_sql_baselines_sql_handle.sql` | Displays SQL Plan Baselines filtered by an input SQL_HANDLE, showing baseline identity, SQL text excerpt, status flags, and verification/execution timestamps to review plans associated with one SQL handle. |
| `show_sql_baselines_sql_plan.sql` | Displays SQL Plan Baselines filtered by an input PLAN_NAME, returning baseline identifiers, SQL text excerpt, status flags, and verification/execution timestamps to inspect one specific baseline plan or matching plan name pattern. |
| `show_sql_baselines_with_SQLID.sql` | Displays SQL Plan Baselines whose PLAN_NAME follows the SQLID naming pattern (SQLID_% ), showing baseline identifiers, SQL text excerpt, status flags, and last execution timestamp for SQLID-based baseline review. |
| `show_sql_baselines_with_SQLID_old.sql` | Displays SQL Plan Baseline details for an input PLAN_NAME (legacy variant), including SQL handle, plan id/hash, SQL text, status flags, and verification/execution timestamps. |
| `show_sql_patches.sql` | Displays SQL Patch definitions from DBA_SQL_PATCHES, including patch name, SQL text, status, creation time, and last modification time, and writes execution output to show_sql_patches.log. |
| `show_sql_profiles.sql` | Generates a read-only SQL Profiles report from DBA_SQL_PROFILES with optional profile name filtering, detailed profile attributes, and a count summary, while spooling output to show_sql_profiles.log. |
| `swap_good_bad_plan_sql_baseline_cursor_cache.sql` | Replaces a bad execution plan baseline with a good one by loading both from cursor cache, disabling/removing the bad plan, attaching and fixing the good plan, and renaming resulting baseline plan. |

## VAL — Validate / Monitor

| SQL File | Service (from PURPOSE line) |
|---|---|
| `acs_diagnosis.sql` | Produces an Adaptive Cursor Sharing diagnosis report for a SQL_ID (optionally one child cursor), combining parameter checks, cursor performance, split reasons, bind capture, and ACS selectivity/statistics/histogram views. |
| `drop_spd.sql` | Drops SQL Plan Directives linked to a specified schema object by scanning DBA_SQL_PLAN_DIR_OBJECTS, removing each directive via DBMS_SPD, then displaying remaining directives for the schema. |
| `histogram_pending_stats_advisor.sql` | Advises and optionally applies pending histogram statistics workflow for a target table column, using column stats and SYS.COL_USAGE$ evidence to support skew diagnosis and controlled validation. |
| `lock_table_stats.sql` | Locks optimizer statistics for a specified table using DBMS_STATS.LOCK_TABLE_STATS and verifies lock status from DBA_TAB_STATISTICS. |
| `mcp_smoke_test.sql` | Executes a minimal Oracle query to validate MCP-driven SQL execution flow, confirming database connectivity, statement execution, and result retrieval using a simple DUAL-based select statement without input parameters. |
| `show_sql_set.sql` | Displays SQL Tuning Sets available in the database from DBA_SQLSET, including name, owner, description, and last modification date, after setting session NLS date format for readable timestamp output. |
| `unlock_table_stats.sql` | Unlocks optimizer statistics for a specified table using DBMS_STATS.UNLOCK_TABLE_STATS and verifies lock status from DBA_TAB_STATISTICS. |

## Skipped SQL files (non-compliant/missing extended PURPOSE)

| SQL File | Reason |
|---|---|
| `sql_exec_template.sql` | missing extended PURPOSE header line |
