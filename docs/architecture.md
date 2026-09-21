# Architecture

Agent Code Starter separates agent judgment from deterministic mechanics.

## Skill layer

There are exactly four user-facing skills:

- `issues`
- `implement`
- `sdlc-do`
- `code-review`

`implement` and `sdlc-do` are explicit implementation choices. There is no automatic risk router and neither workflow reviews its own work.

Both execution skills use one primary agent, forbid sub-agent orchestration, stop on failures instead of retrying autonomously, and end with a merge-vs-PR finalization choice.

`code-review` is a separate one-shot, read-only adversarial workflow. For a PR, it posts one GitHub review with actionable inline findings where possible and never edits code.

Review remediation is not a fifth skill. A later explicit `implement` invocation loads the existing PR feedback, fixes valid findings on the same PR branch, validates once, pushes the update, and stops.

The intended cross-AI flow is:

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
  push existing PR
        ↓
      STOP
        ↓
optional explicit re-review by AI B
```

Every transition between agents is initiated by the user. ACS never creates an autonomous review loop.

## Runtime layer

`runtime/` contains deterministic operations:

- issue normalization and writing
- request/issue context preparation
- branch/worktree creation
- check/test execution
- diff summarization
- DOR/DoD validation
- final commit/merge/new-PR/update-existing-PR operations

Runtime scripts execute with the target repository as the working directory. They must never infer the target repository from the plugin installation path.

## Target repository layer

Project repositories own project truth: architecture, domain invariants, product requirements, tests, deployment conventions, security constraints, and optional `.agent-code.json` overrides.

The plugin must not copy shared framework files into target repositories.
