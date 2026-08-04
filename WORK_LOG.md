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
  (`check_cross_schema_dependency.sql`) — zero rows returned for
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
- **Step 1 of the Oracle copy: export (.dmp) files — DONE.**
  - User can SSH into the DB server and `sudo su - oracle`; exported
    each schema as its own separate job, connecting as that schema's
    own owner account — sidesteps needing to know whether the
    schema-owner accounts carry `DATAPUMP_EXP_FULL_DATABASE`, since
    exporting your own schema only needs a `DIRECTORY` object with
    READ/WRITE granted to it.
  - `ORACLE_SID=orcl` (only one instance on this box). Every value
    (SID, directory, filenames) spelled out explicitly on the command
    line — no parameter file, no reliance on ambient shell env vars,
    since the DB server is shared with other users. Passwords
    intentionally left out of the runbook entirely — `expdp` prompts
    for them interactively, so they never land in shell history or
    show up to other users via `ps -ef`.
  - Source DB's `NLS_CHARACTERSET` checked: `ZHS16GBK`. Target side
    still needs the same check once the target Oracle 19c instance is
    identified/created (see "To do" below) — a mismatch silently
    corrupts/truncates Chinese text on import with no error raised.
  - **Disk-full incident, recovered:** SALESYSFLOW's first export
    attempt failed with "master table ... failed to load/unload" —
    root cause was `/home/oracle`'s filesystem hitting 100% used
    (SALESYS's dump alone filled that small partition, leaving no room
    for SALESYSFLOW's dump). Fixed by relocating dump output to
    `/opt/dumps` (separate volume with adequate free space): directory
    created with oracle-writable ownership, SALESYS's dump moved over,
    the `DIRECTORY` object repointed (`CREATE OR REPLACE DIRECTORY
    DP_DIR AS '/opt/dumps'`), the leftover failed SALESYSFLOW job
    cleaned up, and SALESYSFLOW re-exported into `/opt/dumps`.
  - **Confirmed 2026-08-04: both schemas' dump files are in
    `/opt/dumps`, both `.log` files show no `ORA-` errors.** Final
    values: `ORACLE_SID=orcl`, `DIR_PATH=/opt/dumps`.
    `step1_export_salesys_salesysflow.sh` updated to match and marked
    done in-file.

## In progress

- **Transferring the exported `.dmp` files off the DB server.** Plan:
  pull both files from the DB server to the user's local Windows
  machine via `scp`, run from the local machine (pulling, not pushed
  from the server) — not necessarily straight to the eventual target
  Oracle host yet.
  - **Open/unresolved:** file ownership on `/opt/dumps` is
    `oracle:<oracle's group>` — the user's own SSH login account may
    not have read permission on the dump files. Check with `ls -l
    /opt/dumps` before attempting the `scp`; if unreadable, `sudo
    chmod o+r` on both `.dmp` files is the quick fix. Not yet checked
    or confirmed in this session.

## To do (later steps, not yet started)

1. Verify `NLS_CHARACTERSET` matches between source (`ZHS16GBK`,
   confirmed) and target Oracle instances before importing (mismatched
   character sets silently corrupt Chinese text on import, no error
   raised). Target side not yet checked.
2. On the target host: confirm an Oracle 19c instance/PDB already
   exists; create the new prefixed schema users + tablespace; run
   `impdp` with `REMAP_SCHEMA` (and `REMAP_TABLESPACE` if the
   tablespace names differ between source and target).
3. Post-import: run `utlrp.sql` to recompile invalid objects, spot
   check row counts against the source, then repoint system B's
   datasource config (host/port/service name, username/password) at
   the new schema users so it runs fully independent of system A's
   database.
4. Hide all menus in system B except the 2 required ones, via the menu
   table's visibility flag (not deletion) — keep ancestor nodes of the
   2 kept menus visible too. User is handling this directly; also
   decide whether hiding needs to be paired with removing the
   corresponding role-menu permission mappings if API-level blocking
   (not just UI hiding) is required.
5. Audit and disable Redis, MQ, XXL-Job, any plain `@Scheduled` tasks,
   and all outbound HTTP calls (including OCR). Since the code was
   copied wholesale from system A, the real risk is the app still
   trying to reach these services in the new environment and failing —
   at minimum needs: (a) excluding the relevant Spring Boot
   auto-configuration (not just blanking connection config), and (b)
   fixing/removing the code call sites that `@Autowire` those clients,
   since excluding the autoconfiguration alone turns a runtime
   connection failure into a startup "bean not found" failure instead.
