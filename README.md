# Agent Code Starter

Starter kit for lean AI-assisted product and software delivery with a small command surface and deterministic runtime scripts.

## Included

- `CODEX.md` (portable Codex guidance)
- `.claude/commands/*` (lean Claude command surface)
- `agentic-scripts/*` (deterministic runtime layer)
- `.github/workflows/deploy-template.yml` (generic deploy template)

## Lean Command Set

The active command model is:

- `/issues`
- `/sdlc-do`

Claude commands live in `.claude/commands`. Codex uses the matching skills from `~/.codex/skills` or repo-local overrides in `codex-skills/`.

### Primary Delivery Flow (Default: Fast Path)

```text

/implement #<issue>
```

## Execution Strategy (Critical)

Default to `/implement`.

Use `/implement` for:
- Most feature work
- Small to medium changes
- Iteration and prototyping
- Bug fixes
- Any task where the implementation is already clear

Use `/sdlc-do` ONLY when:
- The change is high risk (auth, data integrity, infra)
- Multiple subsystems are involved
- The implementation approach is unclear
- You explicitly want TDD or formal validation
- Failure would be costly or hard to unwind

If unsure:
→ Start with `/implement`
→ Escalate to `/sdlc-do` only if needed

Never default to `/sdlc-do`.

Grouped sibling tickets are also valid when they are one bounded delivery unit:

```text
/sdlc-do #30 and #31 together
```

You can also use direct requests:

```text
/sdlc-do implement this request
```

### Two-Gate Mode (SDLC Only)

This applies ONLY when using `/sdlc-do`.
Only two approvals are expected:

1. Plan approval
   - approve or revise the implementation plan
2. Final approval
   - `Commit and merge.`
   - or `Commit and push up as Pull Request.`

For issue-based work, finalization should go through `agentic-scripts/finalize_work.sh` when the user asks to commit or finalize, including the lightweight `/sdlc-do` path. In this flow, a "closing comment" means an issue-closing footer in the commit body or PR body such as `Fixes #123` or `Closes #123`, not a separate GitHub issue comment.

Do not use `gh issue close`, `gh issue comment`, or any separate GitHub issue close/comment action unless the user explicitly asks for that.

If revisions are requested:
- plan revisions return to Gate 1
- code revisions return to Gate 2

## Quick Bootstrap Checklist

1. Decide which bootstrap files you want to bring into the target repo.
2. Update `agentic-scripts/` for the repo’s real architecture where needed.
3. Replace deploy template workflow with your real CI/CD workflow.
4. Confirm any GitHub labels or workflow conventions used by your issue flow.

## Codex Bootstrap

If you mainly use Codex, initialize a sibling repo with the portable starter files:

```text
./bootstrap_codex_project.sh <repo-name>
```

This copies:

- `CODEX.md`
- `.gitignore`
- `agentic-scripts/`

If you do not pass flags, the bootstrap script will ask what to bring over.

Useful flags:

- `--with-github`
- `--no-github`
- `--no-codex`
- `--no-gitignore`
- `--no-agentic-scripts`

It does not copy `codex-skills/`. The intended model is:

- portable runtime stays in the repo
- skills are global by default from `~/.codex/skills`
- repo-local `codex-skills/` are only for project-specific overrides

Add the optional GitHub workflow template with:

```text
./bootstrap_codex_project.sh <repo-name> --with-github
```

## Notes

- By default, commands preserve strict approval-gate behavior and avoid destructive actions.
- `agentic-scripts/run_tests.sh` is a starter adapter and may need repo-specific updates for non-JS or unusual test architectures.

## Skills And Commands

This template also supports Codex skills in `codex-skills/` when a repo needs local overrides.

- Repo-defined skill instructions live in `codex-skills/<skill-name>/SKILL.md`.
- Global availability is from `~/.codex/skills` (app-level install).
- Claude command mirrors live in `.claude/commands/<name>.md` when you want the same workflow available there.

The lean active surface is:

- `/issues`
- `/sdlc-do`

In Codex threads, invoke by naming the skill, for example:

```text
$issues
```

You can also use slash-style wording (`/issues`) or plain language that clearly matches the skill intent.

### Skill Usage Rules

Use the matching skill whenever the request clearly fits one of the supported workflows:

- `$issues` or `/issues`: turn rough product or engineering input into issue drafts. If the work is an epic with stories, the flow must produce a parent epic issue plus separate child story issues attached as GitHub sub-issues.
- `$implement` or `/implement`: default execution path. Use for most work. Minimal overhead, fast iteration, targeted validation.
- `$sdlc-do` or `/sdlc-do`: high-ceremony execution path. Use only for complex, risky, or unclear work that benefits from planning, TDD, and formal validation.

Keep the deterministic logic in `agentic-scripts/` and the skill/command contract in `codex-skills/` or `.claude/commands/`. When you update one of the shared issue-flow scripts, propagate the same change to every repo that carries that script so the command surface does not drift.

## Anti-Overengineering Rule

The system is intentionally biased toward speed.

- Prefer fast iteration over perfect process
- Prefer direct implementation over planning
- Prefer targeted validation over full SDLC

Do NOT use `/sdlc-do` by default.

If the work can be completed safely without full SDLC:
→ use `/implement`

Escalation is allowed.
Overhead is not required.
