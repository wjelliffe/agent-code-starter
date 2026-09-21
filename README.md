# Agent Code Starter

> **Give your coding agent judgment, not bureaucracy.**

Agent Code Starter is a small set of bounded software-delivery workflows backed by deterministic runtime helpers.

The design goal is simple:

> **The model decides what code to change. Scripts do everything deterministic. One task stays one task.**

A normal implementation should not turn into a planner → implementer → reviewer → fixer → reviewer loop. ACS intentionally forbids that default behavior.

## Four skills

ACS has exactly four human-facing skills:

- **`issues`** — turn product/engineering input into actionable GitHub issues.
- **`implement`** — cheap, bounded execution for one clear issue or request.
- **`sdlc-do`** — explicit stricter execution for one bounded unit when you want the extra ceremony.
- **`code-review`** — one-shot skeptical review. Review only; no edits.

There is no `verify` skill, no debugging skill, no review-remediation skill, and no automatic routing skill. Those concerns are either inline execution rules or deterministic runtime behavior.

## The execution contract

Both implementation flows are hard-bounded:

- one primary agent
- zero sub-agents
- zero agent-team orchestration
- zero automatic retries
- at most one review invocation per execution
- zero autonomous review → fix → re-review loops
- no automatic escalation from `implement` to `sdlc-do`
- stop on command failure and report evidence

If review finds blockers, ACS stops. Fixing them is a later explicit user action, not an invisible recursive loop.

## Two implementation modes

| | `implement` | `sdlc-do` |
|---|---|---|
| Use for | Clear single task | Explicit strict pass |
| Plan approval | No | Yes |
| Isolation | Minimal/safe | Branch/worktree |
| Testing | Targeted | Deliberate |
| Review | Optional, user-selected | Optional, user-selected |
| Retry loops | Never | Never |
| Sub-agents | Never | Never |

The choice is explicit. ACS does not inspect keywords and silently promote a task into a larger workflow.

## Deterministic runtime

`runtime/` contains the mechanics that should not consume model judgment:

- issue normalization/writing
- branch/worktree setup
- check and test execution
- diff summaries
- Definition of Ready / Definition of Done validation
- final commit/merge/PR behavior

Runtime helpers execute against the target repository working directory. The plugin stays the methodology; the target repository stays the source of project truth.

## Repository layout

```text
Agent Code Starter
├── .agents/plugins/     Codex/ChatGPT marketplace metadata
├── .codex-plugin/       Codex plugin manifest
├── .claude-plugin/      Claude Code plugin metadata
├── skills/
│   ├── issues/
│   ├── implement/
│   ├── sdlc-do/
│   └── code-review/
├── runtime/             deterministic helpers
└── tests/               behavioral/runtime regression tests
```

## Installation

### ChatGPT workspace

Workspace admins can import this repository directly:

1. Open **Workspace settings → Plugins**.
2. Select **Add → Import marketplace**.
3. Use `https://github.com/wjelliffe/agent-code-starter`.
4. Use the default branch (`main`).
5. Import the marketplace and make Agent Code Starter available to the desired users.

### Personal Codex

```bash
codex plugin marketplace add wjelliffe/agent-code-starter --ref main
codex plugin add agent-code-starter@agent-code-starter
```

Start a new Codex task after installation so the skills are rediscovered.

### Claude Code

```bash
claude plugin marketplace add wjelliffe/agent-code-starter
claude plugin install agent-code-starter@agent-code-starter
```

If Claude Code asks for a reload:

```text
/reload-plugins
```

To update later:

```bash
claude plugin marketplace update agent-code-starter
claude plugin update agent-code-starter@agent-code-starter
```

## Project overrides

Repositories may optionally provide `.agent-code.json` for deterministic command configuration:

```json
{
  "trunk_branch": "main",
  "branch_prefix": "agent/",
  "commands": {
    "checks": ["npm run lint", "npm run typecheck"],
    "tests": ["npm test"]
  }
}
```

See [configuration](docs/configuration.md).

## Development

Run the regression suite with:

```bash
python3 -m unittest discover -s tests -v
```

The tests intentionally enforce the four-skill surface and bounded execution contract so recursive orchestration cannot quietly creep back in.
