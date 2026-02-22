---
name: issues
description: Turn an approved implementation plan into detailed GitHub issues.
metadata:
  short-description: Draft and create issue breakdown from approved plan
---

# Create GitHub Issues from Plan

Turn an approved implementation plan into detailed GitHub issues that are specific enough to code from.

## Procedure

### 1. Gather the Plan

Locate the implementation plan from one of these sources (in priority order):
1. The current conversation context (if a plan was just approved)
2. A plan file referenced in the conversation
3. Relevant `spec/` or `docs/` files on the current branch

If no plan is found, ask the user what work needs to be broken into issues.

### 2. Break into Issues

Decompose the plan into discrete, implementable units. Each issue should represent a single logical change that could be its own commit. Guidelines:

- **One concern per issue**. Do not mix schema changes with UI work.
- **Dependency order**. Note which issues block others.
- **Implementation detail**. Include:
  - Files to create or modify
  - Key decisions already made
  - Acceptance criteria

### 3. Draft Issues for Review

Before creating anything on GitHub, present the full list to the user and wait for explicit approval.

### 4. Create Issues on GitHub

Use the `gh` CLI to create each issue:

```bash
gh issue create --title "<title>" --body "<body>" --label "<labels>"
```

Title format: conventional commit style (`feat: ...`, `fix: ...`, `docs: ...`).

Body format:

```markdown
## Summary
<1-2 sentences>

## Details
- Files to create/modify: ...
- Key decisions: ...
- Dependencies: Blocked by #X

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

Labels should match existing repo conventions.

### 5. Report Results

After creation, print a summary table with issue number, title, labels, and blockers.

## Rules

- **Always get approval before creating issues.**
- **Reference issue numbers** in blocker fields after creation and update bodies if needed.
- **Do not create issues for trivial steps.**
- **Match existing label conventions**; check `gh label list` if unsure.
