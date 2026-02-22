# Commit Issue Work

Create a local commit for the current issue branch, include issue-closing reference, and remove local pulled issue doc before finalizing.

## Usage

- `/commit #62`
- `/commit 62`

## Procedure

### 1. Validate branch and tree

- Refuse if on `main`.
- Run `git status` and summarize staged/unstaged changes.
- If issue number missing, ask for it.

### 2. Remove local pulled issue doc (if present)

Before commit, remove local issue mirror doc for this issue if it exists:

- `docs/issues/ISSUE-<num>.md`

This avoids duplicating canonical issue content that already lives on GitHub.

### 3. Build commit message

Use conventional style + issue closure in body:

```text
<type>(<scope>): <summary>

Fixes #<num>
```

Type defaults:
- `feat` for feature work
- `fix` for bug work
- `docs` for docs-only
- `refactor` for structural improvements

### 4. Commit

```bash
git add -A
git commit -m "<subject>" -m "Fixes #<num>"
```

### 5. Optional local merge + branch cleanup (only if user asked)

If the user explicitly requests local integration flow:

```bash
git checkout main
git pull origin main
git merge --ff-only <branch> || git merge <branch>
git branch -d <branch>
```

Do not do this unless explicitly requested.

## Rules

- **Never commit directly on main.**
- **Always include `Fixes #<num>` when issue number is provided.**
- **Delete local pulled issue doc for that issue before commit.**
