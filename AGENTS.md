# PerfToolKit engineering record

## Identity, ownership, and scope

PerfToolKit is an Oracle performance investigation and plan-management toolkit maintained by David Cherel (author recorded in `perf_tool_kit.pl`). Intended audience: Oracle DBAs. Deliverables are SQL*Plus scripts, an interactive Perl launcher, configuration script, and reports. Scope includes SQL discovery, plans, optimizer statistics, baselines, patches, profiles, and incident analysis. General operating-system administration is outside scope.

Environment status: source targets Oracle Database, including RAC, multitenant, AWR and Statspack workflows. The launcher contains an Oracle 19c home path; this is not evidence of certification. Exact supported database releases, editions, OS versions, and dependency versions remain unverified. The configuration script assumes a Unix Oracle server, Bash, GNU-style `sed -i`, and local PMON visibility. Native macOS, Windows, and AIX bootstrap compatibility is unverified; `perf_tool_kit_windows_old.pl` is a legacy artifact.

## Primary References

Authoritative references to verify against the target database release: Oracle Database PL/SQL Packages and Types Reference (`DBMS_SQLDIAG`, `DBMS_SPM`, `DBMS_STATS`, `DBMS_XPLAN`, `DBMS_SQLTUNE`); Oracle Database Reference (dynamic performance and historical views); SQL*Plus User's Guide and Reference (`SPOOL` and substitution variables); Oracle Database Licensing Information User Manual. Oracle 19c is a source-context reference, not a declared support boundary. Documentation edition, publication dates, and deployment-specific feature eligibility have not yet been validated. Reference inventory recorded 2026-10-24.

## Repository map and architecture

- Root `*.sql`: diagnostic reports and explicit administrative actions.
- `perf_tool_kit.pl`: interactive launcher, version 1.9 in source; uses DBI and DBD::Oracle.
- `config.sh`: probes the local Oracle environment, rewrites the launcher shebang, and generates `PerfToolKit_parameters.conf`.
- `README.txt`: existing setup and usage instructions.
- `PTK_services_catalogue.md`: script catalogue.
- `*.log`, `*.txt`: reports, examples, or historical artifacts; not proof of current successful execution.

Control flow: configuration -> launcher -> Oracle queries/SQL*Plus scripts -> terminal and spool files. Some scripts modify database metadata; exports/imports use staging tables and Data Pump.

## Reproducible bootstrap

External prerequisites: running target Oracle instance and configured Oracle Home; `oraenv`, SQL*Plus, Bash, Perl with DBI/DBD::Oracle, and Data Pump for transfer workflows. Runtime/module versions are not pinned and must be recorded before claiming reproducible deployment.

Existing README procedure, unverified in this checkout:

```bash
. oraenv <<< MYDBINSTANCE
chmod +x config.sh
./config.sh
perl perf_tool_kit.pl
```

Replace `MYDBINSTANCE` with the actual instance. Run from the repository root. Expected configuration output is `PerfToolKit_parameters.conf`; expected launcher output is an interactive menu. There is no documented build step. Bootstrap requires external Oracle state and cannot be validated from a checkout alone.

## Configuration, permissions, and secrets

Required environment: `ORACLE_HOME`, `ORACLE_SID`; configuration also records `PTK_DIAG_PACK`, `PTK_MULTITENANT_DB`, `PTK_STATSPACK`, and `PTK_EDITION`. The existing launcher/configuration use local OS-authenticated SYSDBA access. Individual SQL scripts require access to their referenced views/packages; a least-privilege grant matrix is not yet documented. Do not infer feature authorization from technical availability.

Provision and revoke OS/database access through the target environment's DBA process. Password/token rotation is not applicable to the current OS-authenticated connection mechanism; external account lifecycle remains site-specific. Never add credentials, private keys, tokens, wallets, or unredacted connection strings. Treat reports and existing historical files as potentially sensitive.

## Interfaces and operating model

Scripts use SQL*Plus positional substitution parameters (`&1`, etc.); consult each header for arguments and effects. Reports commonly use fixed spool names and may overwrite previous output. Many scripts exit SQL*Plus. `drop_sql_patch.sql` accepts a patch name and writes `drop_sql_patch.log`; it performs patch deletion and is not a read-only validation command.

## Deployment and recovery

Deployment means checking out the chosen revision into an Oracle administrative environment and generating local configuration. No service installation is documented. Preserve reports/configuration before upgrades; restore a prior Git revision for code rollback. Code rollback does not undo database actions. Database recovery is action-specific: for patch deletion, preserve the original patch definition and its recreation procedure beforehand. A universal database rollback procedure is not established.

## Validation

Static check for the log-name correction, from the repository root:

```bash
rg -n 'writes output to|^spool ' drop_sql_patch.sql
git diff --check -- drop_sql_patch.sql AGENTS.md
```

Pass criteria: the description and opening spool statement name `drop_sql_patch.log`, and no whitespace errors are reported. On 2026-10-24 these static checks passed. Oracle execution and bootstrap are unverified; no database-changing script was executed for this correction.

## Decisions and change trace

- 2026-10-24: corrected the output description in `drop_sql_patch.sql` to match its existing `spool drop_sql_patch.log` command. Documentation-only change; no SQL interface or runtime behavior change. Verified using the static checks above. Added this root record as required by the project's engineering-record instructions. Existing unrelated working-tree modifications were preserved. The correction was prepared for `main` in an isolated checkout; unrelated `workflow` edits were excluded.
