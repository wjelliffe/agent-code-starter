---
name: ship
description: Create a PR from the current branch and close resolved issues.
metadata:
  short-description: Run preflight checks, open PR, and handle issue closure
---

# Ship: PR Creation + Issue Cleanup

Create a pull request for the current branch and close any GitHub issues resolved by the work.

## Procedure

### 1. Pre-flight Checks

Run these checks and surface any problems before proceeding:

- Clean tree: `git status`
- Not on `main`
- Pushed to remote (push with `-u` if missing upstream)
- TypeScript: `npx tsc --noEmit` (warn on errors; do not silently ignore)

### 2. Analyze Changes

Gather context for the PR description:

```bash
git log main..HEAD --oneline
git diff main...HEAD --stat
```

Read all branch commits and changed files.

### 3. Create Pull Request

Use `gh pr create --title "<title>" --body "<body>"`.

Body should include `## Summary`, `## Changes`, `## Test plan`, and `Resolves #X` lines for auto-closing.

### 4. Identify Issues to Close

- Check commit messages for issue references.
- Check matching issues for completed work.
- Confirm issue list with the user.
- Close any manual-close issues with:

```bash
gh issue close <number> --comment "Resolved in PR #<pr-number>"
```

### 5. Clean Up Merged Branches (post-merge only)

Run only when user explicitly confirms merge happened:

```bash
git checkout main && git pull
git branch -d <branch-name>
git remote prune origin
```

### 6. Report

Print summary including PR number, URL, resolved issues, and branch mapping.

## Rules

- **Always run pre-flight checks.**
- **Include `Resolves #X`** in PR body when applicable.
- **Do not delete branches until post-merge and explicit instruction.**
- **Do not force-push** unless explicitly requested.
