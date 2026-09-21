# Migrating to the bundled-runtime architecture

Agent Code Starter now ships deterministic scripts inside the plugin itself. Target repositories should no longer carry shared ACS framework copies.

## Recommended order

1. Install/update the plugin.
2. Validate `issues`, `plan`, `implement`, `code-review`, and `sdlc-do` in one real repository.
3. Remove duplicated framework infrastructure from application repositories:
   - `agentic-scripts/`
   - `codex-skills/`
   - Agent Code Starter-owned `.claude/commands/`
   - generic copied framework instruction files
4. Keep project-specific architecture, domain invariants, deployment rules, and security constraints.
5. If the old project used `.agent-code.json`, translate only needed overrides into `.agent-code`.
6. Remove Python installed solely for ACS runtime support; ACS itself no longer needs it.

## Configuration translation

Old:

```json
{
  "trunk_branch": "main",
  "commands": {
    "checks": ["npm run lint"],
    "tests": ["npm test"]
  }
}
```

New:

```text
trunk_branch=main
check=npm run lint
test=npm test
```

The plugin is the distribution mechanism. The target repository is the source of project truth.
