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

- **One concern per issue** — don't mix schema changes with UI work
- **Dependency order** — note which issues block others
- **Implementation detail** — include enough context to code from:
  - Files to create or modify
  - Key decisions already made
  - Acceptance criteria (what "done" looks like)

### 3. Draft Issues for Review

Before creating anything on GitHub, present the full list to the user:

```
I'll create these issues:

1. **feat: Add BugReport schema + migration**
   Labels: area:database, size:small
   Files: prisma/schema.prisma
   Blocked by: none

2. **feat: Add bug report submit API**
   Labels: area:backend, size:small
   Files: src/app/api/bug-reports/route.ts
   Blocked by: #1
   ...
```

Wait for explicit approval before creating issues. The user may want to adjust scope, combine issues, or reorder.

### 4. Create Issues on GitHub

Use the `gh` CLI to create each issue:

```bash
gh issue create --title "<title>" --body "<body>" --label "<labels>"
```

**Title format:** Use conventional commit style — `feat: ...`, `fix: ...`, `docs: ...`

**Body format:**
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

**Labels** — use existing repo labels:
- Area: `area:frontend`, `area:backend`, `area:database`
- Size: `size:small`, `size:medium`, `size:large`
- Type: `bug`, `enhancement`
- Add `navigation`, `For Laura`, or other project-specific labels as appropriate

### 5. Report Results

After creation, print a summary table:

```
Created N issues:

| # | Title | Labels | Blocked by |
|---|-------|--------|------------|
| 61 | feat: Add BugReport schema | area:database, size:small | — |
| 62 | feat: Add submit API | area:backend, size:small | #61 |
...
```

## Rules

- **Always get approval before creating issues.** Present the draft list first.
- **Reference issue numbers** in "blocked by" fields after creation — update issue bodies if needed.
- **Don't create issues for trivial steps** like "run npm install" — only for meaningful code changes.
- **Match existing label conventions** — check `gh label list` if unsure what labels exist.
