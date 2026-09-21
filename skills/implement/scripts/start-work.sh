#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${script_dir}/common.sh"

work_key="${1:-}"
mode="${2:-inplace}"
[[ -n "$work_key" ]] || { echo "usage: start-work.sh <work-key> [inplace|worktree]" >&2; exit 2; }
[[ "$mode" == "inplace" || "$mode" == "worktree" ]] || { echo "mode must be inplace or worktree" >&2; exit 2; }
acs_require_command git

root="$(acs_repo_root)"
slug="$(acs_slug "$work_key")"
branch="$(acs_branch_prefix)${slug}"
trunk="$(acs_trunk_branch)"

[[ -z "$(git -C "$root" status --porcelain)" ]] || { echo "refusing setup with a dirty working tree" >&2; exit 1; }
git -C "$root" show-ref --verify --quiet "refs/heads/${trunk}" || { echo "trunk branch not found: ${trunk}" >&2; exit 1; }

if [[ "$mode" == "inplace" ]]; then
  if git -C "$root" show-ref --verify --quiet "refs/heads/${branch}"; then
    git -C "$root" checkout "$branch" >/dev/null
  else
    git -C "$root" checkout "$trunk" >/dev/null
    git -C "$root" checkout -b "$branch" >/dev/null
  fi
  printf 'ACS_BRANCH=%s\nACS_PATH=%s\nACS_TRUNK=%s\n' "$branch" "$root" "$trunk"
  exit 0
fi

repo_name="$(basename "$root")"
worktree_path="$(cd "$(dirname "$root")" && pwd)/${repo_name}-${slug}"
if [[ -d "$worktree_path" ]]; then
  existing="$(git -C "$worktree_path" branch --show-current 2>/dev/null || true)"
  [[ "$existing" == "$branch" ]] || { echo "existing worktree is on ${existing}, expected ${branch}" >&2; exit 1; }
elif git -C "$root" show-ref --verify --quiet "refs/heads/${branch}"; then
  git -C "$root" worktree add "$worktree_path" "$branch" >/dev/null
else
  git -C "$root" worktree add -b "$branch" "$worktree_path" "$trunk" >/dev/null
fi
printf 'ACS_BRANCH=%s\nACS_PATH=%s\nACS_TRUNK=%s\n' "$branch" "$worktree_path" "$trunk"
