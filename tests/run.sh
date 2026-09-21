#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
passes=0

pass() { echo "ok - $1"; passes=$((passes+1)); }
fail() { echo "not ok - $1" >&2; exit 1; }
assert_contains() { grep -Fq "$2" <<<"$1" || fail "$3"; }
assert_file() { [[ -f "$1" ]] || fail "missing $1"; }

# Packaging and architecture
[[ "$(grep -c '"version": "3.0.0"' "$ROOT/.codex-plugin/plugin.json")" -eq 1 ]] || fail 'Codex version'
[[ "$(grep -c '"version": "3.0.0"' "$ROOT/.claude-plugin/plugin.json")" -eq 1 ]] || fail 'Claude version'
pass 'plugin versions are synchronized'

for skill in issues plan implement code-review sdlc-do; do assert_file "$ROOT/skills/$skill/SKILL.md"; done
[[ "$(find "$ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')" == "5" ]] || fail 'expected five invocable skill entries'
pass 'four skills plus workflow facade are present'

[[ ! -d "$ROOT/runtime" ]] || fail 'legacy root runtime directory still exists'
[[ ! -d "$ROOT/agentic-scripts" ]] || fail 'legacy agentic-scripts directory still exists'
[[ -z "$(find "$ROOT" -type f -name '*.py' -print)" ]] || fail 'Python files remain in repository'
pass 'runtime is bundled with skills and has no Python dependency'

assert_contains "$(cat "$ROOT/README.md")" 'Execution is cheap. Judgment is scarce.' 'README missing key saying'
assert_contains "$(cat "$ROOT/README.md")" 'The orchestrator belongs in deterministic code. The model is a bounded worker.' 'README missing orchestration principle'
pass 'README preserves product language'

# Script parity and syntax
for sh in $(find "$ROOT/skills" -type f -path '*/scripts/*.sh' | sort); do
  bash -n "$sh" || fail "invalid Bash syntax: $sh"
  ps1="${sh%.sh}.ps1"
  [[ -f "$ps1" ]] || fail "missing PowerShell pair for $sh"
done
pass 'Bash scripts parse and every helper has a PowerShell pair'

# Contract validators
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cat > "$work/plan.md" <<'PLAN'
## Approach
Do it.
## Touch points
- src
## Invariants
- preserve behavior
## Sequence
- edit
## Tests
- run tests
## Risks
- none
PLAN_STATUS: READY
PLAN
"$ROOT/skills/plan/scripts/validate-plan.sh" "$work/plan.md" | grep -Fq 'PLAN_STATUS=READY' || fail 'plan validator'
pass 'plan contract validator accepts a complete plan'

cat > "$work/review.md" <<'REVIEW'
## Findings
No blockers found.
VERDICT: APPROVE
REVIEW
"$ROOT/skills/code-review/scripts/validate-review.sh" "$work/review.md" | grep -Fq 'VERDICT: APPROVE' || fail 'review validator'
pass 'review contract validator accepts a valid verdict'

cat > "$work/issue.md" <<'ISSUE'
## Problem
Something is wrong.
## Acceptance Criteria
- It is fixed.
ISSUE
"$ROOT/skills/issues/scripts/validate-dor.sh" "$work/issue.md" | grep -Fq 'DOR_STATUS=READY' || fail 'DOR validator'
pass 'issue readiness validator accepts actionable issue'

# Fixture repository
repo="$work/repo"
mkdir -p "$repo"
git -C "$repo" init -b main >/dev/null 2>&1 || { git -C "$repo" init >/dev/null; git -C "$repo" checkout -b main >/dev/null; }
git -C "$repo" config user.email test@example.com
git -C "$repo" config user.name 'ACS Tests'
echo fixture > "$repo/README.md"
git -C "$repo" add README.md
git -C "$repo" commit -m initial >/dev/null

# Verification none-found and config failure
out="$(cd "$repo" && "$ROOT/skills/implement/scripts/verify.sh" tests)"
assert_contains "$out" 'ACS_STATUS=NONE_FOUND' 'none-found verification'
pass 'verification reports NONE_FOUND instead of fake pass'

echo 'test=exit 7' > "$repo/.agent-code"
set +e
out="$(cd "$repo" && "$ROOT/skills/implement/scripts/verify.sh" tests 2>&1)"
code=$?
set -e
[[ $code -ne 0 ]] || fail 'configured failure returned zero'
assert_contains "$out" 'ACS_STATUS=FAIL' 'configured failure evidence'
rm "$repo/.agent-code"
pass 'configured verification failure is propagated'

# Dirty branch setup refusal
printf dirty > "$repo/dirty.txt"
set +e
out="$(cd "$repo" && "$ROOT/skills/implement/scripts/start-work.sh" story-1 inplace 2>&1)"
code=$?
set -e
[[ $code -ne 0 ]] || fail 'dirty branch setup was allowed'
assert_contains "$out" 'dirty working tree' 'dirty branch message'
rm "$repo/dirty.txt"
pass 'branch setup refuses dirty tree'

# Diff summary includes untracked files
printf untracked > "$repo/untracked.txt"
out="$(cd "$repo" && "$ROOT/skills/implement/scripts/summarize-diff.sh")"
assert_contains "$out" 'untracked.txt' 'untracked file missing from summary'
rm "$repo/untracked.txt"
pass 'diff summary includes untracked files'

# Finalization cannot commit directly to trunk
printf change > "$repo/change.txt"
set +e
out="$(cd "$repo" && "$ROOT/skills/implement/scripts/finalize.sh" merge 'test change' 2>&1)"
code=$?
set -e
[[ $code -ne 0 ]] || fail 'trunk finalization was allowed'
assert_contains "$out" 'directly on trunk' 'trunk finalization message'
rm "$repo/change.txt"
pass 'finalization refuses trunk'

# SDLC happy path
cd "$repo"
ctl="$ROOT/skills/sdlc-do/scripts/sdlc.sh"
out="$($ctl start happy issue-107)"
assert_contains "$out" 'State: PLAN_REQUIRED' 'sdlc start'
out="$($ctl approve-plan happy)"; assert_contains "$out" 'State: IMPLEMENT_REQUIRED' 'approve plan'
out="$($ctl complete happy implement)"; assert_contains "$out" 'State: VERIFY_REQUIRED' 'implement transition'
out="$($ctl complete happy verify pass)"; assert_contains "$out" 'State: CREATE_PR_REQUIRED' 'verify transition'
out="$($ctl complete happy create-pr 123)"; assert_contains "$out" 'State: REVIEW_1_REQUIRED' 'pr transition'
out="$($ctl complete happy review approve)"; assert_contains "$out" 'State: MERGE_REQUIRED' 'review approve transition'
out="$($ctl complete happy merge)"; assert_contains "$out" 'State: DONE' 'merge transition'
pass 'SDLC happy path reaches DONE'

# SDLC bounded remediation path
out="$($ctl start bounded issue-108)"
$ctl approve-plan bounded >/dev/null
$ctl complete bounded implement >/dev/null
$ctl complete bounded verify pass >/dev/null
$ctl complete bounded create-pr 124 >/dev/null
out="$($ctl complete bounded review blockers)"; assert_contains "$out" 'State: REMEDIATE_REQUIRED' 'review1 blockers'
$ctl complete bounded remediate >/dev/null
$ctl complete bounded reverify pass >/dev/null
out="$($ctl complete bounded review blockers)"
assert_contains "$out" 'State: BLOCKED' 'review2 must block'
assert_contains "$out" 'Review passes: 2/2' 'review pass cap'
set +e
out="$($ctl complete bounded remediate 2>&1)"
code=$?
set -e
[[ $code -ne 0 ]] || fail 'blocked workflow permitted third remediation'
pass 'second blocking review terminates with no remediation loop'

echo "1..$passes"
