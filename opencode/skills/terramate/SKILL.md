---
name: terramate
description: IaC orchestration with Terramate CLI for Terraform at scale. Use when user mentions "terramate", "tm run", "stacks", "change detection", asks about orchestrating Terraform across multiple stacks, generating HCL code, detecting changed infrastructure, or setting up GitOps workflows for IaC.
metadata:
  source: https://github.com/terramate-io/terramate
  version: 0.15.x
---

# Terramate Skill

Terramate is an open-source IaC orchestration and code generation engine for Terraform.

This skill is a **router + operating rules** for Terramate work. Deep-dive content lives under `references/`.

## When to Use

- Breaking monolithic Terraform into smaller stacks
- Running commands across multiple stacks with change detection
- Generating DRY HCL/JSON/YAML configurations
- Setting up GitOps workflows with pull request automation
- Managing multi-environment IaC deployments

**Related skill:** If the task is primarily about Terraform module design, testing strategy, state hygiene, CI checks, or refactoring `.tf` code (not orchestration), load `terraform`.

## Safety Gates (STOP and get explicit approval)

Terramate wraps `terraform apply/destroy` — the same risks apply at scale.

Never "just do it" for:
- `terramate run -- terraform apply` or `destroy` without `--changed` (runs against ALL stacks)
- `--parallel` with `apply` (concurrent state mutations; confirm the user understands the blast radius)
- `-auto-approve` in any `terramate run` command targeting production stacks
- Removing or reconfiguring stacks that have active state

When any of these is involved, confirm scope and environment before proceeding.

## Core Concepts

### Stacks

A **stack** is a directory containing IaC code that can be orchestrated independently.

```hcl
# stack.tm.hcl
stack {
  name        = "networking"
  description = "VPC network and subnet resources"
  tags        = ["infra", "networking"]
}
```

### Change Detection

Terramate detects which stacks have changed using Git:

```bash
terramate list --changed
terramate run --changed -- terraform plan
```

### Code Generation

Generate DRY configurations using globals and HCL templates:

```hcl
# globals.tm.hcl
globals {
  project     = "myproject"
  environment = "prod"
  region      = "europe-west2"
}

# generate.tm.hcl (generates backend.tf)
generate_hcl "backend.tf" {
  content {
    terraform {
      backend "gcs" {
        bucket = "tfstate-${global.project}"
        prefix = terramate.stack.path.relative
      }
    }
  }
}
```

## Quick Commands

```bash
terramate create --all-terraform     # Auto-detect and create stacks
terramate list                       # List all stacks
terramate list --changed             # List changed stacks
terramate run -- terraform init      # Run in all stacks
terramate run --changed -- terraform plan  # Run only changed
terramate generate                   # Generate code from templates
terramate fmt --check                # Check formatting
```

## Progressive Disclosure (open the right guide)

| Topic | Read this |
|------|-----------|
| Creating, configuring, or organizing stacks | [Stacks](references/stacks.md) |
| Running commands, parallelism, filtering, ordering | [Orchestration](references/orchestration.md) |
| Generating HCL, JSON, YAML; globals and metadata | [Code Generation](references/code-generation.md) |
| Change detection, triggers, and Git integration | [Change Detection](references/change-detection.md) |
| GitHub Actions, GitLab CI, BitBucket Pipelines | [CI/CD](references/ci-cd.md) |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running `terraform` directly instead of `terramate run` | Use `terramate run -- terraform ...` to respect stack ordering |
| Forgetting `--changed` flag | Always use `--changed` in CI to avoid unnecessary runs |
| Not running `terramate generate` after globals change | Run `terramate generate` and commit generated files |
| Hardcoding values that should be globals | Move to `globals.tm.hcl` and reference via `global.*` |
| Using `--parallel` with `apply` without understanding blast radius | Confirm scope; prefer sequential for production |

## References

- Terramate docs: https://terramate.io/docs/cli
- Installation: https://terramate.io/docs/cli/installation
- Playground: https://play.terramate.io
