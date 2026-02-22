# Update Docs for Current Work

Capture architectural, operational, and workflow documentation updates required by the current issue.

## Procedure

### 1. Gather context

Use, in order:
1. current conversation context
2. local issue doc in `docs/issues/ISSUE-<num>.md`
3. affected files and relevant spec/docs (`spec/`, `docs/`, `.env.example`, `README.md`)

### 2. Identify required doc changes

Determine the minimum set of docs/spec updates needed to keep repository truth accurate.

### 3. Propose doc changes (approval gate)

Before editing, present:
1. files to update
2. summary of each change
3. risks/assumptions
4. follow-ups

Wait for explicit approval.

### 4. Apply doc updates

Make concise, direct edits aligned with existing style.

### 5. Confirm

Report:
- docs updated
- files touched
- what decisions/changes were captured

## Rules

- **No code edits** in `/docs` mode unless explicitly requested.
- **Do not run installs/tests** unless explicitly approved.
- Keep changes tightly scoped to current issue.
