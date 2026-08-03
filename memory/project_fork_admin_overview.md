---
name: project-fork-admin-overview
description: "fork-admin is a fork/trim of an existing admin system (A) into a leaner new system (B); Oracle 19c, menu allowlisting, service disabling"
metadata: 
  node_type: memory
  type: project
  originSessionId: e587847d-bfb7-40a9-a810-b6c2110e553b
  modified: 2026-08-03T14:29:54.062Z
---

fork-admin (`C:\Users\DecVens\Desktop\codes\fork-admin`) forks an existing
admin console ("system A") into a trimmed new system ("B"). Scope, as of
2026-08-03:

1. **Menu hiding** — B keeps only two menus visible; everything else in
   A's menu tree is hidden via DB config (not deleted), so the two kept
   menus stay unaffected by future upstream merges from A.
2. **Database migration** — all of A's Oracle 19c data (two schemas)
   moves to B. User is actively working on this part first.
3. **Disable unused services** — Redis, MQ, XXL-Job (and any other
   scheduled/cron tasks), and all outbound HTTP calls to external
   services get disabled/removed in B.

**Why:** B is a cut-down deployment of A for a narrower use case — not
stated exactly why, but the shape (menu allowlist + infra stripped down
+ no outbound network) strongly suggests B runs in a more
locked-down/restricted environment than A did.

**How to apply:** When advising on any of these three areas, prefer
config/DB-driven toggles over deleting code or rows outright — keeps
the fork mergeable against upstream A and reversible. See
[[project-fork-admin-restricted-machine-setup]] for a related but
distinct restricted-machine detail (AI coding tool setup, not the app
architecture itself).

## Known facts (as of 2026-08-03)

- The two Oracle schemas being migrated are named **SALESYS** and
  **SALESYSFLOW**. Confirmed no cross-schema foreign keys, synonyms, or
  code-level (`all_dependencies`) references between them — user ran
  the check queries and got zero rows back, so the two schemas can be
  exported/imported independently without ordering concerns.
- Both source and target DB environments for this migration are
  **non-production** — user explicitly said performance/slowness
  doesn't matter, only that the migration completes correctly. Don't
  over-index on Data Pump performance tuning (PARALLEL, compression)
  when advising here.
- It's a **one-time, point-in-time full copy** (DDL + DML) — no need
  for incremental/delta sync design; data added to A after the copy
  point doesn't need to carry over.
- Roughly **400+ tables** in scope, across the two schemas combined.
- A working-notes/snippets repo for this project exists at
  **github.com/Keal-thas/fork-admin-migration-notes** (public, at the
  user's explicit request — they said sensitive info in it is fine).
  Used for pushing SQL snippets etc. the user wants easy access to from
  their restricted machine.
- **System A is in-house/self-developed (自研)**, not built on an
  open-source admin template like RuoYi. Don't assume RuoYi-specific
  table/config names apply — confirm actual names from the real
  codebase/schema instead of guessing from that framework's conventions.
- The Oracle copy target schemas get **renamed with a prefix** on
  import (user's own example was `afogadmin_`, not yet confirmed as
  final) via Data Pump `REMAP_SCHEMA` — meaning if system A's code ever
  hardcodes schema-qualified table references (e.g. `SALESYS.TABLE_X`
  in SQL/MyBatis mappers) rather than relying on the connected user's
  default schema, those references will break after the rename and need
  to be found and fixed. This is a real open risk to check, not yet
  confirmed either way.
- The target for this Oracle copy is explicitly **not necessarily the
  same machine** — the goal is a portable dump file importable onto any
  Oracle 19c host/IP, i.e. plain file-based Data Pump (no
  `NETWORK_LINK`), so the resulting copy can start up fully independent
  of the original A database.
- **Export privilege situation (2026-08-03):** user can SSH into the DB
  server and `sudo su - oracle`, but is unsure whether their
  schema-owner accounts (passwords known) carry elevated Data Pump
  roles (`DATAPUMP_EXP_FULL_DATABASE`). Resolution: export SALESYS and
  SALESYSFLOW as two **separate** `expdp` jobs, each connecting as that
  schema's own owner — exporting one's own schema needs no elevated
  role, only a `DIRECTORY` object granted READ/WRITE, which the
  `oracle` OS user (via `sqlplus / as sysdba` after `sudo su - oracle`)
  can set up once. Avoids ever needing to confirm the schema accounts'
  privilege level.
- User also wants everything spelled out explicitly on the command
  line (no `PARFILE`, no reliance on ambient env vars) since the DB
  server is shared with other people — see
  [[feedback-explicit-commands-shared-servers]].
- **Correction (2026-08-03):** user runs expdp locally on the DB server
  itself (already SSH'd in) — no host/port/service connect string
  needed at all, that was over-engineering on my part. A local
  bequeath connection (bare `user/password`, no `@...`) works fine;
  the only thing that matters is `ORACLE_SID`, passed inline per
  command (`ORACLE_SID=xxx expdp ...`) rather than exported into the
  shared shell, keeping it compatible with the shared-server/no-ambient-
  env-var preference. Real login usernames confirmed as literally
  `SALESYS` and `SALESYSFLOW`. Port is the Oracle default (1521) but
  irrelevant here since there's no network hop.
- A running work log lives in the migration-notes repo at
  `WORK_LOG.md` (github.com/Keal-thas/fork-admin-migration-notes) —
  keep it updated as steps complete rather than re-deriving status from
  this memory file each time.
