# Pull Issue to Local Doc

Fetch a GitHub issue and materialize it as a local working doc for execution.

## Usage

- `/pull #62`
- `/pull 62`

## Procedure

### 1. Validate input

- Require an issue number from `$ARGUMENTS`.
- If missing, ask for the issue number.

### 2. Fetch issue from GitHub

Use `gh`:

```bash
gh issue view <num> --json number,title,body,labels,assignees,url,state
```

If the issue is missing/inaccessible, report clearly and stop.

### 3. Propose local file write (approval gate)

Before writing, propose creating/updating:

- `docs/issues/ISSUE-<num>.md`

Include planned sections:
- Issue metadata (title, URL, labels, state)
- Source-of-truth acceptance criteria (copied from issue)
- Execution checklist
- Notes/assumptions
- Implementation log

Wait for explicit approval before writing.

### 4. Write local issue doc

Create/update `docs/issues/ISSUE-<num>.md` with concise, execution-ready structure.

### 5. Confirm

Report:
- issue fetched
- local doc path
- suggested next command (`/docs` or `/implement #<num>`)

## Rules

- **Do not edit files without approval.**
- **Do not reinterpret acceptance criteria.** Preserve issue intent.
- Keep doc concise and execution-oriented.
