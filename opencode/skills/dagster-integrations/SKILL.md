---
name: dagster-integrations
description: Guidance for Dagster integration libraries (dagster-dbt, dagster-fivetran, dagster-airbyte, dagster-snowflake, dagster-k8s). Use when user mentions "dagster-*" packages, asks about dbt assets in Dagster, connecting warehouses, ETL integrations, or setting up external system connectors.
metadata:
  source: https://github.com/dagster-io/skills
  adapted_for: opencode
---

# Dagster Integrations

Use this skill for requests involving third-party systems connected through `dagster-*` libraries.

## Use This Skill When

- A task mentions a specific integration package such as `dagster-dbt`, `dagster-fivetran`, `dagster-airbyte`, `dagster-snowflake`, or similar.
- You need to evaluate which integration to use for ETL, storage, compute, BI, alerting, or observability.
- You need first-time setup steps before adding a component to a project.

## Integration Workflow

1. Identify the target technology and expected data flow.
2. Confirm the matching `dagster-*` package exists and is installed.
3. Scaffold or configure integration components using package-specific patterns.
4. Validate definitions and perform a targeted run.

## Common Setup

```bash
uv add dagster-dbt
uv add dagster-fivetran
dg check defs
```

## Reference Guides

This skill includes detailed reference guides by integration category. Read the relevant guide when needed:

| Guide | Use When |
|-------|----------|
| [references/dagster-dbt/README.md](references/dagster-dbt/README.md) | Overview of dagster-dbt integration options |
| [references/dagster-dbt/pythonic-integration.md](references/dagster-dbt/pythonic-integration.md) | Setting up dagster-dbt with the Pythonic API |
| [references/dagster-dbt/component-based-integration.md](references/dagster-dbt/component-based-integration.md) | Using the component-based dbt integration pattern |
| [references/dagster-dbt/dependencies.md](references/dagster-dbt/dependencies.md) | Managing cross-system dependencies between dbt and Dagster |
| [references/dagster-dbt/asset-checks.md](references/dagster-dbt/asset-checks.md) | Configuring asset checks for dbt models |
| [references/etl.md](references/etl.md) | ETL and ingestion integrations (Fivetran, Airbyte, etc.) |
| [references/storage.md](references/storage.md) | Storage and warehouse integrations (S3, GCS, Snowflake, etc.) |
| [references/compute.md](references/compute.md) | Compute integrations (Spark, K8s, etc.) |
| [references/bi.md](references/bi.md) | BI and analytics integrations |
| [references/alerting.md](references/alerting.md) | Alerting and notification integrations |
| [references/monitoring.md](references/monitoring.md) | Monitoring and observability integrations |
| [references/testing.md](references/testing.md) | Testing and data quality integrations |
| [references/ai.md](references/ai.md) | AI and ML integrations |
| [references/other.md](references/other.md) | Other / uncategorized integrations |

## References

- Dagster integrations index: https://docs.dagster.io/integrations
- Dagster dbt integration: https://docs.dagster.io/integrations/libraries/dbt
