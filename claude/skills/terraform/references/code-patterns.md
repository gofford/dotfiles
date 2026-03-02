# Code Patterns & Structure

> **Part of:** [terraform](../SKILL.md)
> **Purpose:** Comprehensive patterns for Terraform code structure and modern features

This document provides detailed code patterns, structure guidelines, and modern Terraform features. For high-level principles, see the [main skill file](../SKILL.md).

---

## Table of Contents

1. [Block Ordering & Structure](#block-ordering--structure)
2. [Count vs For_Each Deep Dive](#count-vs-for_each-deep-dive)
3. [Modern Terraform Features (1.0+)](#modern-terraform-features-10)
4. [Version Management](#version-management)
5. [Refactoring Patterns](#refactoring-patterns)
6. [Locals for Dependency Management](#locals-for-dependency-management)

---

## Block Ordering & Structure

### Resource Block Structure

**Strict argument ordering:**

1. `count` or `for_each` FIRST (blank line after)
2. Other arguments (alphabetical or logical grouping)
3. `labels` as last real argument
4. `depends_on` after labels (if needed)
5. `lifecycle` at the very end (if needed)

```hcl
# ✅ GOOD - Correct ordering
resource "google_compute_instance" "this" {
  count = var.create_instance ? 1 : 0

  name         = "${var.name}-instance"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public[0].id
  }

  labels = {
    name        = "${var.name}-instance"
    environment = var.environment
  }

  depends_on = [google_compute_network.this]

  lifecycle {
    create_before_destroy = true
  }
}

# ❌ BAD - Wrong ordering
resource "google_compute_instance" "this" {
  name         = "instance"
  machine_type = var.machine_type

  labels = { name = "instance" }

  count = var.create_instance ? 1 : 0  # Should be first

  zone = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public[0].id
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_compute_network.this]  # Should be after labels
}
```

### Variable Definition Structure

**Variable block ordering:**

1. `description` (ALWAYS required)
2. `type`
3. `default`
4. `sensitive` (when setting to true)
5. `nullable` (when setting to false)
6. `validation`

```hcl
# ✅ GOOD - Correct ordering and structure
variable "environment" {
  description = "Environment name for resource labeling"
  type        = string
  default     = "dev"
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
```

### Variable Type Preferences

- Prefer **simple types** (`string`, `number`, `list()`, `map()`) over `object()` unless strict validation needed
- Use `optional()` for optional object attributes (Terraform 1.3+)
- Use `any` to disable validation at certain depths or support multiple types

**Modern variable patterns (Terraform 1.3+):**

```hcl
# ✅ GOOD - Using optional() for object attributes
variable "database_config" {
  description = "Cloud SQL configuration with optional parameters"
  type = object({
    name               = string
    database_version   = string
    tier               = string
    backup_retention   = optional(number, 7)      # Default: 7
    monitoring_enabled = optional(bool, true)      # Default: true
    labels             = optional(map(string), {}) # Default: {}
  })
}

# Usage - only required fields needed
database_config = {
  name             = "mydb"
  database_version = "MYSQL_8_0"
  tier             = "db-f1-micro"
  # Optional fields use defaults
}
```

**Complex type example:**

```hcl
# For lists/maps of same type
variable "subnetwork_configs" {
  description = "Map of subnetwork configurations"
  type        = map(map(string))  # All values are maps of strings
}

# When types vary, use any
variable "mixed_config" {
  description = "Configuration with varying types"
  type        = any
}
```

### Output Structure

**Pattern:** `{name}_{type}_{attribute}`

```hcl
# ✅ GOOD
output "firewall_id" {  # "this_" should be omitted
  description = "The ID of the firewall rule"
  value       = try(google_compute_firewall.this[0].id, "")
}

output "private_subnetwork_ids" {  # Plural for list
  description = "List of private subnetwork IDs"
  value       = [for k, v in google_compute_subnetwork.private : v.id]
}

# ❌ BAD
output "this_firewall_id" {  # Don't prefix with "this_"
  value = google_compute_firewall.this[0].id
}

output "subnetwork_id" {  # Should be plural "subnetwork_ids"
  value = [for k, v in google_compute_subnetwork.private : v.id]  # Returns list
}
```

---

## Count vs For_Each Deep Dive

### When to use count

✓ **Simple numeric replication:**
```hcl
resource "google_compute_subnetwork" "public" {
  count = 3

  name          = "public-${count.index}"
  network       = google_compute_network.this.id
  ip_cidr_range = cidrsubnet(var.network_cidr, 8, count.index)
  region        = var.region
}
```

✓ **Boolean conditions (create or don't):**
```hcl
# ✅ GOOD - Boolean condition
resource "google_compute_router_nat" "this" {
  count = var.create_nat ? 1 : 0

  name   = "${var.name}-nat"
  router = google_compute_router.this[0].name
  region = var.region
}

# Less preferred - length check
resource "google_compute_router_nat" "this" {
  count = length(var.subnetworks) > 0 ? 1 : 0

  name   = "${var.name}-nat"
  router = google_compute_router.this[0].name
  region = var.region
}
```

✓ **When order doesn't matter and items won't change**

### When to use for_each

✓ **Reference resources by key:**
```hcl
resource "google_compute_subnetwork" "private" {
  for_each = var.subnetworks

  name          = each.key
  network       = google_compute_network.this.id
  ip_cidr_range = each.value.cidr
  region        = each.value.region
}

# Reference by key: google_compute_subnetwork.private["subnet-a"]
```

✓ **Items may be added/removed from middle:**
```hcl
# ❌ BAD with count - removing middle item recreates all subsequent resources
resource "google_compute_subnetwork" "private" {
  count = length(var.subnetwork_names)

  name          = var.subnetwork_names[count.index]
  network       = google_compute_network.this.id
  ip_cidr_range = cidrsubnet(var.network_cidr, 4, count.index)
  region        = var.region
  # If var.subnetwork_names[1] removed, all resources after recreated!
}

# ✅ GOOD with for_each - removal only affects that one resource
resource "google_compute_subnetwork" "private" {
  for_each = toset(var.subnetwork_names)

  name          = each.key
  network       = google_compute_network.this.id
  ip_cidr_range = cidrsubnet(var.network_cidr, 4, index(var.subnetwork_names, each.key))
  region        = var.region
  # Removing one subnet name only destroys that subnetwork
}
```

✓ **Creating multiple named resources:**
```hcl
variable "environments" {
  default = {
    dev = {
      machine_type   = "e2-micro"
      instance_count = 1
    }
    prod = {
      machine_type   = "e2-standard-4"
      instance_count = 3
    }
  }
}

resource "google_compute_instance" "app" {
  for_each = var.environments

  name         = "app-${each.key}"
  machine_type = each.value.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.boot_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id
  }

  labels = {
    environment = each.key  # "dev" or "prod"
  }
}
```

### Count to For_Each Migration

**When to migrate:** When you need stable resource addressing or items might be added/removed from middle of list.

**Migration steps:**

1. Add `for_each` to resource
2. Use `moved` blocks to preserve existing resources
3. Remove `count` after verifying with `terraform plan`

**Complete example:**

```hcl
# Before (using count)
variable "subnetwork_names" {
  default = ["subnet-a", "subnet-b", "subnet-c"]
}

resource "google_compute_subnetwork" "private" {
  count = length(var.subnetwork_names)

  name          = var.subnetwork_names[count.index]
  network       = google_compute_network.this.id
  ip_cidr_range = cidrsubnet(var.network_cidr, 8, count.index)
  region        = var.region

  labels = {
    name = "private-${var.subnetwork_names[count.index]}"
  }
}

# Reference: google_compute_subnetwork.private[0].id

# After (using for_each)
resource "google_compute_subnetwork" "private" {
  for_each = toset(var.subnetwork_names)

  name          = each.key
  network       = google_compute_network.this.id
  ip_cidr_range = cidrsubnet(var.network_cidr, 8, index(var.subnetwork_names, each.key))
  region        = var.region

  labels = {
    name = "private-${each.key}"
  }
}

# Reference: google_compute_subnetwork.private["subnet-a"].id

# Migration blocks (prevents resource recreation)
moved {
  from = google_compute_subnetwork.private[0]
  to   = google_compute_subnetwork.private["subnet-a"]
}

moved {
  from = google_compute_subnetwork.private[1]
  to   = google_compute_subnetwork.private["subnet-b"]
}

moved {
  from = google_compute_subnetwork.private[2]
  to   = google_compute_subnetwork.private["subnet-c"]
}

# Verify migration:
# terraform plan should show "moved" operations, not destroy/create
```

**Benefits after migration:**
- Removing "subnet-b" only destroys that subnetwork (not subnet-c)
- Adding new subnetwork doesn't affect existing ones
- Resources have stable addresses by name

---

## Modern Terraform Features (1.0+)

### try() Function (Terraform 0.13+)

**Use try() instead of element(concat()):**

```hcl
# ✅ GOOD - Modern try() function
output "firewall_id" {
  description = "The ID of the firewall rule"
  value       = try(google_compute_firewall.this[0].id, "")
}

output "first_subnetwork_id" {
  description = "ID of first subnetwork with multiple fallbacks"
  value       = try(
    google_compute_subnetwork.public["primary"].id,
    google_compute_subnetwork.private["primary"].id,
    ""
  )
}

# ❌ BAD - Legacy pattern
output "firewall_id" {
  value = element(concat(google_compute_firewall.this.*.id, [""]), 0)
}
```

### nullable = false (Terraform 1.1+)

**Set nullable = false for non-null variables:**

```hcl
# ✅ GOOD (Terraform 1.1+)
variable "network_cidr" {
  description = "Primary CIDR range for the subnetwork"
  type        = string
  nullable    = false  # Passing null uses default, not null
  default     = "10.0.0.0/16"
}
```

### optional() with Defaults (Terraform 1.3+)

**Use optional() for object attributes:**

```hcl
# ✅ GOOD - Using optional() for object attributes
variable "database_config" {
  description = "Cloud SQL configuration with optional parameters"
  type = object({
    name               = string
    database_version   = string
    tier               = string
    backup_retention   = optional(number, 7)      # Default: 7
    monitoring_enabled = optional(bool, true)      # Default: true
    labels             = optional(map(string), {}) # Default: {}
  })
}

# Usage - only required fields needed
database_config = {
  name             = "mydb"
  database_version = "MYSQL_8_0"
  tier             = "db-f1-micro"
  # Optional fields use defaults
}
```

### Moved Blocks (Terraform 1.1+)

**Rename resources without destroy/recreate:**

```hcl
# Rename a resource
moved {
  from = google_compute_instance.web_server
  to   = google_compute_instance.web
}

# Rename a module
moved {
  from = module.old_module_name
  to   = module.new_module_name
}

# Move resource into for_each
moved {
  from = google_compute_subnetwork.private[0]
  to   = google_compute_subnetwork.private["subnet-a"]
}
```

### Provider-Defined Functions (Terraform 1.8+)

**Use provider-specific functions for data transformation:**

```hcl
# Google provider function example
data "google_project" "current" {}

locals {
  # Provider function (Terraform 1.8+)
  project_number = provider::google::region_from_zone(var.zone)
}

# Check provider documentation for available functions
# Check the Google provider changelog for available functions
```

### Cross-Variable Validation (Terraform 1.9+)

**Reference other variables in validation blocks:**

```hcl
variable "machine_type" {
  description = "Compute Engine machine type"
  type        = string
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number

  validation {
    # Can reference var.machine_type in Terraform 1.9+
    condition = !(
      var.machine_type == "e2-micro" &&
      var.disk_size_gb > 500
    )
    error_message = "Micro instances cannot have disk > 500 GB"
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "backup_retention" {
  description = "Backup retention period in days"
  type        = number

  validation {
    # Production requires longer retention
    condition = (
      var.environment == "prod" ? var.backup_retention >= 7 : true
    )
    error_message = "Production environment requires backup_retention >= 7 days"
  }
}
```

### Write-Only Arguments (Terraform 1.11+)

**Always use write-only arguments or external secret management:**

```hcl
# ✅ GOOD - External secret with write-only argument
data "google_secret_manager_secret_version" "db_password" {
  secret = "prod-database-password"
}

resource "google_sql_database_instance" "this" {
  name             = "main-instance"
  database_version = "MYSQL_8_0"

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_user" "admin" {
  instance = google_sql_database_instance.this.name
  name     = "admin"

  # write-only (Terraform 1.11+, requires provider support):
  # Check google provider changelog for write-only attribute availability.
  # If not yet supported, use `password` with external secret rotation instead.
  password_wo = data.google_secret_manager_secret_version.db_password.secret_data
}

# ❌ BAD - Secret ends up in state file
resource "random_password" "db" {
  length = 16
}

resource "google_sql_user" "admin" {
  instance = google_sql_database_instance.this.name
  name     = "admin"
  password = random_password.db.result  # Stored in state!
}

# ❌ BAD - Variable secret stored in state
resource "google_sql_user" "admin" {
  instance = google_sql_database_instance.this.name
  name     = "admin"
  password = var.db_password  # Ends up in state file
}
```

---

## Version Management

### Version Constraint Syntax

```hcl
# Exact version (avoid unless necessary - inflexible)
version = "5.0.0"

# Pessimistic constraint (recommended for stability)
# Allows patch updates only
version = "~> 5.0"      # Allows 5.0.x (any x), but not 5.1.0
version = "~> 5.0.1"    # Allows 5.0.x where x >= 1, but not 5.1.0

# Range constraints
version = ">= 5.0, < 6.0"     # Any 5.x version
version = ">= 5.0.0, < 5.1.0" # Specific minor version range

# Minimum version
version = ">= 5.0"  # Any version 5.0 or higher (risky - breaking changes)

# Latest (avoid in production - unpredictable)
# No version specified = always use latest available
```

### Versioning Strategy by Component

**Terraform itself:**
```hcl
# versions.tf
terraform {
  # Pin to minor version, allow patch updates
  required_version = "~> 1.9"  # Allows 1.9.x
}
```

**Providers:**
```hcl
# versions.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"  # Pin major version, allow minor/patch updates
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
```

**Modules:**
```hcl
# Production - pin exact version
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "9.3.0"  # Exact version for production stability
}

# Development - allow flexibility
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.3"  # Allow patch updates in dev
}
```

### Update Strategy

**Security patches:**
- Update immediately
- Test in dev → stage → prod
- Prioritize provider and Terraform core updates

**Minor versions:**
- Regular maintenance windows (monthly/quarterly)
- Review changelog for breaking changes
- Test thoroughly before production

**Major versions:**
- Planned upgrade cycles
- Dedicated testing period
- May require code changes
- Update in phases: dev → stage → prod

### Version Management Workflow

```hcl
# Step 1: Lock versions in versions.tf
terraform {
  required_version = "~> 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Step 2: Generate lock file (commit this)
terraform init
# Creates .terraform.lock.hcl with exact versions used

# Step 3: Update providers when needed
terraform init -upgrade
# Updates to latest within constraints

# Step 4: Review and test changes before committing
terraform plan
```

### Example versions.tf Template

```hcl
terraform {
  # Terraform version
  required_version = "~> 1.9"

  # Provider versions
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  # Backend configuration (optional here, often in backend.tf)
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "infrastructure/terraform.tfstate"
  }
}
```

---

## Refactoring Patterns

### Terraform Version Upgrades

#### 0.12/0.13 → 1.x Migration Checklist

**Replace legacy patterns with modern equivalents:**

- [ ] Replace `element(concat(...))` with `try()`
- [ ] Add `nullable = false` to variables that shouldn't accept null
- [ ] Use `optional()` in object types for optional attributes
- [ ] Add `validation` blocks to variables with constraints
- [ ] Migrate secrets to write-only arguments (Terraform 1.11+)
- [ ] Use `moved` blocks for resource refactoring (Terraform 1.1+)
- [ ] Consider cross-variable validation (Terraform 1.9+)

**Example migration:**

```hcl
# Before (0.12 style)
output "firewall_id" {
  value = element(concat(google_compute_firewall.this.*.id, [""]), 0)
}

variable "config" {
  type = object({
    name = string
    size = number
  })
}

# After (1.x style)
output "firewall_id" {
  description = "The ID of the firewall rule"
  value       = try(google_compute_firewall.this[0].id, "")
}

variable "config" {
  description = "Configuration settings"
  type = object({
    name = string
    size = optional(number, 100)  # Optional with default
  })
  nullable = false  # Don't accept null
}
```

### Secrets Remediation

**Pattern:** Move secrets out of Terraform state into external secret management.

#### Before - Secrets in State

```hcl
# ❌ BAD - Secret generated and stored in state
resource "random_password" "db" {
  length  = 16
  special = true
}

resource "google_sql_user" "admin" {
  instance = google_sql_database_instance.this.name
  name     = "admin"
  password = random_password.db.result  # In state!
}

# OR

# ❌ BAD - Secret passed via variable and stored in state
variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true  # Marked sensitive but still in state!
}

resource "google_sql_user" "admin" {
  instance = google_sql_database_instance.this.name
  name     = "admin"
  password = var.db_password  # In state!
}
```

#### After - External Secret Management

**Option 1: Write-only arguments (Terraform 1.11+)**

```hcl
# ✅ GOOD - Fetch from GCP Secret Manager
data "google_secret_manager_secret_version" "db_password" {
  secret = "prod-database-password"
}

resource "google_sql_user" "admin" {
  instance = google_sql_database_instance.this.name
  name     = "admin"

  # write-only: Sent to GCP, not stored in state
  password_wo = data.google_secret_manager_secret_version.db_password.secret_data
}
```

**Option 2: Separate secret creation (if Terraform 1.11+ not available)**

```hcl
# ✅ GOOD - Reference pre-existing secret
# Secret created outside Terraform (manually or separate process)

data "google_secret_manager_secret_version" "db_password" {
  secret = "prod-database-password"
}

# Note: Without write-only, you may need to handle secret rotation
# outside Terraform or accept that the secret value appears in state
# during initial creation but not after rotation
```

**Migration steps:**

1. Create secret in GCP Secret Manager (outside Terraform)
2. Update Terraform to use data sources
3. Use write-only argument (if Terraform 1.11+)
4. Remove `random_password` resource or variable
5. Run `terraform apply` to update
6. Verify secret not in state: `terraform show` should not display password

---

## Locals for Dependency Management

**Use locals to hint explicit resource deletion order:**

```hcl
# ✅ GOOD - Forces correct deletion order
# Ensures subnetworks deleted before service networking connection

locals {
  # References service networking connection first, falling back to network
  # This forces Terraform to delete subnetworks before the peering connection
  network_id = try(
    google_service_networking_connection.this[0].network,
    google_compute_network.this.id,
    ""
  )
}

resource "google_compute_network" "this" {
  name                    = "my-network"
  auto_create_subnetworks = false
}

resource "google_service_networking_connection" "this" {
  count = var.enable_private_services ? 1 : 0

  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip[0].name]
}

resource "google_compute_subnetwork" "main" {
  # Uses local instead of direct reference
  # Creates implicit dependency on service networking connection
  network       = local.network_id
  name          = "main-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
}

# Without local: Terraform might try to delete peering before subnetworks → ERROR
# With local: Subnetworks deleted first, then peering connection, then network ✓
```

**Why this matters:**
- Prevents deletion errors when destroying infrastructure
- Ensures correct dependency order without explicit `depends_on`
- Particularly useful for complex network configurations with private service access

**Common use cases:**
- Networks with private service connections
- Resources that depend on optional configurations
- Complex deletion order requirements

---

**Back to:** [Main Skill File](../SKILL.md)
