# fork-admin work log

Running record of what's done and what's left, for the A -> B fork
(menu allowlist, Oracle 19c copy, disabling Redis/MQ/XXL-Job/outbound
HTTP). Update this file as work progresses.

## Done

- **2026-08-03** — Confirmed system A is in-house/self-developed, not
  built on an open-source admin template.
- **2026-08-03** — Confirmed the two Oracle schemas: `SALESYS` and
  `SALESYSFLOW`.
- **2026-08-03** — Ran the cross-schema dependency check
  (`cross_schema_dependency_check.sql`) — zero rows returned for
  foreign keys, synonyms, and `all_dependencies` in both directions.
  The two schemas have no cross-references; they can be
  exported/imported independently.
- **2026-08-03** — Confirmed this is a one-time, point-in-time full
  copy (DDL + DML), not an ongoing sync — data added to A after the
  copy point does not need to carry over. Both source and target DB
  environments for this copy are non-production.
- **2026-08-03** — Checked app code and DB-stored code for hardcoded
  schema-qualified references (`SALESYS.` / `SALESYSFLOW.`) — none
  found, all references are unqualified (rely on the connected user's
  default schema). This means the target-side schema rename (prefix)
  is safe and won't break any SQL/MyBatis mappers.

## In progress

- **Step 1 of the Oracle copy: generating the export (.dmp) file(s).**
  Constraints as of 2026-08-03:
  - User can SSH into the DB server and `sudo su - oracle`.
  - User has passwords for the schema-owner accounts but is not sure
    whether those accounts carry elevated Data Pump privileges
    (`DATAPUMP_EXP_FULL_DATABASE`) or not.
  - Requirement: no parameter file, no reliance on ambient shell
    environment variables (the server is shared with other users) —
    every value spelled out explicitly on the command line.
  - Plan: export each schema as a separate job, connecting as that
    schema's own owner account — exporting **your own** schema needs
    no elevated Data Pump role, only a `DIRECTORY` object with
    READ/WRITE granted to it. This sidesteps the open question about
    whether the schema-owner accounts have `DATAPUMP_EXP_FULL_DATABASE`
    entirely.
  - **2026-08-04** — Confirmed `ORACLE_SID=orcl` (via `echo $ORACLE_SID`
    after `sudo su - oracle`, already set by that user's shell profile
    — only one instance on this box) and `DIR_PATH=/home/oracle/dumps`.
    `step1_export_salesys_salesysflow.sh` rewritten as a manual runbook
    (numbered copy/paste blocks, not a one-shot script — user runs each
    command by hand) with both values filled in. Passwords are
    intentionally left out of the file entirely: `expdp` prompts for
    them interactively when omitted from the connect string, which
    also avoids them showing up in shell history or `ps -ef` on this
    shared server. Ready to run — next action is executing the 6
    blocks in that file.
  - **2026-08-04** — Checked source DB's `NLS_CHARACTERSET` ahead of
    schedule (this is really step 1 of the "to do" list below, but
    source side was easy to check while already SSH'd in):
    ```sql
    SELECT parameter, value FROM nls_database_parameters WHERE parameter = 'NLS_CHARACTERSET';
    ```
    Source (`SALESYS`/`SALESYSFLOW`'s DB) returned `ZHS16GBK`. Target
    side still unchecked — needs the same query once the target
    Oracle 19c instance is identified/created. They must match (or
    target must be a proper superset) or Chinese text import will
    silently corrupt/truncate with no error.

## To do (later steps, not yet started)

1. Verify `NLS_CHARACTERSET` matches between source and target Oracle
   instances before importing (mismatched character sets silently
   corrupt Chinese text on import, no error raised).
2. Transfer the exported `.dmp` file(s) to the target host (any
   transfer method — it's a plain portable file, no network link
   between source and target DB required).
3. On the target host: confirm an Oracle 19c instance/PDB already
   exists; create the new prefixed schema users + tablespace; run
   `impdp` with `REMAP_SCHEMA` (and `REMAP_TABLESPACE` if the
   tablespace names differ between source and target).
4. Post-import: run `utlrp.sql` to recompile invalid objects, spot
   check row counts against the source, then repoint system B's
   datasource config (host/port/service name, username/password) at
   the new schema users so it runs fully independent of system A's
   database.
5. Hide all menus in system B except the 2 required ones, via the menu
   table's visibility flag (not deletion) — keep ancestor nodes of the
   2 kept menus visible too. User is handling this directly; also
   decide whether hiding needs to be paired with removing the
   corresponding role-menu permission mappings if API-level blocking
   (not just UI hiding) is required.
6. Audit and disable Redis, MQ, XXL-Job, any plain `@Scheduled` tasks,
   and all outbound HTTP calls (including OCR). Since the code was
   copied wholesale from system A, the real risk is the app still
   trying to reach these services in the new environment and failing —
   at minimum needs: (a) excluding the relevant Spring Boot
   auto-configuration (not just blanking connection config), and (b)
   fixing/removing the code call sites that `@Autowire` those clients,
   since excluding the autoconfiguration alone turns a runtime
   connection failure into a startup "bean not found" failure instead.
