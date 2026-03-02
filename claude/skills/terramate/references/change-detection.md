# Change Detection Reference

## Table of Contents
- [How It Works](#how-it-works)
- [Git Integration](#git-integration)
- [Module Detection](#module-detection)
- [Watch Patterns](#watch-patterns)
- [Triggers](#triggers)
- [CI/CD Usage](#cicd-usage)

## How It Works

Terramate detects changes by comparing Git state between branches or commits. A stack is "changed" if:

1. Any file in the stack directory changed
2. Any watched file/pattern changed
3. Any referenced Terraform module changed
4. A trigger file indicates forced change

## Git Integration

### Default Behavior

```bash
# Compare to default branch (main/master)
terramate list --changed
```

Terramate automatically detects default branch from Git remote.

### Custom Base Reference

```bash
# Compare to specific branch
terramate list --changed --git-change-base origin/develop

# Compare to specific commit
terramate list --changed --git-change-base abc123

# Compare to tag
terramate list --changed --git-change-base v1.0.0
```

### Uncommitted Changes

```bash
# Include uncommitted changes
terramate list --changed --git-uncommitted

# Include untracked files
terramate list --changed --git-untracked
```

## Module Detection

Terramate automatically detects changes in referenced Terraform modules:

```hcl
# stacks/networking/main.tf
module "vpc" {
  source = "../../modules/vpc"  # Changes here trigger stack
}

module "subnets" {
  source = "../../modules/networking/subnets"
}
```

If `modules/vpc/main.tf` changes, the `networking` stack is marked as changed.

### Module Detection Config

```hcl
# terramate.tm.hcl
terramate {
  config {
    change_detection {
      terraform {
        enabled = "auto"  # or "off", "force"
      }
    }
  }
}
```

## Watch Patterns

Add custom watch patterns to detect changes outside the stack:

### Stack-Level Watch

```hcl
# stacks/app/stack.tm.hcl
stack {
  name = "app"
  
  watch = [
    # Watch shared modules
    "/modules/common/**/*.tf",
    
    # Watch policy files
    "/policies/*.json",
    
    # Watch specific file
    "/config/app.yaml"
  ]
}
```

### Project-Level Watch

```hcl
# terramate.tm.hcl
terramate {
  config {
    change_detection {
      git {
        # Glob patterns to always consider
        watch = [
          "/shared/**/*.tf"
        ]
      }
    }
  }
}
```

## Triggers

Force stacks to be marked as changed without actual file changes:

### Trigger Files

Create trigger files in `.tmtriggers/` directory:

```bash
# Trigger specific stack
echo "stacks/networking" >> .tmtriggers/force-deploy

# Trigger all stacks matching pattern
echo "stacks/prod/*" >> .tmtriggers/force-deploy
```

Commit the trigger file to mark stacks as changed.

### Stack-Level Triggers

```hcl
# stacks/app/stack.tm.hcl
stack {
  name = "app"
  
  # Always mark changed if these stacks changed
  wants = [
    "/stacks/networking",
    "/stacks/database"
  ]
}
```

### Project-Level Triggers

```hcl
# terramate.tm.hcl
terramate {
  config {
    change_detection {
      git {
        # Files that trigger ALL stacks
        watch_all = [
          "terramate.tm.hcl",
          ".github/workflows/*.yml"
        ]
      }
    }
  }
}
```

## CI/CD Usage

### Pull Request Workflow

```yaml
# .github/workflows/pr.yml
- name: List changed stacks
  run: terramate list --changed
  
- name: Plan changed stacks
  run: terramate run --changed -- terraform plan
```

### Merge to Main Workflow

```yaml
# .github/workflows/deploy.yml
- name: Detect changes
  run: |
    # Compare current commit to previous
    terramate list --changed --git-change-base HEAD~1
    
- name: Deploy changes
  run: terramate run --changed -- terraform apply -auto-approve
```

### Force Full Deploy

```bash
# Deploy all stacks regardless of changes
terramate run -- terraform apply

# Or use trigger files
echo "*" > .tmtriggers/full-deploy
git add .tmtriggers/full-deploy
git commit -m "Force full deployment"
```

## Debugging Change Detection

### Verbose Output

```bash
# See why stacks are marked changed
terramate list --changed --verbose

# Show change detection details
terramate debug show change-detection
```

### Verify Expected Changes

```bash
# List changed files per stack
terramate list --changed --why
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Stack not detected as changed | Check watch patterns, module paths |
| Too many stacks changed | Review `watch_all` patterns, trigger files |
| Module changes not detected | Verify relative path in `source` attribute |
| CI detecting unexpected changes | Check `git-change-base` is correct branch |
