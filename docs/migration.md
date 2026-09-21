# Migrating from Agent Code Starter v1

Do not delete working v1 infrastructure before the plugin is installed and validated in at least one real repository.

## Recommended order

1. Install the v2 plugin.
2. Validate `issues`, `implement`, `sdlc-do`, `code-review`, and finalization in one real project.
3. Remove global duplicate Codex skills that the plugin now supplies.
4. In each application repository, diff local copies against the old starter so project-specific behavior is not lost.
5. Remove shared copies:
   - `agentic-scripts/`
   - `codex-skills/`
   - Agent Code Starter-owned `.claude/commands/`
   - generic `CODEX.md`, `CLAUDE.md`, or `GEMINI.md` files that only repeat framework rules
6. Keep or rewrite project-specific instructions: architecture, domain invariants, test/deploy commands, security rules, and operational constraints.
7. Add `.agent-code.json` only when the plugin cannot reliably infer a project setting.

The old bootstrap/propagation scripts are intentionally not part of v2. Plugin installation is the distribution mechanism.
