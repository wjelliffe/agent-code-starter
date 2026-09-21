#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$root" ]] || { echo "summarize-diff.sh must run inside a git repository" >&2; exit 1; }
cd "$root"
echo '=== ACS DIFF SUMMARY ==='
echo "Branch: $(git branch --show-current)"
echo
printf '%s\n' '--- status ---'
git status --short
echo
printf '%s\n' '--- diff stat ---'
git diff --stat
echo
printf '%s\n' '--- changed files ---'
{
  git diff --name-only
  git ls-files --others --exclude-standard
} | awk 'NF && !seen[$0]++'
