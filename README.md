# Agent Code Starter

> **Give your coding agent judgment, not just instructions.**

[![CI](https://github.com/wjelliffe/agent-code-starter/actions/workflows/ci.yml/badge.svg)](https://github.com/wjelliffe/agent-code-starter/actions/workflows/ci.yml)

Agent Code Starter is an adaptive software-delivery plugin for coding agents.

It is built around a simple idea:

> **Move quick when you can; go deep when you need.**

We love the tools and workflows already out there. Agent Code Starter takes a deliberately speed-first approach: start with the quickest responsible path, apply clear litmus tests for risk, and step up the SDLC only when the change calls for it.

A copy change should not trigger an architecture summit.  
An auth migration should not get a three-line plan and a thumbs-up.

**Maximum speed when speed is safe. Maximum rigor when rigor matters.**

---

## The whole idea

```text
                         ┌─────────────────────┐
 request / issue ───────▶│  Agent Code Starter │
                         └──────────┬──────────┘
                                    │
                               assess risk
                              ╱             ╲
                             ╱               ╲
                     ordinary work        risky work
                          │                   │
                     /implement          /sdlc-do
                          │                   │
                  inspect existing       explicit plan
                  architecture           isolated worktree
                  smallest change        deeper testing
                  targeted tests         mandatory review
                          │                   │
                          └─────────┬─────────┘
                                    ▼
                             fresh evidence
                                    │
                                    ▼
                              merge / PR
```

The default is **not** "do the maximum process."

The default is **use the minimum process that reliably produces correct software**.

---

## Why it feels different

### ⚡ Fast by default

`implement` is the normal path.

Read the issue. Inspect the existing code. Understand the architecture. Make the smallest correct change. Run the checks that matter. Keep moving.

No mandatory design document because you changed a validation message.

### 🧠 Rigor is adaptive

Agent Code Starter steps up automatically when the work materially involves things like:

- authentication or authorization
- secrets, tokens, encryption, or security controls
- schema migrations, backfills, or data integrity
- transactions, concurrency, race conditions, or idempotency
- billing or payments
- production infrastructure
- multiple coupled subsystems
- an implementation approach that is genuinely unclear
- an explicit request for strict TDD or a full SDLC pass

That path is `sdlc-do`: plan, isolate, test deliberately, verify fully, perform a skeptical review, then finalize.

### 🔍 Review the code that actually exists

Code review is not "read the PR description and glance at the diff."

The review workflow checks the linked issue and comments, current trunk, surrounding architecture, important invariants, tests, CI, regressions, and — when relevant — auth/authz, unsafe input, SQL, secrets, logging, state transitions, concurrency, migrations, and backfills.

### 🐛 Root cause before patching

When the cause of a failure is not already known, `systematic-debugging` reproduces, traces, forms a falsifiable hypothesis, and fixes the owning layer.

Less agent whack-a-mole.

### ✅ Evidence before "done"

Agent Code Starter does not allow optimistic completion semantics.

- "No tests found" is **not** "tests passed."
- A failed PR creation is **not** success.
- A clean linter is **not** proof that the build works.
- Code that looks correct is **not** verified code.

Fresh evidence before completion claims.

### 🔌 Install the methodology once

v2 is plugin-first.

The engineering workflow lives in the plugin. Your application repository keeps the things that actually belong to the application: architecture, domain rules, constraints, tests, deployment conventions, and optional local overrides.

No spraying the same agent scripts and prompts into every repo. No propagation commits every time the framework improves.

---

## Two speeds

| | `implement` | `sdlc-do` |
|---|---|---|
| Best for | Clear, bounded changes | Risky, cross-cutting, or ambiguous work |
| Planning | Brief execution preview | Explicit approved plan |
| Isolation | Safe feature branch | Worktree by default |
| Testing | Targeted and proportional | Deliberate, deeper coverage |
| TDD | When it adds value | Preferred for behavior changes |
| Review | Optional / risk-driven | Mandatory |
| Verification | Required | Required |
| Goal | **Move fast safely** | **Make expensive mistakes hard** |

---

## Skills

Agent Code Starter ships with one canonical skill set:

- **`issues`** — turn rough product or engineering input into actionable GitHub issues.
- **`implement`** — default low-overhead implementation workflow.
- **`sdlc-do`** — rigorous workflow for risky or ambiguous changes.
- **`code-review`** — skeptical senior/staff-level review against requirements, trunk, architecture, tests, security, and CI.
- **`systematic-debugging`** — reproduce, trace, isolate root cause, then fix.
- **`verify`** — require fresh evidence before claiming completion.
- **`address-review`** — evaluate review feedback technically, fix valid findings, verify, and respond.

---

## Plugin-first architecture

```text
Agent Code Starter
├── .agents/plugins/    installable marketplace
├── .codex-plugin/      Codex manifest
├── .claude-plugin/     Claude Code manifest
├── skills/             canonical agent behavior
├── runtime/            deterministic Git/GitHub/verification helpers
├── evals/              routing and behavioral scenarios
└── tests/              plugin and runtime regression tests

Your application repo
├── AGENTS.md            project-specific truth
├── .agent-code.json     optional overrides
├── src/
└── tests/
```

The separation is intentional:

**Plugin = engineering methodology.**  
**Repository = project truth.**

---

## Project overrides

Most repositories need no Agent Code Starter files at all.

When auto-detection is not enough, add a small `.agent-code.json`:

```json
{
  "trunk_branch": "main",
  "branch_prefix": "agent/",
  "review_mode": "auto",
  "commands": {
    "checks": ["npm run lint", "npm run typecheck"],
    "tests": ["npm test"]
  }
}
```

See [configuration](docs/configuration.md).

---

## Installation

### Codex Desktop — Chat **and** Work

Agent Code Starter is a Codex plugin. The same installed plugin is available in both **Chat** and **Work** modes; you do not need Work just to use the skills.

This repository is also its own Codex marketplace, so installation is two commands:

```bash
codex plugin marketplace add wjelliffe/agent-code-starter --ref main
codex plugin add agent-code-starter@agent-code-starter
```

Then start a new Codex chat/task so the installed skills are discovered.

You can also use the Codex plugin UI: add `wjelliffe/agent-code-starter` as a marketplace, then install **Agent Code Starter** from it.

No Agent Code Starter files need to be copied into your application repositories.

### Claude Code

The same repository includes `.claude-plugin/plugin.json` and uses the same canonical `skills/` content. Claude distribution remains separate from the Codex marketplace.

---

## Runtime guarantees

Runtime helpers execute from the **target repository working directory** even though they live inside the plugin.

Notable guarantees:

- implementation work is never finalized directly on trunk
- PR creation failure is a real failure
- checks/tests report `pass`, `fail`, or `none-found`
- finding no tests is never described as "tests passed"
- dirty in-place work is rejected rather than overwritten
- JS/TS, Python, Go, and Rust projects have lightweight auto-detection
- project commands can override auto-detection through `.agent-code.json`

---

## Migrating from v1

If you used the original copied-script version, install and validate the plugin first. Then remove the old shared infrastructure from target repositories.

See [migration](docs/migration.md).

---

## Development

Run the framework regression suite with:

```bash
python3 -m unittest discover -s tests -v
```

CI validates plugin structure, shell syntax, routing scenarios, runtime behavior, verification semantics, branch safety, and core skill contracts.

---

## Philosophy

**Move quick when you can; go deep when you need.**

Agent Code Starter is not trying to make every coding task look important.

It is trying to match the depth of the engineering process to the risk and complexity of the change in front of you.
