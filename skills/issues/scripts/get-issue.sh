#!/usr/bin/env bash
set -euo pipefail
number="${1:-}"
[[ "$number" =~ ^[0-9]+$ ]] || { echo "usage: get-issue.sh <issue-number>" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
gh issue view "$number" --json number,title,body,url,state,labels,assignees,author,comments
