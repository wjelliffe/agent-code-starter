---
name: sdlc-do
description: Use when taking one bounded feature through plan, implementation, verification, adversarial review, remediation when needed, and merge.
metadata:
  short-description: Finish one feature end to end
---

# SDLC Do

Take one bounded feature all the way to completion.

This skill is a thin workflow facade. The deterministic controller in `scripts/sdlc.*` owns lifecycle state and legal transitions. Do not invent phases, retries, or extra review passes.

Use `.sh` on Bash-compatible hosts and `.ps1` on PowerShell hosts. Run the controller from the target repository.

## Lifecycle

```text
PLAN_REQUIRED
  ↓ user approves plan
IMPLEMENT_REQUIRED
  ↓
VERIFY_REQUIRED
  ↓ pass
CREATE_PR_REQUIRED
  ↓
REVIEW_1_REQUIRED
  ├─ approve ─────────────→ MERGE_REQUIRED → DONE
  └─ blockers
       ↓
  REMEDIATE_REQUIRED
       ↓
  REVERIFY_REQUIRED
       ↓ pass
  REVIEW_2_REQUIRED
       ├─ approve ────────→ MERGE_REQUIRED → DONE
       └─ blockers ───────→ BLOCKED
```

There is no transition from the second review back to remediation.

## Run protocol

1. Start once with `scripts/sdlc.* start <run-id> <target>` or resume with `status`.
2. Obey the state printed by the controller:
   - `PLAN_REQUIRED`: apply the `plan` skill contract, validate the plan, present it, and wait for the single human gate. After approval run `approve-plan`.
   - `IMPLEMENT_REQUIRED`: prepare isolated work with `../implement/scripts/start-work.* <work-key> worktree`, then implement the approved plan. Complete `implement` only when the code change is ready for verification.
   - `VERIFY_REQUIRED`: run deterministic checks/tests once plus diff/acceptance-criteria assessment. Complete `verify pass|fail`.
   - `CREATE_PR_REQUIRED`: create the PR with `../implement/scripts/finalize.* pr`, then complete `create-pr <number>`.
   - `REVIEW_1_REQUIRED`: use a fresh isolated reviewer when the host supports it, applying the `code-review` contract. Validate/post one review. Complete `review approve|blockers`.
   - `REMEDIATE_REQUIRED`: the implementation owner fixes valid findings on the same PR and uses `finalize.* update-pr`. Complete `remediate`.
   - `REVERIFY_REQUIRED`: run verification once. Complete `reverify pass|fail`.
   - `REVIEW_2_REQUIRED`: run one final fresh review. Complete `review approve|blockers`. This is the final review pass.
   - `MERGE_REQUIRED`: merge the PR with `../implement/scripts/finalize.* merge-pr`, then complete `merge`.
   - `DONE`: report the completed feature and evidence.
   - `BLOCKED`: stop and surface the blocker.
3. After every transition, show the controller's progress output.

## Contract

- One bounded feature or tightly coupled unit of work.
- One plan approval gate; after approval, drive the finite lifecycle to `DONE` or `BLOCKED`.
- At most two adversarial review passes.
- Remediation occurs at most once.
- Deterministic scripts own Git, GitHub, verification commands, state, and transitions.
- Model judgment is reserved for planning, coding, acceptance-criteria assessment, and review.
- Never turn `BLOCKED` into an autonomous retry loop.
