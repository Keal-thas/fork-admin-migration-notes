---
name: project-fork-admin-restricted-machine-setup
description: "fork-admin's real target/dev environment shares constraints with the machine documented in the opencode-qwen-prompt repo (no internet, Windows, git-bash, single-user)"
metadata: 
  node_type: memory
  type: project
  originSessionId: e587847d-bfb7-40a9-a810-b6c2110e553b
  modified: 2026-08-03T13:12:40.404Z
---

On 2026-08-03 the user pointed at a sibling local repo,
`C:\Users\DecVens\Desktop\codes\opencode-qwen-prompt`, saying it
documents a "restricted machine" (受限机器) relevant to fork-admin.
**Correction, same day:** the ask was only to look at that machine's
characteristics for context, not to copy the repo's files into
fork-admin — an initial full copy into `fork-admin/opencode-qwen-prompt/`
was made and then removed at the user's clarification. Do not recreate
that copy.

The restricted-machine characteristics worth carrying over as context:
single-user, Windows, accessed via git-bash, **no internet access at
all** (code/tools have to be transferred in as a zip from a separate
machine that does have internet), reaches a model-serving API only
over the local network. That other repo's actual content (opencode +
Qwen system-prompt override config) is specific to *that* repo's own
problem and is not itself part of fork-admin.

**Why relevant to fork-admin:** read together with
[[project-fork-admin-overview]], fork-admin's own requirements (menu
allowlist, Oracle migration, stripping Redis/MQ/XXL-Job/outbound HTTP)
line up with a system meant to run somewhere locked-down/offline too —
so this is background context for *why* fork-admin looks the way it
does, not a mandate to reuse that other repo's files.

**How to apply:** Don't assume this Claude Code session runs on that
restricted machine (it very likely doesn't — this session has network
access). When advising on fork-admin, keep in mind the eventual
deployment target may have no outbound internet at all, which reinforces
why outbound-HTTP-dependent features need to be fully disabled, not just
config-pointed at an unreachable host.
