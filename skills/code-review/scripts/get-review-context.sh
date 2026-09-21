#!/usr/bin/env bash
set -euo pipefail
pr="${1:-}"
[[ "$pr" =~ ^[0-9]+$ ]] || { echo "usage: get-review-context.sh <pr-number>" >&2; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "gh is required" >&2; exit 1; }
repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
echo '=== PR ==='
gh pr view "$pr" --json number,title,body,url,state,baseRefName,headRefName,author,labels,statusCheckRollup
echo
echo '=== DIFF ==='
gh pr diff "$pr"
echo
echo '=== INLINE REVIEW COMMENTS ==='
gh api "repos/${repo}/pulls/${pr}/comments"
echo
echo '=== CONVERSATION COMMENTS ==='
gh api "repos/${repo}/issues/${pr}/comments"
