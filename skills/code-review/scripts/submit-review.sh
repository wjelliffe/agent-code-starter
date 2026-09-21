#!/usr/bin/env bash
set -euo pipefail
pr="${1:-}"; file="${2:-}"
[[ "$pr" =~ ^[0-9]+$ && -f "$file" ]] || { echo "usage: submit-review.sh <pr-number> <review-file>" >&2; exit 2; }
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${script_dir}/validate-review.sh" "$file" >/dev/null
command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
gh pr review "$pr" --comment --body-file "$file"
printf 'ACS_REVIEW_POSTED=true\nACS_PR_NUMBER=%s\n' "$pr"
