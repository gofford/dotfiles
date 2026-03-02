# Orchestration Reference

## Table of Contents
- [Basic Commands](#basic-commands)
- [Filtering Stacks](#filtering-stacks)
- [Parallel Execution](#parallel-execution)
- [Execution Order](#execution-order)
- [Scripts](#scripts)
- [Environment Variables](#environment-variables)

## Basic Commands

### terramate run

Execute commands in stacks:

```bash
# Run in all stacks
terramate run -- terraform init

# Run only in changed stacks
terramate run --changed -- terraform plan

# Dry run (show what would execute)
terramate run --dry-run -- terraform apply
```

### Command Chaining

Chain multiple Terraform commands:

```bash
# Initialize and plan
terramate run --changed -- terraform init -upgrade
terramate run --changed -- terraform plan -out=plan.tfplan

# Apply with saved plan
terramate run --changed -- terraform apply plan.tfplan
```

## Filtering Stacks

### By Change Status

```bash
# Only changed stacks (compared to default branch)
terramate run --changed -- terraform plan

# Changed compared to specific branch
terramate run --changed --git-change-base origin/main -- terraform plan

# Changed within specific directory
terramate run --changed stacks/prod/ -- terraform apply
```

### By Tags

```bash
# Single tag filter
terramate run --tags env:prod -- terraform apply

# Multiple tags (AND logic)
terramate run --tags env:prod --tags region:europe-west2 -- terraform apply

# Exclude tags
terramate run --no-tags deprecated -- terraform plan
```

### By Path

```bash
# Run in specific stack
terramate run stacks/networking -- terraform init

# Run in stacks under a path
terramate run stacks/prod/ -- terraform apply

# Exclude paths
terramate run --exclude stacks/deprecated -- terraform plan
```

## Parallel Execution

### Basic Parallelism

```bash
# Run with 4 parallel workers
terramate run --parallel 4 -- terraform apply -auto-approve

# Maximum parallelism (no limit)
terramate run --parallel 0 -- terraform init
```

### Dependency-Aware Parallelism

Terramate respects stack dependencies during parallel execution:

```
[networking] ────┐
                 ├──> [application]
[database] ──────┘
```

With `--parallel 4`, networking and database run in parallel, then application runs after both complete.

## Execution Order

### Normal Order (Dependencies First)

```bash
# Default: dependencies run first
terramate run -- terraform apply
```

Order: networking → database → application

### Reverse Order (Dependents First)

```bash
# Reverse: dependents run first (for destroy)
terramate run --reverse -- terraform destroy
```

Order: application → database → networking

### Continue on Error

```bash
# Continue running other stacks if one fails
terramate run --continue-on-error -- terraform apply
```

## Scripts

Define reusable command sequences:

```hcl
# scripts.tm.hcl
script "deploy" {
  name        = "Deploy stack"
  description = "Initialize and apply Terraform"
  
  job {
    name = "init"
    commands = [
      ["terraform", "init", "-upgrade"],
    ]
  }
  
  job {
    name = "apply"
    commands = [
      ["terraform", "apply", "-auto-approve"],
    ]
  }
}

script "plan" {
  name = "Plan changes"
  
  job {
    commands = [
      ["terraform", "init"],
      ["terraform", "plan", "-out=plan.tfplan"],
    ]
  }
}
```

Run scripts:

```bash
# Run script in all stacks
terramate script run deploy

# Run script in changed stacks
terramate script run --changed plan
```

### Conditional Scripts

```hcl
script "deploy" {
  job {
    name = "init"
    commands = [
      ["terraform", "init"],
    ]
  }
  
  job {
    name = "apply"
    # Only run on prod stacks
    condition = tm_contains(terramate.stack.tags, "env:prod")
    commands = [
      ["terraform", "apply", "-auto-approve"],
    ]
  }
}
```

## Environment Variables

### Setting Environment Variables

```hcl
# terramate.tm.hcl
terramate {
  config {
    run {
      env {
        TF_IN_AUTOMATION = "true"
        GOOGLE_REGION    = global.region
      }
    }
  }
}
```

### Stack-Specific Environment

```hcl
# stacks/prod/terramate.tm.hcl
terramate {
  config {
    run {
      env {
        TF_VAR_environment = "production"
      }
    }
  }
}
```

### Using Globals in Environment

```hcl
globals {
  gcp_region  = "europe-west2"
  environment = "prod"
}

terramate {
  config {
    run {
      env {
        GOOGLE_REGION    = global.gcp_region
        TF_VAR_env       = global.environment
        TF_VAR_stack     = terramate.stack.name
      }
    }
  }
}
```

## Cloud Sync

Sync execution results to Terramate Cloud:

```bash
# Sync deployment status
terramate run --sync-deployment -- terraform apply

# Sync preview (plan) results
terramate run --sync-preview -- terraform plan

# Sync drift detection
terramate run --sync-drift-status -- terraform plan -detailed-exitcode
```
