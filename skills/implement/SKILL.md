---
name: implement
description: Use when executing one clear GitHub issue or direct request, or when addressing review feedback on one existing pull request.
metadata:
  short-description: One bounded coding pass
---

# Implement

Implement one bounded unit of work. This is the fast path: understand the task, make the change, verify it, then either merge or open/update a PR.

Deterministic mechanics live in `scripts/`. Use `.sh` on Bash-compatible hosts and `.ps1` on PowerShell hosts. The scripts run against the target repository and ship with the plugin; do not copy ACS framework scripts into application repositories.

## New work

1. Load the issue with `../issues/scripts/get-issue.*` when applicable.
2. State a short execution preview: intended change, likely touch points, and verification.
3. Prepare a safe branch with `scripts/start-work.* <work-key> inplace` unless the environment already provides isolated work.
4. Implement the smallest correct change.
5. Run `scripts/verify.* checks` and relevant `scripts/verify.* tests` once.
6. Run `scripts/summarize-diff.*` and assess the acceptance criteria/invariants against the actual diff.
7. Present exactly two finalization choices:
   - `Commit and merge.`
   - `Commit and push up as Pull Request.`
8. Use `scripts/finalize.* merge|pr` for the selected action.

Do not add a planning approval gate here. Use `plan` first when the user wants design before implementation, or use `sdlc-do` for the full lifecycle.

## Existing PR remediation

Use this mode only when explicitly asked to address review feedback on an existing PR.

1. Load the PR, requirements, review comments, current diff, and CI evidence. `../code-review/scripts/get-review-context.*` can gather the review packet.
2. Work on the existing PR head branch. Never create a second PR.
3. Evaluate findings; fix valid actionable findings only.
4. Run relevant checks/tests once.
5. Summarize the diff.
6. Use `scripts/finalize.* update-pr <title> <pr-number>` to commit and push the same PR branch.
7. Stop. A later review is a separate bounded review pass unless `sdlc-do` is controlling the lifecycle.

## Contract

- One bounded coding owner.
- No silent escalation into a larger workflow.
- No recursive retry loop after command failure.
- No self-directed review/fix/re-review cycle.
- Do not broaden scope or modify unrelated files.
- Failures return evidence instead of triggering more work automatically.
