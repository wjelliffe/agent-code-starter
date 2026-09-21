---
name: sdlc-do
description: Use when explicitly executing one bounded implementation unit with a stricter plan, isolation, testing, and verification flow.
metadata:
  short-description: Bounded strict SDLC execution
---

# SDLC Do

Execute exactly one bounded implementation unit with higher ceremony. This is an explicit workflow, not an automatic escalation target.

Bundled deterministic helpers live at `../../runtime/` relative to this skill. Run them with the target repository as the working directory.

## Scope

Supports one GitHub issue, one tightly coupled issue set intended to land together, or one direct request.

Does not support epics, parent-issue orchestration, unrelated batching, delegation, agent teams, or sub-agents. Do not spawn another agent for implementation, testing, debugging, or review.

## Gates

- Gate 1: plan approval.
- Gate 2: finalization choice.

## Flow

1. **Load context once**
   - Use `get_issue.sh` for issue input.
   - Use `prepare_sdlc_context.sh` once to normalize execution context.
   - If either fails, stop. Do not retry automatically.

2. **Plan — Gate 1**
   Produce a concise execution plan covering files/components, invariants, implementation sequence, tests, verification, and material risks. Wait for approval.

3. **Execution setup**
   Use `start_worktree.sh` in the selected mode. If setup fails, stop.

4. **Implement**
   - Keep work within the approved plan.
   - Prefer tests first where they materially reduce risk.
   - Investigate unclear failures in this same agent. Do not delegate.

5. **Validate once**
   - Run `run_checks.sh` once.
   - Run `run_tests.sh` once.
   - If either fails, stop and report the evidence. Do not enter an autonomous repair/retry loop.

6. **Diff + DoD**
   - Run `summarize_diff.sh`.
   - Run `validate_dod.sh` once.
   - If validation fails, stop.

7. **Gate 2**
   Present exactly:
   - `Commit and merge.`
   - `Commit and push up as Pull Request.`

   Wait for the user. Do not run code review inside `sdlc-do`.

8. **Finalize**
   Use `finalize_work.sh` for the selected finalization action. If it fails, stop. Do not retry automatically.

If a pull request is created, stop. Independent review is a separate `code-review` invocation, ideally performed by another AI/session. Any resulting review comments can later be addressed with a new bounded `implement` pass.

## Hard limits

- One primary agent.
- Zero sub-agents.
- Zero orchestration.
- Zero automatic review invocations.
- Zero autonomous review/fix/re-review loops.
- Zero automatic retries after command failure.
- Deterministic work belongs in runtime helpers.
- Do not broaden scope beyond the approved bounded unit.
- Do not modify unrelated files.
