#!/usr/bin/env bash
set -euo pipefail

acs_repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || {
    echo "Agent Code Starter must run inside a git repository" >&2
    return 1
  }
}

acs_config_file() {
  printf '%s/.agent-code\n' "$(acs_repo_root)"
}

acs_config_first() {
  local key="$1" file
  file="$(acs_config_file)"
  [[ -f "$file" ]] || return 0
  sed -n "s/^${key}=//p" "$file" | head -n 1
}

acs_config_all() {
  local key="$1" file
  file="$(acs_config_file)"
  [[ -f "$file" ]] || return 0
  sed -n "s/^${key}=//p" "$file"
}

acs_trunk_branch() {
  local configured root detected
  configured="$(acs_config_first trunk_branch)"
  if [[ -n "$configured" ]]; then
    printf '%s\n' "$configured"
    return
  fi
  root="$(acs_repo_root)"
  detected="$(git -C "$root" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's#^refs/remotes/origin/##' || true)"
  if [[ -n "$detected" ]]; then
    printf '%s\n' "$detected"
  elif git -C "$root" show-ref --verify --quiet refs/heads/main; then
    printf 'main\n'
  else
    printf 'master\n'
  fi
}

acs_branch_prefix() {
  local configured
  configured="$(acs_config_first branch_prefix)"
  configured="${configured:-agent/}"
  [[ "$configured" == */ ]] || configured="${configured}/"
  printf '%s\n' "$configured"
}

acs_slug() {
  printf '%s' "$*" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-72
}

acs_require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "$1 is required" >&2
    return 1
  }
}

acs_current_branch() {
  git -C "$(acs_repo_root)" branch --show-current
}
