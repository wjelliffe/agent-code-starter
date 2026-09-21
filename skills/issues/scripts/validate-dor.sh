#!/usr/bin/env bash
set -euo pipefail
file="${1:-}"
[[ -f "$file" ]] || { echo "usage: validate-dor.sh <issue-body-file>" >&2; exit 2; }
missing=0
if ! grep -Eiq '^#{1,6}[[:space:]]+(Problem|Objective)([[:space:]]|$)' "$file"; then
  echo "DOR_MISSING=Problem or Objective heading"; missing=1
fi
if ! grep -Eiq '^#{1,6}[[:space:]]+Acceptance Criteria([[:space:]]|$)' "$file"; then
  echo "DOR_MISSING=Acceptance Criteria heading"; missing=1
fi
if ! grep -Eq '^[-*][[:space:]]+(.+)$' "$file"; then
  echo "DOR_MISSING=at least one actionable bullet"; missing=1
fi
if [[ "$missing" -ne 0 ]]; then echo 'DOR_STATUS=BLOCKED'; exit 1; fi
echo 'DOR_STATUS=READY'
