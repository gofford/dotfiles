---
description: Generate or update documentation for a scope
agent: architect
subtask: true
---

Generate or update documentation for the following scope:

$ARGUMENTS

Protocol:
1. Load relevant skills for the domain and find their documentation guidance.
2. Identify existing documentation (README, docstrings, YAML descriptions, schema docs)
   within the scope.
3. Identify gaps: undocumented modules, stale descriptions, missing examples.
4. Generate or update documentation. Match the existing style and conventions.
5. For dbt: use `dbt ls --output json` or read `target/manifest.json` for column
   descriptions and lineage context. Use the dbt skill's documentation methodology
   if available.

Rules:
- Prefer updating existing docs over creating new files.
- Do not restructure code. Documentation changes only.
- If the scope is ambiguous, ask the user to narrow it before proceeding.
