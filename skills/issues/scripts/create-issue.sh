#!/usr/bin/env bash
set -euo pipefail
title="${1:-}"
body_file="${2:-}"
[[ -n "$title" && -f "$body_file" ]] || { echo "usage: create-issue.sh <title> <body-file> [label ...]" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
shift 2
args=(issue create --title "$title" --body-file "$body_file")
for label in "$@"; do args+=(--label "$label"); done
url="$(gh "${args[@]}")"
number="$(gh issue view "$url" --json number --jq .number)"
printf 'ACS_ISSUE_NUMBER=%s\nACS_ISSUE_URL=%s\n' "$number" "$url"
