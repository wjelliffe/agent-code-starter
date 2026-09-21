#!/usr/bin/env bash
set -euo pipefail
file="${1:-}"
[[ -f "$file" ]] || { echo "usage: validate-plan.sh <plan-file>" >&2; exit 2; }
missing=0
for heading in 'Approach' 'Touch points' 'Invariants' 'Sequence' 'Tests' 'Risks'; do
  if ! grep -Eiq "^#{1,6}[[:space:]]+${heading}([[:space:]]|$)" "$file"; then
    echo "PLAN_MISSING=${heading}"; missing=1
  fi
done
status="$(grep -Eio '^PLAN_STATUS:[[:space:]]*(READY|BLOCKED)[[:space:]]*$' "$file" | tail -n 1 | sed -E 's/^PLAN_STATUS:[[:space:]]*//I' | tr '[:lower:]' '[:upper:]')"
if [[ -z "$status" ]]; then echo 'PLAN_MISSING=PLAN_STATUS: READY|BLOCKED'; missing=1; fi
if [[ "$missing" -ne 0 ]]; then echo 'PLAN_VALID=false'; exit 1; fi
printf 'PLAN_VALID=true\nPLAN_STATUS=%s\n' "$status"
