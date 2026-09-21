---
name: implement
description: Use when executing one clear GitHub issue or direct request with a minimal, low-token flow using deterministic runtime helpers and one final approval gate.
metadata:
  short-description: Cheap single-task implementation
---

# Implement

Execute exactly one bounded implementation unit with minimal overhead.

Bundled deterministic helpers live at `../../runtime/` relative to this skill. Run them with the target repository as the working directory.

## Scope

Supports one GitHub issue or one direct request.

Does not support epics, multiple unrelated issues, orchestration, delegation, agent teams, or sub-agents. Do not spawn another agent for implementation, testing, debugging, or review.

If the request is not one bounded unit, stop and ask the user to split it or explicitly choose `sdlc-do`.

## Flow

1. **Load**
   - For an issue, run `get_issue.sh`.
   - If loading fails, stop. Do not retry automatically.

2. **Execution preview**
   - State likely files, intended change, and minimal verification.
   - Do not add a plan approval gate.

3. **Implement**
   - Make the smallest correct change.
   - Do not expand scope.
   - If the cause of a bug is unclear, investigate it in this same agent before editing. Do not invoke another skill or agent.

4. **Validate once**
   - Run `run_checks.sh` once.
   - Run `run_tests.sh` only when relevant tests exist, behavior changed, or the issue requires tests.
   - If either fails, stop and report the failure. Do not enter an autonomous repair/retry loop.

5. **Summarize**
   - Run `summarize_diff.sh`.
   - Present files changed, what changed, verification results, and known risks.

6. **Final gate**
   Present exactly:
   - `Execute code review.`
   - `Commit and merge.`
   - `Commit and push up as Pull Request.`

   Wait for the user.

   If the user selects review, invoke `code-review` exactly once. If it returns blockers, stop and return the findings to the user. Do not fix and re-review autonomously. A later explicit user request may address those findings as a new bounded pass.

7. **Finalize**
   - Finalize only through `finalize_work.sh`.
   - If finalization fails, stop and report it. Do not retry automatically.

## Hard limits

- One primary agent.
- Zero sub-agents.
- Zero automatic escalation to `sdlc-do`.
- At most one review invocation per execution.
- Zero autonomous review/fix/re-review loops.
- Zero automatic retries after command failure.
- Targeted verification only.
- Deterministic work belongs in runtime helpers.
- Do not modify unrelated files.
