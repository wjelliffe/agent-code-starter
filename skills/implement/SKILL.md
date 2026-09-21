---
name: implement
description: Use when executing one clear GitHub issue or direct request, or when addressing review feedback on one existing pull request, with a minimal bounded flow.
metadata:
  short-description: Cheap single-task implementation
---

# Implement

Execute exactly one bounded implementation unit with minimal overhead.

Bundled deterministic helpers live at `../../runtime/` relative to this skill. Run them with the target repository as the working directory.

## Scope

Supports exactly one of:

- one GitHub issue
- one direct request
- one existing pull request whose review feedback must be addressed

Does not support epics, unrelated issue batching, orchestration, delegation, agent teams, or sub-agents. Do not spawn another agent for implementation, testing, debugging, or review.

## New work flow

1. **Load**
   - For an issue, run `get_issue.sh`, then `prepare_sdlc_context.sh issue <issue-json-path>`.
   - For a direct request, run `prepare_sdlc_context.sh minimal` with the request on stdin.
   - Keep the returned context path for finalization.
   - If loading fails, stop. Do not retry automatically.

2. **Execution preview**
   - State likely files, intended change, and minimal verification.
   - Do not add a plan approval gate.

3. **Implement**
   - Make the smallest correct change.
   - Do not expand scope.
   - If the cause of a bug is unclear, investigate it in this same agent before editing.

4. **Validate once**
   - Run `run_checks.sh` once.
   - Run `run_tests.sh` only when relevant tests exist, behavior changed, or the issue requires tests.
   - If either fails, stop and report the failure. Do not enter an autonomous repair/retry loop.

5. **Summarize**
   - Run `summarize_diff.sh`.
   - Present files changed, what changed, verification results, and known risks.

6. **Final gate**
   Present exactly:
   - `Commit and merge.`
   - `Commit and push up as Pull Request.`

   Wait for the user. Code review is not part of this execution flow.

7. **Finalize**
   - Run `finalize_work.sh merge <context-json-path>` or `finalize_work.sh pr <context-json-path>` according to the user's selection.
   - If finalization fails, stop and report it. Do not retry automatically.

If a pull request is created, stop. Independent review is a separate `code-review` invocation, ideally in another AI/session.

## Existing PR review-remediation flow

Use this mode only when the user explicitly asks to address review feedback on an existing PR.

1. Load the PR, linked issue/requirements, unresolved review threads/comments, current diff, and CI status.
2. Check out the existing PR head branch. Do not create a new branch or new PR.
3. Evaluate each unresolved finding rather than blindly accepting it:
   - valid and actionable
   - already addressed
   - incorrect / based on a false assumption
   - requires product or architecture clarification
4. Fix valid actionable findings only. Keep changes scoped to the review.
5. Run `run_checks.sh` once and only the affected/relevant tests once.
6. If validation fails, stop and report it. Do not auto-retry.
7. Run `prepare_sdlc_context.sh minimal` with `Address review feedback on PR #<number>` on stdin.
8. Run `finalize_work.sh update-pr <context-json-path> <pr-number>`. The runtime must verify that the current branch is the open PR's head branch, commit once, and push to that existing PR without creating another PR.
9. Reply concisely to review threads when GitHub tooling is available:
   - say what changed for fixed findings
   - give evidence when a finding is incorrect
   - do not resolve threads automatically
10. Stop. Do not invoke `code-review` or re-review the PR.

## Hard limits

- One primary agent.
- Zero sub-agents.
- Zero automatic escalation to `sdlc-do`.
- Zero automatic review invocations.
- Zero autonomous review/fix/re-review loops.
- Zero automatic retries after command failure.
- Targeted verification only.
- Deterministic work belongs in runtime helpers.
- Do not modify unrelated files.
