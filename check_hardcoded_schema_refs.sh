#!/usr/bin/env bash
# Search application source for hardcoded schema-qualified table
# references (SALESYS.xxx / SALESYSFLOW.xxx), which will break once
# the schemas are imported under renamed (prefixed) users.
#
# Usage: ./check_hardcoded_schema_refs.sh /path/to/project/source

set -euo pipefail

SRC_DIR="${1:?Usage: $0 /path/to/project/source}"

grep -rniE \
  --include='*.java' \
  --include='*.xml' \
  --include='*.sql' \
  --include='*.yml' \
  --include='*.yaml' \
  --include='*.properties' \
  '\b(SALESYS|SALESYSFLOW)\.' \
  "$SRC_DIR"
