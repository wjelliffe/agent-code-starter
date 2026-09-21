# Agent Code Starter

Agent Code Starter is an adaptive software-delivery plugin for coding agents.

It deliberately has two speeds:

- **`implement`** is the default: inspect the existing code, make the smallest correct change, run targeted verification, and keep moving.
- **`sdlc-do`** is the strict path: plan, isolate, test deliberately, verify fully, perform a skeptical review, then finalize.

The point is not maximum ceremony. The point is the **minimum process that reliably produces correct software**, with rigor increasing as risk increases.

## Why v2

The original starter copied skills, Claude commands, and shell scripts into every application repository. That worked, but it created drift and made upgrades a propagation problem.

v2 is plugin-first:

```text
Agent Code Starter plugin
├── skills/       canonical agent behavior
├── runtime/      deterministic helpers
└── manifests     Codex + Claude packaging

Your application repo
├── AGENTS.md / project docs
├── .agent-code.json   optional overrides
├── src/
└── tests/
```

No `agentic-scripts/`, `codex-skills/`, or shared `.claude/commands/` need to be copied into target repositories.

## Skills

- **`issues`** — turn product/engineering input into actionable GitHub issues.
- **`implement`** — default low-overhead implementation workflow.
- **`sdlc-do`** — rigorous workflow for risky, cross-cutting, or ambiguous changes.
- **`code-review`** — skeptical review against the issue, current trunk, architecture, tests, security, and CI.
- **`systematic-debugging`** — reproduce, trace, isolate root cause, then fix.
- **`verify`** — require fresh evidence before claiming work is done.
- **`address-review`** — evaluate PR feedback technically, fix valid findings, and verify the fixes.

## Adaptive routing

`implement` remains the normal entry point. It escalates to `sdlc-do` when the work involves material risk such as:

- authentication or authorization
- secrets, tokens, encryption, or security controls
- schema migrations, backfills, or data integrity
- transactions, concurrency, or race-sensitive state
- billing or payments
- production infrastructure or deployment mechanics
- multiple coupled subsystems
- an unclear implementation approach
- an explicit request for strict TDD / full SDLC

The bundled `runtime/route.py` provides a deterministic advisory signal; the agent still applies engineering judgment.

## Project overrides

Most repositories need no Agent Code Starter files at all. When auto-detection is not enough, add a small `.agent-code.json`:

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

## Installation

### Codex

This repository is a Codex plugin root and contains the required `.codex-plugin/plugin.json`.

For local development before marketplace publication, place the checkout at `~/plugins/agent-code-starter` and register it in your personal `~/.agents/plugins/marketplace.json` as a local plugin source. Codex's plugin marketplace format resolves `./plugins/agent-code-starter` from that personal marketplace to `~/plugins/agent-code-starter`.

Once published to a marketplace, installation becomes the normal Plugins UI flow; target repositories require no bootstrap step.

### Claude Code

The same repository also includes `.claude-plugin/plugin.json` and uses the same canonical `skills/` content. Distribution/marketplace registration is separate from the skill implementation.

## Runtime

Runtime helpers execute **from the target repository working directory** even though the scripts live inside the plugin. They emit machine-readable JSON where practical.

Notable guarantees:

- implementation work is never finalized directly on trunk
- PR creation failure is a real failure, not an empty-success response
- checks/tests report `pass`, `fail`, or `none-found`; finding no tests is never described as "tests passed"
- JS, Python, Go, and Rust projects have lightweight auto-detection
- custom project commands override auto-detection through `.agent-code.json`

## Migration from v1

Install and validate the plugin first. Then remove copied shared infrastructure from target repositories. See [migration](docs/migration.md).

## Development

Run:

```bash
python3 -m unittest discover -s tests -v
```

CI also validates shell syntax, manifests, routing scenarios, runtime behavior, and core skill contracts.
