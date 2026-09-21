# Evals

These deterministic scenarios protect the most important routing property of Agent Code Starter: ordinary work should stay cheap while clearly risky work should step up to the strict path.

`tests/test_plugin.py` runs every scenario through `runtime/route.py`.

These are not a substitute for live model-behavior evals. When the plugin is published/distributed, add harness-level evals for:

- fast-path requests not expanding into unnecessary planning
- high-risk requests escalating before edits
- `none-found` tests never being reported as "tests pass"
- review using current trunk and issue context
- failed PR creation not being reported as success
- debugging tracing root cause before speculative fixes
