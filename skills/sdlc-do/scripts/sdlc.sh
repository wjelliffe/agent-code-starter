#!/usr/bin/env bash
set -euo pipefail

command_name="${1:-}"
run_id="${2:-}"
shift $(( $# >= 2 ? 2 : $# )) || true

[[ -n "$command_name" && -n "$run_id" ]] || {
  echo "usage: sdlc.sh <start|status|approve-plan|complete|block> <run-id> [args...]" >&2
  exit 2
}
[[ "$run_id" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "run-id may contain only letters, numbers, dot, underscore, and hyphen" >&2; exit 2; }

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "$repo_root" ]] || { echo "sdlc.sh must run inside a git repository" >&2; exit 1; }
common_dir="$(git -C "$repo_root" rev-parse --git-common-dir)"
if [[ "$common_dir" != /* ]]; then common_dir="${repo_root}/${common_dir}"; fi
run_dir="${common_dir}/agent-code-starter/runs/${run_id}"

read_field() { [[ -f "${run_dir}/$1" ]] && cat "${run_dir}/$1" || true; }
write_field() { mkdir -p "$run_dir"; printf '%s\n' "$2" > "${run_dir}/$1"; }
state() { read_field STATE; }
require_run() { [[ -d "$run_dir" ]] || { echo "unknown ACS SDLC run: ${run_id}" >&2; exit 1; }; }
require_state() {
  local expected="$1" actual
  actual="$(state)"
  [[ "$actual" == "$expected" ]] || { echo "illegal transition: expected ${expected}, current state is ${actual}" >&2; exit 1; }
}
set_blocked() {
  write_field STATE BLOCKED
  write_field BLOCK_REASON "$1"
}

next_for_state() {
  case "$1" in
    PLAN_REQUIRED) echo 'Produce and validate the technical plan; then ask for plan approval.' ;;
    IMPLEMENT_REQUIRED) echo 'Implement the approved plan in the prepared branch/worktree.' ;;
    VERIFY_REQUIRED) echo 'Run deterministic checks/tests and assess acceptance criteria.' ;;
    CREATE_PR_REQUIRED) echo 'Create the pull request and record its number.' ;;
    REVIEW_1_REQUIRED) echo 'Run one fresh adversarial review pass.' ;;
    REMEDIATE_REQUIRED) echo 'Address valid findings on the existing PR.' ;;
    REVERIFY_REQUIRED) echo 'Re-run deterministic verification once.' ;;
    REVIEW_2_REQUIRED) echo 'Run the final fresh review pass. This is the last review pass.' ;;
    MERGE_REQUIRED) echo 'Merge the reviewed PR.' ;;
    DONE) echo 'Feature complete.' ;;
    BLOCKED) echo "Stop and surface blocker: $(read_field BLOCK_REASON)" ;;
    *) echo 'Unknown state.' ;;
  esac
}

show_status() {
  require_run
  local current target reviews pr
  current="$(state)"
  target="$(read_field TARGET)"
  reviews="$(read_field REVIEW_PASS)"; reviews="${reviews:-0}"
  pr="$(read_field PR_NUMBER)"
  echo "ACS SDLC ${run_id}"
  echo "Target: ${target}"
  echo "State: ${current}"
  echo "Review passes: ${reviews}/2"
  [[ -z "$pr" ]] || echo "PR: #${pr}"
  echo "Next: $(next_for_state "$current")"
}

case "$command_name" in
  start)
    [[ ! -d "$run_dir" ]] || { echo "run already exists: ${run_id}" >&2; exit 1; }
    target="$*"
    [[ -n "$target" ]] || target="$run_id"
    mkdir -p "$run_dir"
    write_field TARGET "$target"
    write_field STATE PLAN_REQUIRED
    write_field REVIEW_PASS 0
    show_status
    ;;
  status)
    show_status
    ;;
  approve-plan)
    require_run
    require_state PLAN_REQUIRED
    write_field STATE IMPLEMENT_REQUIRED
    show_status
    ;;
  complete)
    require_run
    phase="${1:-}"; result="${2:-}"
    case "$phase" in
      implement)
        require_state IMPLEMENT_REQUIRED
        write_field STATE VERIFY_REQUIRED
        ;;
      verify)
        require_state VERIFY_REQUIRED
        if [[ "$result" == "pass" ]]; then write_field STATE CREATE_PR_REQUIRED
        elif [[ "$result" == "fail" ]]; then set_blocked 'initial verification failed'
        else echo "verify result must be pass or fail" >&2; exit 2; fi
        ;;
      create-pr)
        require_state CREATE_PR_REQUIRED
        [[ "$result" =~ ^[0-9]+$ ]] || { echo "create-pr requires a numeric PR number" >&2; exit 2; }
        write_field PR_NUMBER "$result"
        write_field STATE REVIEW_1_REQUIRED
        ;;
      review)
        current="$(state)"
        [[ "$result" == "approve" || "$result" == "blockers" ]] || { echo "review result must be approve or blockers" >&2; exit 2; }
        if [[ "$current" == "REVIEW_1_REQUIRED" ]]; then
          write_field REVIEW_PASS 1
          if [[ "$result" == "approve" ]]; then write_field STATE MERGE_REQUIRED; else write_field STATE REMEDIATE_REQUIRED; fi
        elif [[ "$current" == "REVIEW_2_REQUIRED" ]]; then
          write_field REVIEW_PASS 2
          if [[ "$result" == "approve" ]]; then write_field STATE MERGE_REQUIRED; else set_blocked 'final review still has substantive blockers'; fi
        else
          echo "illegal transition: review cannot complete from ${current}" >&2; exit 1
        fi
        ;;
      remediate)
        require_state REMEDIATE_REQUIRED
        write_field STATE REVERIFY_REQUIRED
        ;;
      reverify)
        require_state REVERIFY_REQUIRED
        if [[ "$result" == "pass" ]]; then write_field STATE REVIEW_2_REQUIRED
        elif [[ "$result" == "fail" ]]; then set_blocked 'verification after remediation failed'
        else echo "reverify result must be pass or fail" >&2; exit 2; fi
        ;;
      merge)
        require_state MERGE_REQUIRED
        write_field STATE DONE
        ;;
      *) echo "unknown completion phase: ${phase}" >&2; exit 2 ;;
    esac
    show_status
    ;;
  block)
    require_run
    current="$(state)"
    [[ "$current" != "DONE" ]] || { echo 'cannot block a completed run' >&2; exit 1; }
    reason="$*"; [[ -n "$reason" ]] || reason='blocked by operator'
    set_blocked "$reason"
    show_status
    ;;
  *) echo "unknown command: ${command_name}" >&2; exit 2 ;;
esac
