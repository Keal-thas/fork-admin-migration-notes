# fork-admin migration notes

Working notes and reusable snippets for the fork-admin project: forking
an existing Oracle-based admin system (A) into a trimmed-down new system
(B) — menu allowlist, Oracle 19c data migration, disabling unused
services (Redis/MQ/XXL-Job/outbound HTTP).

## Contents

- `WORK_LOG.md` — running record of what's done and what's left.
- `check_cross_schema_dependency.sql` — three queries to check whether
  two Oracle schemas have cross-schema foreign keys, synonyms, or any
  other object-level dependency (views/procedures/triggers referencing
  the other schema), before deciding whether they can be exported /
  imported independently via Data Pump.
- `check_hardcoded_schema_refs.sh` / `check_hardcoded_schema_refs.sql` —
  find hardcoded `SALESYS.`/`SALESYSFLOW.` schema-qualified references
  in app code and in DB-stored code, before renaming either schema.
- `step1_export_salesys_salesysflow.sh` — Data Pump export step for the
  Oracle copy.
- `memory/` — a copy of this project's Claude Code cross-session memory
  files (kept here too so the context isn't only sitting on one local
  machine).
