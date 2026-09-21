#!/usr/bin/env bash
set -euo pipefail
file="${1:-}"
[[ -f "$file" ]] || { echo "usage: validate-review.sh <review-file>" >&2; exit 2; }
last="$(awk 'NF{line=$0} END{print line}' "$file")"
if [[ "$last" != 'VERDICT: APPROVE' && "$last" != 'VERDICT: BLOCKERS' ]]; then
  echo 'REVIEW_VALID=false'
  echo 'REVIEW_ERROR=last non-empty line must be VERDICT: APPROVE or VERDICT: BLOCKERS'
  exit 1
fi
if ! grep -Eiq '^#{1,6}[[:space:]]+Findings([[:space:]]|$)' "$file"; then
  echo 'REVIEW_VALID=false'
  echo 'REVIEW_ERROR=missing Findings heading'
  exit 1
fi
printf 'REVIEW_VALID=true\n%s\n' "$last"
