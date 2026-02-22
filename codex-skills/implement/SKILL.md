---
name: implement
description: Implement an issue in scoped, approval-gated steps.
metadata:
  short-description: Plan then implement with explicit approval before edits
---

# Implement Issue

Implement the requested issue in scoped, approval-gated steps.

## Usage

- `/implement #62`
- `/implement 62`

## Procedure

### 1. Load issue context

Use, in order:
1. local issue doc `docs/issues/ISSUE-<num>.md` (preferred)
2. `gh issue view <num>`
3. current conversation context

If issue number is missing, ask for it.

### 2. Define scoped execution plan

List only in-scope work for this issue:
- files likely to change
- implementation steps
- risks/assumptions

### 3. Approval gate before edits

Before changing files, present:
1. proposed file changes
2. risks/assumptions
3. follow-ups

Wait for explicit approval.

### 4. Implement

Make minimal, incremental edits aligned to issue acceptance criteria.

### 5. Report completion

Provide:
- summary of changes
- files touched
- how acceptance criteria were satisfied
- any manual verification steps

## Rules

- **Do not expand scope** beyond issue unless user approves.
- **Do not run installs/tests** unless explicitly requested or approved.
- Respect repo approval-gate and safety rules.
