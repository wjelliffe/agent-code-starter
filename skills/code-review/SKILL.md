---
name: code-review
description: Use when reviewing a current branch or pull request before merge, especially when correctness requires checking the issue, current trunk, architecture, tests, security, data integrity, and CI rather than only the diff description.
---

# Code Review

Perform a skeptical senior/staff-level review. Do not edit files.

## Establish the review base

1. Read the linked issue/request, acceptance criteria, comments, dependencies, and relevant parent/related issues.
2. Read project instructions and the surrounding architecture that owns the changed behavior.
3. Fetch current `origin` when available and compare against the actual current trunk merge-base, not the author's summary.
4. Inspect the complete diff plus relevant unchanged code needed to validate invariants.
5. If a PR exists, inspect its CI/check results and failure logs yourself when available.

## Review dimensions

Always check:

- acceptance criteria and intended behavior
- regressions and broken existing behavior
- invalid inputs and error paths
- duplicated business logic or divergence across surfaces
- state/invariant enforcement at the correct layer
- meaningful tests for changed behavior
- scope creep and accidental unrelated changes

When relevant, explicitly inspect:

- authentication and authorization gaps
- unsafe input handling
- SQL/query parameterization
- secret/token/cookie/credential leakage
- unsafe logging
- path/file traversal risks
- invalid state transitions
- transactions, races, retries, and idempotency
- migration/backfill/rollback safety
- cross-surface consistency
- backwards compatibility

Do not invent findings to justify a review. Do not waive a real issue because tests happen to pass.

## Output

Return findings first, highest severity first:

- **BLOCKER** — security/data-loss/major correctness issue or requirement failure that must be fixed.
- **IMPORTANT** — substantive correctness, invariant, regression, or coverage gap that should block merge.
- **MINOR** — non-blocking improvement.

Every blocking finding needs concrete evidence: file/line or specific behavior, why it matters, and the smallest reasonable correction.

Then include a concise verification summary and exactly one verdict:

`VERDICT: APPROVE`

or

`VERDICT: BLOCKERS`

Any BLOCKER or IMPORTANT finding means BLOCKERS.
