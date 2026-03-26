---
name: sdlc-do
description: Use when a GitHub issue should go through the full Definition of Done flow with shared issue JSON, approval gates, and deterministic runtime scripts.
metadata:
  short-description: Definition of Done engine
---

# SDLC Do

Use this skill for issue-driven delivery that needs structured planning, controlled execution, and a Definition of Done check.

## Usage

- `/sdlc-do #62`
- `/sdlc-do 62`
- `/sdlc-do #62 mode=worktree`
- `/sdlc-do #62 mode=inplace`

## Inputs

- Issue number is required. If missing, ask once and stop.
- Execution mode is optional. Default to `inplace`. Use `worktree` only when the user explicitly wants isolation.

## Core Rules

- Exactly two approvals:
  - Gate 1: plan approval
  - Gate 2: final review approval
- Resolve `<workspace-root>` from the active repository, typically with `git rev-parse --show-toplevel`.
- All agents use the same `<workspace-root>/.tmp/issue-<num>.json` input.
- Deterministic actions must go through `<workspace-root>/agentic-scripts`.
- Do not create transient issue docs in `docs/`.
- Commit only if the user explicitly asks for it.

## Workflow Sequence

1. Run `<workspace-root>/agentic-scripts/get_issue.sh <num>`.
2. Read `<workspace-root>/.tmp/issue-<num>.json`.
3. Build an execution plan that covers code, docs, risks, and verification.
4. Stop for Gate 1 approval.
5. Choose execution context:
   - `inplace` default: stay in the current repo and working copy
   - `worktree`: run `<workspace-root>/agentic-scripts/start_worktree.sh <num> worktree`
6. Implement the issue.
7. Run `<workspace-root>/agentic-scripts/run_checks.sh`.
8. Run `<workspace-root>/agentic-scripts/summarize_diff.sh`.
9. Run `<workspace-root>/agentic-scripts/validate_dod.sh <num>`.
10. Present the final package:
   - plan coverage
   - checks output
   - diff summary
   - DOD validation
   - remaining risks
11. Stop for Gate 2 approval.
12. Commit only if explicitly requested.

## Revision Loops

- Gate 1 feedback: revise plan and return to Gate 1.
- Gate 2 feedback: revise implementation and return to Gate 2.

## DOD Checklist

- acceptance criteria satisfied
- code implemented
- checks/tests executed
- no obvious regressions
- docs updated if needed
- diff summarized
- risks noted
- ready for review
- worktree clean
- DOD validator passes

## Rules

- Respect repo approval and safety rules.
- Do not duplicate logic that belongs in `<workspace-root>/agentic-scripts`.
- In multi-agent runs, all agents read the same issue JSON and should own disjoint file slices.
- Keep the narration concise; the scripts provide the deterministic evidence.
