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
- `/implement`

Claude commands live in `.claude/commands`. Codex uses the matching skills from `~/.codex/skills` or repo-local overrides in `codex-skills/`.

### Primary Delivery Flow

```text
/sdlc-do #<issue>
```

You can also use direct requests:

```text
/sdlc-do implement this request
```

### Two-Gate Mode

Only two approvals are expected:

1. Plan approval
   - approve or revise the implementation plan
2. Final approval
   - `Commit and merge.`
   - or `Commit and push up as Pull Request.`

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
- `--keep-agents`

It does not copy `codex-skills/`. The intended model is:

- portable runtime stays in the repo
- skills are global by default from `~/.codex/skills`
- repo-local `codex-skills/` are only for project-specific overrides

It also removes `AGENTS.md` from the target if present, so the default setup stays lean and avoids duplicated policy files.

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
- Repo trigger behavior is defined in `AGENTS.md`.
- Global availability is from `~/.codex/skills` (app-level install).
- Claude command mirrors live in `.claude/commands/<name>.md` when you want the same workflow available there.

The lean active surface is:

- `/issues`
- `/sdlc-do`
- `/implement`

In Codex threads, invoke by naming the skill, for example:

```text
$issues
```

You can also use slash-style wording (`/issues`) or plain language that clearly matches the skill intent.

### Skill Usage Rules

Use the matching skill whenever the request clearly fits one of the supported workflows:

- `$issues` or `/issues`: turn rough product or engineering input into issue drafts. If the work is an epic with stories, the flow must produce a parent epic issue plus separate child story issues attached as GitHub sub-issues.
- `$sdlc-do` or `/sdlc-do`: run the full two-gate delivery flow for implementation work.
- `$implement` or `/implement`: make a small direct change without the full SDLC ceremony.

Keep the deterministic logic in `agentic-scripts/` and the skill/command contract in `codex-skills/` or `.claude/commands/`. When you update one of the shared issue-flow scripts, propagate the same change to every repo that carries that script so the command surface does not drift.
