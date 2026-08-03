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
    entirely. See `step1_export_salesys_salesysflow.sh` — still has a
    few values marked for the user to confirm (exact login usernames,
    OS directory path, host/port/service name).

## To do (later steps, not yet started)

1. Check for hardcoded schema-qualified references (`SALESYS.` /
   `SALESYSFLOW.`) in app code (Java / MyBatis XML / MyBatis-Plus
   annotations) and in DB-stored code (procedures/triggers/views) —
   see `check_hardcoded_schema_refs.sh` and
   `check_hardcoded_schema_refs.sql`. Matters because the target import
   renames both schemas with a prefix (user's example: `afogadmin_`,
   not yet confirmed as final).
2. Verify `NLS_CHARACTERSET` matches between source and target Oracle
   instances before importing (mismatched character sets silently
   corrupt Chinese text on import, no error raised).
3. Transfer the exported `.dmp` file(s) to the target host (any
   transfer method — it's a plain portable file, no network link
   between source and target DB required).
4. On the target host: confirm an Oracle 19c instance/PDB already
   exists; create the new prefixed schema users + tablespace; run
   `impdp` with `REMAP_SCHEMA` (and `REMAP_TABLESPACE` if the
   tablespace names differ between source and target).
5. Post-import: run `utlrp.sql` to recompile invalid objects, spot
   check row counts against the source, then repoint system B's
   datasource config (host/port/service name, username/password) at
   the new schema users so it runs fully independent of system A's
   database.
6. Hide all menus in system B except the 2 required ones, via the menu
   table's visibility flag (not deletion) — keep ancestor nodes of the
   2 kept menus visible too. User is handling this directly; also
   decide whether hiding needs to be paired with removing the
   corresponding role-menu permission mappings if API-level blocking
   (not just UI hiding) is required.
7. Audit and disable Redis, MQ, XXL-Job, any plain `@Scheduled` tasks,
   and all outbound HTTP calls (including OCR). Since the code was
   copied wholesale from system A, the real risk is the app still
   trying to reach these services in the new environment and failing —
   at minimum needs: (a) excluding the relevant Spring Boot
   auto-configuration (not just blanking connection config), and (b)
   fixing/removing the code call sites that `@Autowire` those clients,
   since excluding the autoconfiguration alone turns a runtime
   connection failure into a startup "bean not found" failure instead.
