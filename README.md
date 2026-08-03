# fork-admin migration notes

Working notes and reusable snippets for the fork-admin project: forking
an existing Oracle-based admin system (A) into a trimmed-down new system
(B) — menu allowlist, Oracle 19c data migration, disabling unused
services (Redis/MQ/XXL-Job/outbound HTTP).

## Contents

- `cross_schema_dependency_check.sql` — three queries to check whether
  two Oracle schemas have cross-schema foreign keys, synonyms, or any
  other object-level dependency (views/procedures/triggers referencing
  the other schema), before deciding whether they can be exported /
  imported independently via Data Pump.
