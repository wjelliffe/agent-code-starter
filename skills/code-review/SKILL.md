---
name: code-review
description: Use when performing one skeptical, read-only review of a pull request or current diff against its requirements and posting PR findings when GitHub write access is available.
metadata:
  short-description: One-shot adversarial review
---

# Code Review

Perform exactly one skeptical review pass. Do not modify files. Do not spawn sub-agents or other reviewers. Do not invoke implementation skills.

## Pull request review

When a PR is provided:

1. Read the linked issue/request and acceptance criteria.
2. Read the complete PR diff against current trunk.
3. Inspect only the relevant surrounding code needed to validate architecture and invariants.
4. Inspect relevant tests and available CI evidence.
5. Check for:
   - missed acceptance criteria
   - correctness and regressions
   - invalid/error paths
   - security or data-integrity issues when relevant
   - missing targeted tests
   - scope creep

Produce concrete findings with file/behavior evidence.

Then submit exactly one GitHub PR review when write access is available:

- use a COMMENT review so the workflow also works when the connected GitHub user owns the PR
- place actionable findings inline on changed lines when an exact diff location is available
- put findings that cannot be anchored safely in the review body
- end the review body with exactly one verdict:
  - `VERDICT: APPROVE`
  - `VERDICT: BLOCKERS`

Any substantive correctness, security, data-loss, invariant, regression, or requirement failure means `VERDICT: BLOCKERS`.

If GitHub review writes are unavailable, return the same findings and verdict in chat and state that they were not posted.

## Local diff review

If no PR exists and the user explicitly requests review of a local/current diff, return findings and the verdict in chat only.

## Hard limits

- One review pass.
- Zero edits.
- Zero remediation.
- Zero sub-agents.
- Zero follow-up review unless the user explicitly invokes `code-review` again later.
- Never start a review/fix/re-review loop.
