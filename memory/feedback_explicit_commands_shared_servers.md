---
name: feedback-explicit-commands-shared-servers
description: "On shared servers, write commands with every value spelled out on the command line — no parameter files, no reliance on ambient shell/env-var state"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e587847d-bfb7-40a9-a810-b6c2110e553b
  modified: 2026-08-03T13:41:08.949Z
---

When writing shell/DB commands meant to run on a server other people
also use concurrently, avoid parameter files (`PARFILE=`) and avoid
depending on ambient environment variables that could differ per user
or per session (e.g. `$ORACLE_SID` set via `oraenv`, `$TNS_ADMIN`,
etc.). Put every value directly and explicitly on the command line
instead (e.g. a full EZCONNECT string `user/pass@//host:port/service`
rather than a bare TNS alias that depends on that shell's `tnsnames.ora`
resolution or current `$ORACLE_SID`).

**Why:** stated directly by the user during the fork-admin Oracle
Data Pump work (2026-08-03): "这个服务器不只是我一个人在用" (this server
isn't used by just me) — ambient env-var state on a shared box is
exactly the kind of thing that can silently differ between users'
sessions and cause a command to do the wrong thing without an obvious
error.

**How to apply:** Any time a command/script is destined for a
multi-user or shared environment (not a personal dev machine), default
to fully explicit, self-contained invocations. Doesn't apply to a
private single-user machine where relying on that user's own
configured environment is fine and often simpler.
