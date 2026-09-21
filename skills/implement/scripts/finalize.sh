#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${script_dir}/common.sh"

mode="${1:-}"
title="${2:-}"
number="${3:-}"
[[ "$mode" == "merge" || "$mode" == "pr" || "$mode" == "update-pr" || "$mode" == "merge-pr" ]] || {
  echo "usage: finalize.sh <merge|pr|update-pr|merge-pr> <title> [pr-number]" >&2; exit 2;
}
[[ -n "$title" ]] || title="Agent Code Starter change"
acs_require_command git
root="$(acs_repo_root)"
trunk="$(acs_trunk_branch)"
current="$(git -C "$root" branch --show-current)"

commit_changes() {
  [[ -n "$current" ]] || { echo "refusing finalization from detached HEAD" >&2; exit 1; }
  [[ "$current" != "$trunk" ]] || { echo "refusing to commit or finalize directly on trunk (${trunk})" >&2; exit 1; }
  git -C "$root" add -A
  if git -C "$root" diff --cached --quiet; then
    return 1
  fi
  git -C "$root" commit -m "$1" >/dev/null
  return 0
}

case "$mode" in
  pr)
    acs_require_command gh
    commit_changes "feat: ${title}" || { echo "no changes to finalize" >&2; exit 1; }
    git -C "$root" push -u origin "$current" >/dev/null
    url="$(cd "$root" && gh pr create --title "$title" --body "Implemented with Agent Code Starter." --base "$trunk" --head "$current")"
    pr_number="$(cd "$root" && gh pr view "$url" --json number --jq .number)"
    printf 'ACS_MODE=pr\nACS_PR_NUMBER=%s\nACS_PR_URL=%s\nACS_BRANCH=%s\n' "$pr_number" "$url" "$current"
    ;;
  update-pr)
    acs_require_command gh
    [[ "$number" =~ ^[0-9]+$ ]] || { echo "update-pr requires a numeric PR number" >&2; exit 1; }
    state="$(cd "$root" && gh pr view "$number" --json state --jq .state)"
    head="$(cd "$root" && gh pr view "$number" --json headRefName --jq .headRefName)"
    [[ "$state" == "OPEN" ]] || { echo "refusing to update PR #${number}: state is ${state}" >&2; exit 1; }
    [[ "$head" == "$current" ]] || { echo "refusing to update PR #${number}: current branch ${current} is not PR head ${head}" >&2; exit 1; }
    if commit_changes "fix: ${title}"; then
      git -C "$root" push origin "$current" >/dev/null
      printf 'ACS_MODE=update-pr\nACS_PR_NUMBER=%s\nACS_UPDATED=true\n' "$number"
    else
      printf 'ACS_MODE=update-pr\nACS_PR_NUMBER=%s\nACS_UPDATED=false\n' "$number"
    fi
    ;;
  merge-pr)
    acs_require_command gh
    [[ "$number" =~ ^[0-9]+$ ]] || { echo "merge-pr requires a numeric PR number" >&2; exit 1; }
    state="$(cd "$root" && gh pr view "$number" --json state --jq .state)"
    [[ "$state" == "OPEN" ]] || { echo "refusing to merge PR #${number}: state is ${state}" >&2; exit 1; }
    cd "$root"
    gh pr merge "$number" --squash
    printf 'ACS_MODE=merge-pr\nACS_PR_NUMBER=%s\nACS_MERGED=true\n' "$number"
    ;;
  merge)
    commit_changes "feat: ${title}" || { echo "no changes to finalize" >&2; exit 1; }
    branch="$current"
    git -C "$root" checkout "$trunk" >/dev/null
    git -C "$root" merge --ff-only "$branch" >/dev/null || git -C "$root" merge "$branch" >/dev/null
    git -C "$root" branch -d "$branch" >/dev/null || true
    printf 'ACS_MODE=merge\nACS_MERGED=true\nACS_TRUNK=%s\n' "$trunk"
    ;;
esac
