---
name: feedback-flag-placeholders
description: "When writing scripts/configs with stand-in values (schema names, hosts, prefixes), explicitly call out each placeholder and ask for the real value before finalizing — don't silently leave generic stand-ins"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e587847d-bfb7-40a9-a810-b6c2110e553b
  modified: 2026-08-03T13:29:15.731Z
---

Don't write generic placeholder tokens (things like `SCHEMA1`,
`<your-host>`, example values presented as if final) into scripts,
configs, or files meant to be used for real, without first explicitly
flagging which parts are placeholders and asking the user for the real
values.

**Why:** in the fork-admin project (2026-08-03), the user asked
directly for this after I'd been writing generic placeholder schema
names — their point was that once something is drafted looking
plausible, it's easy for a placeholder to slip through unnoticed
instead of being swapped for the real value. They said explicitly: "如
果你写了占位符,你一定要跟我明确一下,然后我告诉你具体的字,你再写上去"
(if you write a placeholder, you must clarify it with me, then I'll
give you the actual value, before you write it in).

**How to apply:** Before finalizing any deliverable (script, config
file, command to run) that contains a stand-in value I don't actually
know (a name the user only gave as "for example," an IP/host/path I'm
guessing at, a password), stop and ask for the concrete value rather
than shipping a template and hoping it gets edited later. This applies
broadly, not just to Oracle schema names — any project where I'm
producing something meant to be run/used as-is.
