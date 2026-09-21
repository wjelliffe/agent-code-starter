---
name: code-review
description: Use when performing one skeptical review of the current diff or pull request against its requirements; review only, no edits or delegation.
metadata:
  short-description: One-shot skeptical review
---

# Code Review

Perform exactly one skeptical review pass. Do not modify files. Do not spawn sub-agents or other reviewers. Do not invoke other skills.

Read only the evidence needed to judge the change:
- issue/request and acceptance criteria
- complete diff
- relevant surrounding code and invariants
- relevant tests and available CI evidence

Check for:
- missed acceptance criteria
- correctness and regressions
- invalid/error paths
- security or data-integrity issues when relevant
- missing targeted tests
- scope creep

Return concise findings with concrete file/behavior evidence, then exactly one verdict:

`VERDICT: APPROVE`

or

`VERDICT: BLOCKERS`

Any substantive correctness, security, data-loss, invariant, or requirement failure is a blocker.

This skill is one-shot. It must not edit, remediate, re-run itself, or launch another review.
