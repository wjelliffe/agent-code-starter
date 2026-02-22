# Ship: PR Creation + Issue Cleanup

Create a pull request for the current branch and close any GitHub issues resolved by the work.

## Procedure

### 1. Pre-flight Checks

Run these checks and surface any problems before proceeding:

- **Clean tree:** `git status` — warn if there are uncommitted changes
- **Not on main:** Refuse to create a PR from main
- **Pushed to remote:** Check if the branch has an upstream. If not, push with `-u`
- **TypeScript:** Run `npx tsc --noEmit` — warn if there are type errors (don't block, but flag)

### 2. Analyze Changes

Gather context for the PR description:

```bash
git log main..HEAD --oneline          # All commits on this branch
git diff main...HEAD --stat           # Files changed summary
```

Read through the commit messages and changed files to understand the full scope. Look at ALL commits, not just the latest.

### 3. Create Pull Request

Use `gh pr create` with a well-structured description:

```bash
gh pr create --title "<title>" --body "<body>"
```

**Title:** Short (under 70 chars), conventional commit style. Summarize the whole branch, not individual commits.

**Body format:**
```markdown
## Summary
<1-3 bullet points covering what changed and why>

## Changes
<brief list of major changes, grouped logically>

## Test plan
- [ ] Test step 1
- [ ] Test step 2

Resolves #X, #Y, #Z

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Include `Resolves #X` for each issue this PR closes (GitHub auto-closes them on merge).

### 4. Identify Issues to Close

Search for related issues that this PR resolves:

- Check commit messages for issue references (`#41`, `Issue #41`, etc.)
- Check the GitHub issues list for issues that match the work done
- Present the list to the user for confirmation

If the `Resolves #X` lines in the PR body will handle auto-closing, note that. If any issues need manual closing (e.g., they were addressed but not directly referenced), close them with:

```bash
gh issue close <number> --comment "Resolved in PR #<pr-number>"
```

### 5. Clean Up Merged Branches (post-merge only)

This step only applies if the user says the PR has been merged. Do NOT run this automatically.

```bash
git checkout main && git pull
git branch -d <branch-name>           # Delete local branch
git remote prune origin               # Clean stale remote refs
```

### 6. Report

Print a summary:

```
PR: #<number> — <title>
URL: <url>
Issues resolved: #X, #Y, #Z
Branch: <name> → main
```

## Rules

- **Always run pre-flight checks.** Don't create a PR with type errors or uncommitted changes without flagging them.
- **Include `Resolves #X` in the PR body** for auto-closing. Ask the user which issues to reference if unclear.
- **Don't delete branches until the PR is merged.** Only clean up when explicitly told the merge happened.
- **Don't force-push** unless the user explicitly asks.
