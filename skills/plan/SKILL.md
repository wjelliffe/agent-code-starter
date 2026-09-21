---
name: plan
description: Use when producing a read-only technical implementation plan for one bounded issue or request before code is changed.
metadata:
  short-description: Design the change before touching code
---

# Plan

Produce a technical implementation plan for one bounded unit of work. Do not modify repository files.

For issue input, load it with `../issues/scripts/get-issue.*`. Inspect only the repository context needed to make the plan executable.

## Required plan

Write a concise plan with these headings:

- `## Approach`
- `## Touch points`
- `## Invariants`
- `## Sequence`
- `## Tests`
- `## Risks`
- `## Open questions` when needed

End with exactly one status line:

- `PLAN_STATUS: READY`
- `PLAN_STATUS: BLOCKED`

Validate the artifact with `scripts/validate-plan.*`.

## Contract

- Read-only. Never implement.
- Name concrete files/components when evidence supports it; do not invent paths.
- Preserve existing architecture unless the requirement demands a change.
- Call out decisions that genuinely block implementation instead of burying them in prose.
- A `READY` plan should be specific enough that implementation does not need to redesign the feature.
