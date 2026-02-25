---
name: dbt
description: Analytics engineering with dbt (Core/Cloud/Fusion): build/modify models, debug dbt errors, run dbt CLI safely with selectors, use dbt show for data discovery, and fetch dbt docs (llms.txt + .md pages).
user-invocable: false
metadata:
  author: dbt-labs
  merged_from:
    - using-dbt-for-analytics-engineering
    - running-dbt-commands
    - fetching-dbt-docs
---

# dbt Expert

Use dbt to apply software engineering discipline (modularity, DRY, testing, documentation) to data transformations.

## When to Use

- Building or modifying dbt models, sources, tests, docs, packages, or project structure
- Debugging dbt parse/compile/runtime/test failures
- Running dbt commands (especially picking selectors/flags safely)
- Exploring unfamiliar warehouse data to inform modeling decisions (`dbt show`)
- Fetching/quoting authoritative dbt documentation

## Hard Rules (cost + safety)

- **Always scope execution**: prefer `--select` and avoid running an entire project without explicit user approval.
- **Prefer `dbt build`** over `dbt run` / `dbt test` for validating changes.
- **Use `dbt show` iteratively** for discovery and validation; always use `--limit` and push limits early in CTEs.
- **Use `dbt show` iteratively** with `--limit` for discovery and validation before running full builds.

## Reference Guides (read the relevant one)

| Guide | Use when |
|------|----------|
| [references/cli.md](references/cli.md) | Running dbt commands, selectors, `build` vs `run`, `show`, and output hygiene |
| [references/fetching-docs.md](references/fetching-docs.md) | Fetching dbt docs via `.md` URLs, searching `llms.txt`, and using the docs search script |
| [references/planning-dbt-models.md](references/planning-dbt-models.md) | Planning multi-step transformations by working backwards from desired outputs |
| [references/discovering-data.md](references/discovering-data.md) | Onboarding to unfamiliar sources; EDA and documenting discovery using `dbt show` |
| [references/writing-data-tests.md](references/writing-data-tests.md) | Adding high-signal tests without wasting warehouse credits |
| [references/debugging-dbt-errors.md](references/debugging-dbt-errors.md) | Classifying and fixing parse/compile/runtime/test errors |
| [scripts/review_run_results.md](scripts/review_run_results.md) | Reading `target/run_results.json` to identify failures quickly |
| [references/evaluating-impact-of-a-dbt-model-change.md](references/evaluating-impact-of-a-dbt-model-change.md) | Assessing downstream impact before changing an existing model |
| [references/writing-documentation.md](references/writing-documentation.md) | Writing “why”-focused docs at table/column level |
| [references/managing-packages.md](references/managing-packages.md) | Checking/installing packages and version boundaries |

## Common Failure Modes (catch yourself early)

- Writing SQL without verifying columns/values with `dbt show`
- Creating a new model when a surgical change to an existing model would suffice (same grain, same responsibility)
- Removing or weakening tests to “make it pass” without explicit permission
