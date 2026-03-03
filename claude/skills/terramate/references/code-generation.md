# Code Generation Reference

## Table of Contents
- [Globals](#globals)
- [Generate HCL](#generate-hcl)
- [Generate File](#generate-file)
- [Metadata](#metadata)
- [Functions](#functions)
- [Inheritance](#inheritance)

## Globals

Define reusable values accessible across stacks:

```hcl
# globals.tm.hcl (root level)
globals {
  project     = "myproject"
  environment = "prod"
  region      = "europe-west2"
  
  labels = {
    project     = global.project
    environment = global.environment
    managed_by  = "terraform"
  }
}
```

### Nested Globals

```hcl
globals {
  gcp = {
    region     = "europe-west2"
    project_id = "my-gcp-project"
  }
  
  kubernetes = {
    cluster_name = "prod-cluster"
    namespace    = "default"
  }
}
```

Access: `global.gcp.region`, `global.kubernetes.cluster_name`

### Conditional Globals

```hcl
globals {
  environment = "prod"
  
  # Conditional based on other globals
  machine_type = tm_ternary(
    global.environment == "prod",
    "e2-standard-4",
    "e2-medium"
  )
}
```

## Generate HCL

Generate Terraform/HCL files:

### Backend Configuration

```hcl
# generate.tm.hcl
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

### Provider Configuration

```hcl
generate_hcl "provider.tf" {
  content {
    provider "google" {
      project = global.gcp.project_id
      region  = global.gcp.region
    }
  }
}
```

### Terraform Required Version

```hcl
generate_hcl "versions.tf" {
  content {
    terraform {
      required_version = ">= 1.5.0"
      
      required_providers {
        google = {
          source  = "hashicorp/google"
          version = "~> 6.0"
        }
      }
    }
  }
}
```

### Conditional Generation

```hcl
generate_hcl "monitoring.tf" {
  # Only generate in prod stacks
  condition = tm_contains(terramate.stack.tags, "env:prod")
  
  content {
    module "monitoring" {
      source = "../../modules/monitoring"
      
      environment = global.environment
    }
  }
}
```

## Generate File

Generate non-HCL files (JSON, YAML, etc.):

### JSON Files

```hcl
generate_file "config.json" {
  content = tm_jsonencode({
    project     = global.project
    environment = global.environment
    stack       = terramate.stack.name
  })
}
```

### YAML Files

```hcl
generate_file "values.yaml" {
  content = tm_yamlencode({
    replicaCount = tm_ternary(global.environment == "prod", 3, 1)
    image = {
      repository = "myapp"
      tag        = global.app_version
    }
  })
}
```

### Template Files

```hcl
generate_file "README.md" {
  content = <<-EOF
    # ${terramate.stack.name}
    
    Environment: ${global.environment}
    Region: ${global.region}
    
    ## Resources
    This stack manages ${terramate.stack.description}
  EOF
}
```

## Metadata

Access Terramate metadata in generation:

### Stack Metadata

```hcl
generate_hcl "locals.tf" {
  content {
    locals {
      # Stack information
      stack_name = terramate.stack.name
      stack_path = terramate.stack.path.relative
      stack_id   = terramate.stack.id
      
      # Path components
      stack_dir  = terramate.stack.path.basename
      
      # Stack tags as list
      stack_tags = terramate.stack.tags
    }
  }
}
```

### Root Metadata

```hcl
generate_hcl "paths.tf" {
  content {
    locals {
      # Absolute path to repo root
      root_path = terramate.root.path.absolute
      
      # Path from stack to root
      to_root = terramate.root.path.relative
    }
  }
}
```

## Functions

Terramate provides `tm_*` functions for generation:

### String Functions

```hcl
globals {
  name = "my-stack"
  
  # String manipulation
  upper_name = tm_upper(global.name)        # "MY-STACK"
  lower_name = tm_lower(global.name)        # "my-stack"
  title_name = tm_title(global.name)        # "My-Stack"
  
  # Replace
  safe_name = tm_replace(global.name, "-", "_")  # "my_stack"
}
```

### Collection Functions

```hcl
globals {
  environments = ["dev", "staging", "prod"]
  
  # Check membership
  is_prod = tm_contains(global.environments, "prod")  # true
  
  # Get length
  env_count = tm_length(global.environments)  # 3
  
  # Merge maps
  all_tags = tm_merge(global.default_tags, global.stack_tags)
}
```

### Conditional Functions

```hcl
globals {
  environment = "prod"
  
  # Ternary
  replicas = tm_ternary(global.environment == "prod", 3, 1)
  
  # Coalesce (first non-null)
  region = tm_coalesce(global.override_region, "europe-west2")
}
```

### Path Functions

```hcl
generate_hcl "module.tf" {
  content {
    module "vpc" {
      # Relative path from stack to modules
      source = "${terramate.root.path.relative}/modules/vpc"
    }
  }
}
```

## Inheritance

Globals inherit through directory hierarchy:

```
.
├── globals.tm.hcl          # project = "myproject"
└── stacks/
    ├── globals.tm.hcl      # region = "europe-west2"
    ├── prod/
    │   ├── globals.tm.hcl  # environment = "prod"
    │   └── stack.tm.hcl
    └── staging/
        ├── globals.tm.hcl  # environment = "staging"
        └── stack.tm.hcl
```

In `stacks/prod/`:
- `global.project` = "myproject" (from root)
- `global.region` = "europe-west2" (from stacks/)
- `global.environment` = "prod" (from stacks/prod/)

### Override Globals

Child directories override parent values:

```hcl
# root globals.tm.hcl
globals {
  machine_type = "e2-medium"  # Default
}

# stacks/prod/globals.tm.hcl
globals {
  machine_type = "e2-standard-4"  # Override for prod
}
```

## Running Generation

```bash
# Generate all files
terramate generate

# Check if generation is needed (CI)
terramate generate --check

# Format generated files
terramate fmt
```
