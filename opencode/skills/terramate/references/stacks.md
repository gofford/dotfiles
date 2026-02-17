# Stacks Reference

## Table of Contents
- [Stack Definition](#stack-definition)
- [Stack Configuration](#stack-configuration)
- [Stack Tags](#stack-tags)
- [Stack Dependencies](#stack-dependencies)
- [Stack IDs](#stack-ids)
- [Cloning Stacks](#cloning-stacks)

## Stack Definition

Create stacks with `terramate create`:

```bash
# Create a new stack
terramate create stacks/networking

# Create stack with description
terramate create stacks/compute --description "Compute resources"

# Create stacks for all existing Terraform directories
terramate create --all-terraform
```

Manual stack definition in `stack.tm.hcl`:

```hcl
stack {
  name        = "networking"
  description = "VPC and networking infrastructure"
  tags        = ["infra", "networking"]
}
```

## Stack Configuration

### Basic Configuration

```hcl
stack {
  name        = "my-stack"
  description = "Stack description"
  
  # Tags for filtering
  tags = ["env:prod", "team:platform"]
  
  # Explicit ordering (higher runs first)
  order = 100
}
```

### Stack Watch Patterns

Control which files trigger change detection:

```hcl
stack {
  name = "networking"
  
  watch = [
    # Watch additional files outside the stack
    "/modules/vpc/**/*.tf",
    "/shared/policies/*.json"
  ]
}
```

## Stack Tags

Tags enable filtering stacks during orchestration:

```hcl
# stacks/prod-europe-west2/stack.tm.hcl
stack {
  name = "prod-europe-west2"
  tags = [
    "env:prod",
    "region:europe-west2",
    "team:infrastructure"
  ]
}
```

Filter by tags:

```bash
# Run on stacks with specific tag
terramate run --tags env:prod -- terraform plan

# Multiple tag filters (AND logic)
terramate run --tags env:prod --tags region:europe-west2 -- terraform apply

# Exclude tags
terramate run --no-tags deprecated -- terraform apply

# List stacks with tags
terramate list --tags team:platform
```

## Stack Dependencies

### Explicit Dependencies

Define execution order with `after` and `before`:

```hcl
# stacks/compute/stack.tm.hcl
stack {
  name = "compute"
  
  # This stack runs after networking
  after = ["/stacks/networking"]
}
```

```hcl
# stacks/networking/stack.tm.hcl
stack {
  name = "networking"
  
  # This stack runs before compute
  before = ["/stacks/compute"]
}
```

### Order Attribute

Use numeric ordering for simple cases:

```hcl
# Lower order = runs first
stack {
  name  = "networking"
  order = 1  # Runs first
}

stack {
  name  = "compute"
  order = 2  # Runs second
}

stack {
  name  = "application"
  order = 3  # Runs third
}
```

### Visualize Dependencies

```bash
# Show dependency graph
terramate experimental run-graph
```

## Stack IDs

Each stack has a unique UUID for tracking:

```hcl
stack {
  name = "networking"
  id   = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

Auto-generate IDs:

```bash
# Generate IDs for all stacks without them
terramate create --ensure-stack-ids
```

## Cloning Stacks

Create new stacks from existing ones:

```bash
# Clone a stack
terramate experimental clone stacks/prod stacks/staging

# This copies:
# - stack.tm.hcl (with new ID)
# - All .tf files
# - Local .tm.hcl files
```

After cloning, update environment-specific values in globals or variables.

## Stack Metadata

Access stack metadata in code generation:

```hcl
generate_hcl "tags.tf" {
  content {
    locals {
      stack_name = terramate.stack.name
      stack_path = terramate.stack.path.relative
      stack_id   = terramate.stack.id
    }
  }
}
```

Available metadata:
- `terramate.stack.name` - Stack name
- `terramate.stack.description` - Stack description
- `terramate.stack.path.absolute` - Absolute path
- `terramate.stack.path.relative` - Relative path from root
- `terramate.stack.path.basename` - Directory name
- `terramate.stack.id` - Stack UUID
- `terramate.stack.tags` - List of tags
