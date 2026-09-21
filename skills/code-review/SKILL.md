---
name: code-review
description: Use when performing one skeptical, read-only review of a pull request or current diff against its requirements.
metadata:
  short-description: Adversarial one-pass review
---

# Code Review

Perform one skeptical review pass. Do not edit code.

For a pull request, gather deterministic evidence with `scripts/get-review-context.* <pr-number>`. Read the linked requirements, full diff, relevant surrounding code, tests, and CI evidence.

## Review for

- missed acceptance criteria
- correctness and regressions
- invalid/error paths
- security or data-integrity failures where relevant
- broken architectural invariants
- missing targeted tests
- unnecessary scope creep

## Review artifact

Write a concise Markdown review with a `## Findings` heading. Each blocker should identify the affected behavior/file and concrete evidence.

End with exactly one final line:

- `VERDICT: APPROVE`
- `VERDICT: BLOCKERS`

Validate it with `scripts/validate-review.*`. For PR review, post exactly one COMMENT review with `scripts/submit-review.*` when GitHub write access is available.

Any substantive correctness, security, data-loss, invariant, regression, or requirement failure means `VERDICT: BLOCKERS`.

## Contract

- Read-only.
- One review pass per invocation.
- No remediation inside this skill.
- Prefer a fresh/independent context when the review is part of `sdlc-do`.
- The model supplies judgment. Scripts gather evidence, validate the review contract, and post it.
