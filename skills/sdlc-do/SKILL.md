---
name: sdlc-do
description: Use when implementing high-risk, cross-cutting, security-sensitive, data-sensitive, infrastructure, migration, or ambiguous work that benefits from explicit planning and rigorous verification.
---

# SDLC Do

Execute one bounded delivery unit with higher ceremony because failure is expensive or the implementation is genuinely unclear.

Bundled runtime lives at `../../runtime/` relative to this `SKILL.md`. Resolve that path from the installed skill file; run runtime commands with the target repository as the working directory. Invoke bundled shell helpers through `bash` (for example, `bash <plugin-root>/runtime/start_worktree.sh ...`) because plugin packaging may not preserve executable bits.

## Gate 1: plan

Load the issue/request plus project architecture before proposing a plan.

The plan must identify:

- files/components involved
- invariants and security/data constraints
- implementation sequence
- test strategy and TDD stance
- migration/backfill/rollback implications when relevant
- verification and review strategy
- assumptions that could invalidate the approach

Require approval of this plan before edits.

## Isolated execution

Create a worktree by default with `start_worktree.sh <work-key> worktree <context-path>`.

For behavior changes, prefer a real red-green cycle when practical. For migrations, authorization, concurrency, state machines, and data integrity, tests must cover failure and invalid-state paths, not only happy paths.

Keep the implementation bounded to the approved plan. If the architecture must change materially, surface the change rather than silently expanding scope.

## Verification

Run all configured/detected checks and tests. A missing test command is `none-found`, not success; on the strict path, explicitly justify proceeding without executable tests.

Run `validate_dod.sh`, inspect the full diff, and invoke `verify`.

## Mandatory review

Invoke `code-review` before final approval. Review must use current trunk, issue context/comments, surrounding architecture, tests, and available CI evidence.

Fix blocking findings, re-run the covering checks/tests, and re-review. If repeated fixes do not converge, reassess the plan/root cause instead of churning.

## Gate 2: finalization

After verification and clean review, present:

- `Commit and merge.`
- `Commit and push up as Pull Request.`

Finalize only through `finalize_work.sh`.

## Rules

- High rigor does not mean unrelated cleanup.
- Important invariants belong at the service/data boundary where feasible.
- Treat all external input as untrusted.
- Parameterize data access and avoid secret/token leakage.
- Preserve backward compatibility unless the approved plan says otherwise.
- No mandatory per-task subagent/reviewer choreography; use additional agents only when they materially improve the work.
