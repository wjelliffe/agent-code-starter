# Start New Work

Initialize a new feature or bug fix branch following the project's development workflow.

## Usage

- `/start #62`
- `/start 62`
- `/start auth flow`

## Procedure

### 1. Validate Clean Tree

Run `git status`. If there are uncommitted changes:
- List them for the user
- Ask whether to stash, commit, or abort
- Do NOT proceed until the tree is clean

### 2. Sync with Main

```bash
git checkout main
git pull origin main
```

If checkout fails (e.g., detached HEAD, merge conflict), surface the error and ask for guidance.

### 3. Create Feature Branch

Parse `$ARGUMENTS`.

- If `$ARGUMENTS` includes an issue number (`#62` or `62`):
  - Fetch issue title: `gh issue view <num> --json title`
  - Generate deterministic branch name:
    - default: `feat/issue-<num>-<kebab-issue-title>`
    - if issue clearly indicates bug/fix: `fix/issue-<num>-<kebab-issue-title>`
- If `$ARGUMENTS` is freeform text, convert to:
  - Features: `feat/<kebab-case>`
  - Bug fixes: `fix/<kebab-case>`
  - Docs/chores: `docs/<name>` or `chore/<name>`
- If no argument is provided, ask what work is being started.

Create branch:

```bash
git checkout -b <resolved-branch-name>
```

### 4. Confirm

Print summary:

```text
Branch: <resolved-branch-name>
Status: Clean tree, up to date with main
Next: /pull #<issue> (if issue-driven)
```

## Rules

- **Never skip the clean tree check.**
- **Never commit directly to main.**
- **Prefer issue-number branch naming when issue is provided.**
- If `$ARGUMENTS` is empty, ask for intent before creating a branch.
