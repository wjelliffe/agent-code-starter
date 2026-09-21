#!/usr/bin/env bash
set -euo pipefail
parent="${1:-}"; child="${2:-}"
[[ "$parent" =~ ^[0-9]+$ && "$child" =~ ^[0-9]+$ ]] || { echo "usage: link-sub-issue.sh <parent-number> <child-number>" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
child_id="$(gh api "repos/${repo}/issues/${child}" --jq .id)"
gh api --method POST "repos/${repo}/issues/${parent}/sub_issues" -F "sub_issue_id=${child_id}" >/dev/null
printf 'ACS_PARENT=%s\nACS_CHILD=%s\nACS_LINKED=true\n' "$parent" "$child"
