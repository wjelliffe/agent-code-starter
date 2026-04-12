---
name: issues
description: Transform product or engineering input into clear, actionable GitHub issues using adaptive depth, conditional discovery, and a single approval gate.
metadata:
  short-description: PDLC to issue-definition engine
---

# Issues

Turn rough product or engineering input into development-ready GitHub issue drafts.

## Use It When

- turning an epic, user story, task, or bug into clear issue draft(s)
- discovering missing requirements only when they matter
- preparing work so development can take the issue without more planning

## Inputs

Resolve `<workspace-root>` from the active repository, typically with `git rev-parse --show-toplevel`.

- current conversation context
- referenced local plan/spec files
- shared `.tmp` planning artifacts in the workspace
- issue JSON from `<workspace-root>/agentic-scripts/get_issue.sh`

## Runtime References

- `classify_issue_input.sh`
- `draft_issue_bundle.sh`
- `validate_dor.sh`
- `write_issues.sh`

## Flow

Apply only the depth required to make the work immediately actionable.

1. Inspect the input.
2. Classify as `epic`, `user_story`, `task`, or `bug` with default `user_story`.

3. Determine required depth.

Apply the minimum structure necessary to make the issue actionable:

- If the input is already clear:
  - draft a single issue directly
  - include title, description, and concise acceptance criteria

- If the input is ambiguous:
  - ask only the most critical discovery questions
  - do not over-interrogate

- If the input represents multiple pieces of work:
  - break into multiple issues

- If the input is an epic:
  - create a parent epic issue
  - create child story issues
  - attach them as GitHub sub-issues

4. Normalize into `.tmp` only if:
   - multiple issues are being created
   - or the structure is non-trivial

5. Draft the issue or issue bundle:
   - bugs use the lean bug template
   - larger work uses structured templates
   - keep DOR proportional to scope

6. Present the proposed issue(s).

7. Stop for the only gate:
   - `Proposed issue breakdown ready. Approve writing these issues.`

8. On approval, write the issue(s). Otherwise revise and re-present.

## Rules

- Keep discovery conditional.
- Keep DOR proportional to issue size and type.
- Deterministic work belongs in `<workspace-root>/agentic-scripts`.
- The only formal gate in this skill is approval to write the proposed issue(s).
- When drafting an epic with stories, create the stories as separate issues and attach them to the epic as GitHub sub-issues.
- Apply the minimum necessary structure to make the issue actionable; avoid over-expansion.
