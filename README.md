# Agent Code Starter

> **Give your coding agent judgment, not bureaucracy.**

Agent Code Starter is a small set of bounded software-delivery workflows backed by deterministic runtime helpers.

The design goal is simple:

> **The model decides what code to change. Scripts do everything deterministic. One task stays one task.**

A normal implementation must not turn into a planner → implementer → reviewer → fixer → reviewer loop.

## Four skills

ACS has exactly four human-facing skills:

- **`issues`** — turn product/engineering input into actionable GitHub issues.
- **`implement`** — cheap, bounded execution for one clear issue/request, or one bounded pass addressing existing PR review feedback.
- **`sdlc-do`** — explicit stricter execution for one bounded unit when you want the extra ceremony.
- **`code-review`** — one-shot, read-only adversarial review of a PR or diff.

There is no verify skill, debugging skill, review-remediation skill, or automatic routing skill. Those concerns are either inline execution rules or deterministic runtime behavior.

## The execution contract

Implementation flows are hard-bounded:

- one primary agent
- zero sub-agents
- zero agent-team orchestration
- zero automatic retries
- zero automatic review invocations
- zero autonomous review → fix → re-review loops
- no automatic escalation from `implement` to `sdlc-do`
- stop on command failure and report evidence

## Cross-AI review workflow

The intended review flow is deliberately split across independent sessions/models:

```text
AI A: implement / sdlc-do
        ↓
      push PR
        ↓
      STOP
        ↓
AI B: code-review
        ↓
 GitHub review comments
        ↓
      STOP
        ↓
AI A: implement review remediation
        ↓
   push same PR
        ↓
      STOP
        ↓
optional explicit re-review by AI B
```

Every transition between those stages is initiated by the user. ACS never creates an autonomous review loop.

### Implementation

`implement` and `sdlc-do` finish with exactly two choices:

- `Commit and merge.`
- `Commit and push up as Pull Request.`

They do not review their own work.

### Independent review

Run `code-review` separately, ideally with a different AI/model/session. For a PR, it performs one skeptical pass and, when GitHub write access is available, posts one COMMENT review with actionable inline findings where they can be safely anchored.

The reviewer never edits code.

### Addressing review comments

Run `implement` again and explicitly ask it to address review comments on the existing PR. It works on that PR's head branch, fixes valid findings, runs relevant verification once, pushes to the same PR, replies to threads when useful, and stops.

Re-review only when you explicitly ask AI B to run `code-review` again.

## Two implementation modes

| | `implement` | `sdlc-do` |
|---|---|---|
| Use for | Clear task or PR remediation | Explicit strict pass |
| Plan approval | No | Yes |
| Isolation | Minimal/safe | Branch/worktree |
| Testing | Targeted | Deliberate |
| Self-review | Never | Never |
| Retry loops | Never | Never |
| Sub-agents | Never | Never |

The choice is explicit. ACS does not inspect keywords and silently promote a task into a larger workflow.

## Deterministic runtime

`runtime/` contains mechanics that should not consume model judgment:

- issue normalization/writing
- branch/worktree setup
- check and test execution
- diff summaries
- Definition of Ready / Definition of Done validation
- final commit/merge/new-PR behavior
- safe updates to an existing PR branch

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

The tests enforce the four-skill surface, no self-review, no recursive orchestration, and safe existing-PR remediation.
