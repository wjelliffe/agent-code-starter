# Agent Code Starter

> **Give your coding agent judgment, not bureaucracy.**

Agent Code Starter is a portable, deterministic software-delivery system for coding agents. It packages the boring mechanics with the plugin so the model can spend its intelligence where it matters: understanding requirements, designing the change, writing code, and attacking the result in review.

> **The model decides what code to change. Scripts do everything deterministic. One task stays one task.**

No copied `agentic-scripts/` folder. No Python runtime. No mystery router deciding what workflow you meant. No infinite reviewer-fixer treadmill.

## Four skills. One workflow.

ACS has four bounded judgment skills:

- **`issues`** — turn rough product/engineering input into actionable GitHub work.
- **`plan`** — design one change against the actual repository before touching code.
- **`implement`** — execute one bounded coding pass or remediate one existing PR.
- **`code-review`** — perform one skeptical, read-only adversarial review.

And one end-to-end workflow:

- **`sdlc-do`** — plan it with me, then finish the feature.

`/sdlc-do` is not a giant prompt pretending to be an orchestrator. It is a thin facade over a deterministic finite state machine.

```text
plan → approve → implement → verify → PR → review
                                      │
                         approve ─────┘────→ merge → done
                                      │
                                   blockers
                                      ↓
                                  remediate
                                      ↓
                                   reverify
                                      ↓
                                 final review
                                  ↙         ↘
                              approve      blockers
                                ↓             ↓
                              merge        BLOCKED
```

There is no arrow from the final review back into another remediation loop.

## Why this is different

Most agent workflows ask an expensive model to remember where it is, decide what comes next, run shell commands, interpret exit codes, invent retry policy, and somehow know when to stop.

ACS pushes that work down into deterministic scripts.

The workflow controller can tell even a lightweight runner:

```text
ACS SDLC issue-107
State: REVIEW_1_REQUIRED
Review passes: 0/2
PR: #123
Next: Run one fresh adversarial review pass.
```

The runner does not have to reconstruct the lifecycle from chat history. It follows the state machine.

That means stronger models can focus on planning, implementation, and review while orchestration stays explicit, deterministic, and reproducible.

## The plugin ships the engine

The deterministic helpers live beside the skills that use them:

```text
skills/
├── issues/
│   ├── SKILL.md
│   └── scripts/
├── plan/
│   ├── SKILL.md
│   └── scripts/
├── implement/
│   ├── SKILL.md
│   └── scripts/
├── code-review/
│   ├── SKILL.md
│   └── scripts/
└── sdlc-do/
    ├── SKILL.md
    └── scripts/
```

Application repositories do **not** need a copied ACS framework directory. Install the plugin and the engine comes with it.

Every runtime helper ships in both Bash and PowerShell form. ACS itself requires no Python, Node, or other language runtime. It only assumes the tools needed for the action being performed, primarily `git` and `gh` for GitHub operations. Project-specific language runtimes are used only when running that project's own checks/tests.

## What the scripts own

Deterministic code handles:

- GitHub issue reads/writes
- branch and worktree setup
- configured or auto-detected checks/tests
- diff summaries
- plan/review contract validation
- PR creation and same-PR remediation updates
- PR merge
- persisted SDLC state
- legal workflow transitions
- hard review/remediation limits

The model handles:

- what the requirement means
- how the repository should change
- writing the code
- whether acceptance criteria and invariants are satisfied
- adversarial review judgment

> **The orchestrator belongs in deterministic code. The model is a bounded worker.**

## `implement` vs `sdlc-do`

| | `implement` | `sdlc-do` |
|---|---|---|
| Best for | Clear bounded task | Feature you want driven to completion |
| Plan gate | No | Yes |
| Isolation | Safe branch | Worktree/branch |
| Review | Separate | Built into the finite lifecycle |
| Remediation | Explicit one-pass mode | At most once |
| Final review | Explicit if desired | Yes, after remediation |
| End state | Merge or PR | `DONE` or `BLOCKED` |

Use `implement` when the task is obvious and you want speed. Use `sdlc-do` when you want to approve the design once and have ACS carry the bounded feature through review and merge.

## Cross-AI review still works

The standalone primitives remain useful independently. You can have one provider implement and another attack the PR:

```text
AI A: implement → PR
AI B: code-review → findings
AI A: implement remediation → same PR
AI B: optional explicit re-review
```

`sdlc-do` simply bakes a bounded version of that lifecycle into deterministic state: maximum two review passes, maximum one remediation pass.

## Project configuration

Most repositories need nothing.

If a project wants explicit overrides, add a tiny `.agent-code` file:

```text
trunk_branch=main
branch_prefix=agent/
check=npm run lint
check=npm run typecheck
test=npm test
```

Repeated `check=` and `test=` lines are executed in order. The deliberately simple line format avoids requiring a JSON parser or scripting language runtime.

See [configuration](docs/configuration.md).

## Installation

### ChatGPT workspace / Work

Workspace admins can import this repository as a plugin marketplace:

1. Open **Workspace settings → Plugins**.
2. Select **Add → Import marketplace**.
3. Use `https://github.com/wjelliffe/agent-code-starter`.
4. Use the default branch (`main`).
5. Import Agent Code Starter and make it available to the desired users.

Executable workflows require a coding execution environment such as Work or Codex. Ordinary chat can read the skill instructions but should not pretend it executed repository scripts when no shell/repository environment exists.

### Personal Codex

```bash
codex plugin marketplace add wjelliffe/agent-code-starter --ref main
codex plugin add agent-code-starter@agent-code-starter
```

Start a new Codex task after installation so skills are rediscovered.

### Claude Code

```bash
claude plugin marketplace add wjelliffe/agent-code-starter
claude plugin install agent-code-starter@agent-code-starter
```

If Claude Code asks for a reload:

```text
/reload-plugins
```

## Development

ACS has no runtime language dependency. The regression suite is shell-native too:

```bash
bash tests/run.sh
```

On Windows:

```powershell
pwsh -File tests/run.ps1
```

CI runs both Linux/Bash and Windows/PowerShell.

## Design rule

A coding agent should not spend reasoning tokens babysitting deterministic mechanics.

**Let scripts remember the state. Let scripts enforce the bounds. Let the model think.**
