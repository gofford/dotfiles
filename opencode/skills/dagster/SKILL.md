---
name: dagster
description: Expert guidance for Dagster project structure, assets, automation, and dg CLI workflows. Use when user mentions "Dagster assets", "dg scaffold", "schedules", "sensors", "partitions", "automation conditions", "materializations", or asks to "create a Dagster job", "debug run failures", or navigate Dagster definitions.
metadata:
  source: https://github.com/dagster-io/skills
  adapted_for: opencode
---

# Dagster Expert

Use this skill for requests involving Dagster concepts, project definitions, assets, schedules, sensors, and automation behavior.

## Use This Skill When

- The task mentions Dagster assets, jobs, schedules, sensors, partitions, materializations, or automation conditions.
- You need to locate definitions in the Dagster codebase and understand how orchestration is composed.
- You need `dg` CLI guidance for scaffolding, listing, checking, or launching definitions.

## Core Workflow

1. Identify whether the task is definition discovery, new implementation, validation, or runtime debugging.
2. For new definitions, scaffold first with `dg scaffold` rather than creating files manually.
3. Validate with `dg check defs` before proposing execution changes.
4. Use targeted asset selection with `dg launch --assets` when testing specific graph slices.

## Quick Commands

```bash
dg scaffold defs dagster.asset assets/my_asset.py
dg scaffold defs dagster.schedule schedules/daily.py
dg scaffold defs dagster.sensor sensors/my_sensor.py
dg list defs
dg check defs
dg launch --assets "group:analytics"
```

## Reference Guides

This skill includes detailed reference guides. Read the relevant guide when needed:

| Guide | Use When |
|-------|----------|
| [references/assets.md](references/assets.md) | Building or modifying asset definitions |
| [references/asset-key-design.md](references/asset-key-design.md) | Designing asset key naming conventions and hierarchies |
| [references/project-structure.md](references/project-structure.md) | Setting up or reorganizing a Dagster project layout |
| [references/implementation-workflow.md](references/implementation-workflow.md) | Following the end-to-end workflow for implementing new definitions |
| [references/resolvable-components.md](references/resolvable-components.md) | Working with resolvable/component-based patterns |
| [references/env-vars.md](references/env-vars.md) | Configuring environment variables for Dagster |
| [references/automation/README.md](references/automation/README.md) | Overview of automation options (schedules, sensors, declarative) |
| [references/automation/schedules.md](references/automation/schedules.md) | Creating or modifying cron-based schedules |
| [references/automation/sensors/README.md](references/automation/sensors/README.md) | Overview of sensor types and when to use each |
| [references/automation/sensors/basic-sensors.md](references/automation/sensors/basic-sensors.md) | Building basic event-driven sensors |
| [references/automation/sensors/asset-sensors.md](references/automation/sensors/asset-sensors.md) | Sensors that react to asset materializations |
| [references/automation/sensors/run-status-sensors.md](references/automation/sensors/run-status-sensors.md) | Sensors that react to run success/failure |
| [references/automation/declarative-automation/README.md](references/automation/declarative-automation/README.md) | Overview of declarative automation |
| [references/automation/declarative-automation/core-concepts.md](references/automation/declarative-automation/core-concepts.md) | Core concepts of declarative automation conditions |
| [references/automation/declarative-automation/operators.md](references/automation/declarative-automation/operators.md) | Automation condition operators (and, or, not, since) |
| [references/automation/declarative-automation/operands.md](references/automation/declarative-automation/operands.md) | Automation condition operands (missing, updated, etc.) |
| [references/automation/declarative-automation/customization.md](references/automation/declarative-automation/customization.md) | Custom automation conditions |
| [references/automation/declarative-automation/advanced.md](references/automation/declarative-automation/advanced.md) | Advanced declarative automation patterns |
| [references/cli/scaffold.md](references/cli/scaffold.md) | Scaffolding new definitions with `dg scaffold` |
| [references/cli/list.md](references/cli/list.md) | Listing definitions with `dg list` |
| [references/cli/check.md](references/cli/check.md) | Validating definitions with `dg check` |
| [references/cli/launch.md](references/cli/launch.md) | Launching runs with `dg launch` |
| [references/cli/asset-selection.md](references/cli/asset-selection.md) | Asset selection syntax for CLI commands |
| [references/cli/api.md](references/cli/api.md) | dg CLI API reference |

## Integration Routing

If the task is primarily about `dagster-*` integrations (for example dbt, Fivetran, Airbyte, or storage adapters), load `dagster-integrations`.

## References

- Dagster docs: https://docs.dagster.io/
- dg CLI docs: https://docs.dagster.io/guides/build/projects/dg
