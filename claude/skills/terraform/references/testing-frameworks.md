# Testing Frameworks - Detailed Guide

> **Part of:** [terraform](../SKILL.md)
> **Purpose:** Detailed guides for Terraform testing frameworks

This document provides in-depth guidance on testing frameworks for Infrastructure as Code. For the decision matrix and high-level overview, see the [main skill file](../SKILL.md#testing-strategy-framework).

---

## Table of Contents

1. [Static Analysis](#static-analysis)
2. [Plan Testing](#plan-testing)
3. [Native Terraform Tests](#native-terraform-tests)
4. [Terratest (Go-based)](#terratest-go-based)

---

## Static Analysis

**Always do this first.** Zero cost, catches 40%+ of issues before deployment.

### Pre-commit Hooks

```yaml
# In .pre-commit-config.yaml
- repo: https://github.com/antonbabenko/pre-commit-terraform
  hooks:
    - id: terraform_fmt
    - id: terraform_validate
    - id: terraform_tflint
```

### What Each Tool Checks

- **`terraform fmt`** - Code formatting consistency
- **`terraform validate`** - Syntax and internal consistency
- **`TFLint`** - Best practices, provider-specific rules
- **`trivy` / `checkov`** - Security vulnerabilities

### When to Use

Every commit, always. Zero cost, catches 40%+ of issues.

---

## Plan Testing

### What terraform plan Validates

- Verify expected resources will be created/modified/destroyed
- Catch provider authentication issues
- Validate variable combinations
- Review before applying

### In CI/CD

```bash
terraform init
terraform plan -out=tfplan

# Optionally: Convert plan to JSON and validate with tools
terraform show -json tfplan | jq '.'
```

### Limitations

- Doesn't deploy real infrastructure
- Can't catch runtime issues (IAM permissions, network connectivity)
- Won't find resource-specific bugs

---

## Native Terraform Tests

**Available:** Terraform 1.6+

### When to Use

- Team primarily works in HCL (no Go/Ruby experience needed)
- Testing logical operations and module behavior
- Want to avoid external testing dependencies

### Basic Structure

```hcl
# tests/gcs_bucket.tftest.hcl
run "create_bucket" {
  command = apply

  assert {
    condition     = google_storage_bucket.main.name != ""
    error_message = "GCS bucket name must be set"
  }
}

run "verify_versioning" {
  command = plan

  assert {
    condition     = google_storage_bucket.main.versioning[0].enabled == true
    error_message = "Bucket versioning must be enabled"
  }
}
```

### Critical: Validate Resource Schemas First

**Always use Terraform MCP to validate resource schemas before writing tests:**

```bash
# Example workflow in Claude Code:
# 1. Search for provider documentation
mcp__terraform__search_providers({
  provider_name: "google",
  provider_namespace: "hashicorp",
  service_slug: "google_storage_bucket",
  provider_document_type: "resources"
})

# 2. Get detailed schema
mcp__terraform__get_provider_details({
  provider_doc_id: "12345"  # from search results
})
```

**Why This Matters:**
- Some blocks are **sets** (unordered, no indexing with `[0]`)
- Some blocks are **lists** (ordered, indexable)
- Some attributes are **computed** (only known after apply)

**Common Schema Patterns:**

| GCP Resource | Block Type | Indexing |
|--------------|------------|----------|
| `lifecycle_rule` in `google_storage_bucket` | **set** | ❌ Cannot use `[0]` |
| `cors` in `google_storage_bucket` | **set** | ❌ Cannot use `[0]` |
| `versioning` in `google_storage_bucket` | **list** | ✅ Can use `[0]` |

### Working with Set-Type Blocks

**Problem:** Cannot index sets with `[0]`
```hcl
# ❌ WRONG: This will fail
condition = google_storage_bucket.this.lifecycle_rule[0].action[0].type == "Delete"
# Error: Cannot index a set value
```

**Solution 1:** Use `command = apply` to materialize the set
```hcl
run "test_lifecycle" {
  command = apply  # Creates real/mocked resources

  assert {
    # Now the set is materialized and can be checked
    condition     = length([for rule in google_storage_bucket.this.lifecycle_rule :
                             rule.action[0].type if rule.action[0].type == "Delete"]) > 0
    error_message = "Lifecycle rule should include a Delete action"
  }
}
```

**Solution 2:** Check at resource level (avoid accessing nested blocks)
```hcl
run "test_lifecycle_exists" {
  command = plan

  assert {
    # Check that the resource exists without accessing set members
    condition     = google_storage_bucket.this != null
    error_message = "Storage bucket should be created"
  }
}
```

**Solution 3:** Use for expressions (works in apply mode)
```hcl
run "test_lifecycle_action" {
  command = apply

  assert {
    condition     = alltrue([
      for rule in google_storage_bucket.this.lifecycle_rule :
      alltrue([
        for action in [rule.action] :
        action[0].type == "SetStorageClass"
      ])
    ])
    error_message = "Lifecycle should transition storage class"
  }
}
```

### command = plan vs command = apply

**Critical decision:** When to use each command mode

#### Use `command = plan`

**When:**
- Checking input validation
- Verifying resource will be created
- Testing variable defaults
- Checking resource attributes that are **input-derived** (not computed)

**Example:**
```hcl
run "test_input_validation" {
  command = plan  # Fast, no resource creation

  variables {
    bucket_name = "test-bucket"
  }

  assert {
    # bucket name is an input, known at plan time
    condition     = google_storage_bucket.this.name == "test-bucket"
    error_message = "Bucket name should match input"
  }
}
```

#### Use `command = apply`

**When:**
- Checking computed attributes (IDs, self_links, generated URLs)
- Accessing set-type blocks
- Verifying actual resource behavior
- Testing with real/mocked provider responses

**Example:**
```hcl
run "test_computed_values" {
  command = apply  # Executes and gets computed values

  variables {
    bucket_name = "test-bucket"
  }

  assert {
    # self_link is computed, only known after apply
    condition     = length(google_storage_bucket.this.self_link) > 0
    error_message = "Bucket should have a self_link after creation"
  }
}
```

#### Common Pitfall: Checking Computed Values in Plan Mode

**Problem:**
```hcl
run "test_bucket_url" {
  command = plan  # ❌ WRONG MODE

  variables {
    bucket_name = "test-bucket"
  }

  assert {
    # url is computed, unknown at plan time!
    condition     = google_storage_bucket.this.url != ""
    error_message = "Bucket URL should be set"
  }
}
# Error: Condition expression could not be evaluated at this time
```

**Solution:**
```hcl
run "test_bucket_url" {
  command = apply  # ✅ CORRECT MODE

  variables {
    bucket_name = "test-bucket"
  }

  assert {
    # Now url has been generated by provider
    condition     = startswith(google_storage_bucket.this.url, "gs://")
    error_message = "Bucket URL should start with gs://"
  }
}
```

**Quick Decision Guide:**
```
Checking input values? → command = plan
Checking computed values? → command = apply
Accessing set-type blocks? → command = apply
Need fast feedback? → command = plan (with mocks)
Testing real behavior? → command = apply (without mocks)
```

### With Mocking (1.7+)

```hcl
mock_provider "google" {
  mock_resource "google_compute_instance" {
    defaults = {
      id        = "projects/my-project/zones/us-central1-a/instances/mock-instance"
      self_link = "https://www.googleapis.com/compute/v1/projects/my-project/zones/us-central1-a/instances/mock-instance"
    }
  }
}
```

### Pros

- Native HCL syntax (familiar to Terraform users)
- No external dependencies
- Fast execution with mocks
- Good for unit testing module logic

### Cons

- Newer feature (less mature than Terratest)
- Limited ecosystem/examples
- Mocking doesn't catch real-world GCP behavior

---

### Complete Test Examples (Following Best Practices)

#### Example 1: GCS Bucket Tests

```hcl
# tests/unit/gcs_bucket.tftest.hcl

mock_provider "google" {}  # Zero cost with mocks

# Test 1: Input validation (fast, plan mode)
run "validate_bucket_name" {
  command = plan

  variables {
    bucket_name = "my-test-bucket"
  }

  assert {
    condition     = google_storage_bucket.this.name == "my-test-bucket"
    error_message = "Bucket name should match input"
  }
}

# Test 2: Versioning defaults (plan mode - versioning is a list)
run "verify_versioning_enabled" {
  command = plan

  variables {
    bucket_name = "versioned-bucket"
  }

  assert {
    condition     = google_storage_bucket.this.versioning[0].enabled == true
    error_message = "Versioning should be enabled by default"
  }
}

# Test 3: Uniform bucket-level access
run "verify_uniform_access" {
  command = plan

  variables {
    bucket_name = "secure-bucket"
  }

  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access == true
    error_message = "Uniform bucket-level access should be enabled"
  }
}

# Test 4: Computed values (apply mode required)
run "verify_self_link" {
  command = apply

  variables {
    bucket_name = "test-bucket"
  }

  assert {
    condition     = length(google_storage_bucket.this.self_link) > 0
    error_message = "Bucket should have a self_link"
  }

  assert {
    condition     = startswith(google_storage_bucket.this.url, "gs://")
    error_message = "Bucket URL should start with gs://"
  }
}
```

#### Example 2: Lifecycle Rules

```hcl
# tests/unit/lifecycle.tftest.hcl

mock_provider "google" {}

run "verify_lifecycle_transitions" {
  command = apply  # Required for set-type lifecycle_rule blocks

  variables {
    bucket_name = "lifecycle-bucket"
    lifecycle_rules = [{
      action = {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
      condition = {
        age = 90
      }
    },
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age = 180
      }
    }]
  }

  assert {
    # Check that lifecycle rules exist using for expression
    condition = length([
      for rule in google_storage_bucket.this.lifecycle_rule :
      rule if rule.action[0].type == "SetStorageClass"
    ]) == 2
    error_message = "Should have 2 lifecycle rules"
  }

  assert {
    # Verify NEARLINE transition exists
    condition = length([
      for rule in google_storage_bucket.this.lifecycle_rule :
      rule if rule.action[0].storage_class == "NEARLINE"
    ]) == 1
    error_message = "Should have NEARLINE transition"
  }
}
```

---

## Terratest (Go-based)

**Recommended for:** Teams with Go experience, robust integration testing

### When to Use

- Team has Go experience
- Need robust integration testing
- Testing multiple providers/complex infrastructure
- Want battle-tested framework with large community

### Basic Structure

```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestGCSModule(t *testing.T) {
    t.Parallel() // ALWAYS include for parallel execution

    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/complete",
        Vars: map[string]interface{}{
            "bucket_name": "test-bucket-" + uniqueId(),
        },
    }

    // Clean up resources after test
    defer terraform.Destroy(t, terraformOptions)

    // Run terraform init and apply
    terraform.InitAndApply(t, terraformOptions)

    // Get outputs and verify
    bucketName := terraform.Output(t, terraformOptions, "bucket_name")
    assert.NotEmpty(t, bucketName)
}
```

### Cost Management

```go
// Use labels for automated cleanup
Vars: map[string]interface{}{
    "labels": map[string]string{
        "environment": "test",
        "ttl":         "2h", // Auto-delete after 2 hours
    },
}
```

### Critical Patterns

1. **Always use `t.Parallel()`** - Enables parallel test execution
2. **Always use `defer terraform.Destroy()`** - Ensures cleanup
3. **Use unique identifiers** - Avoid resource conflicts
4. **Label resources** - Enable cost tracking and automated cleanup
5. **Use separate GCP projects** - Isolate test infrastructure

### Real-world Costs

- Small module (GCS, IAM): $0-5 per run
- Medium module (VPC, Compute Engine): $5-20 per run
- Large module (Cloud SQL, GKE cluster): $20-100 per run

### Optimization with Test Stages

```go
// Test stages for faster iteration
stage := test_structure.RunTestStage

stage(t, "setup", func() {
    terraform.InitAndApply(t, opts)
})

stage(t, "validate", func() {
    // Assertions here
})

stage(t, "teardown", func() {
    terraform.Destroy(t, opts)
})

// Skip stages during development:
// export SKIP_setup=true
// export SKIP_teardown=true
```

---

## Best Practices Summary

### For All Frameworks

1. **Start with static analysis** - Always free, always fast
2. **Use unique identifiers** - Prevent resource conflicts
3. **Label test resources** - Enable tracking and cleanup
4. **Separate test projects** - Isolate test infrastructure
5. **Implement TTL** - Automatic resource cleanup

### Framework Selection

```
Quick syntax check? → terraform validate + fmt
Security scan? → trivy + checkov
Terraform 1.6+, simple logic? → Native tests
Pre-1.6, or complex integration? → Terratest
```

### Cost Optimization

1. Use mocking for unit tests
2. Implement resource TTL labels
3. Run integration tests only on main branch
4. Use smaller machine types in tests
5. Share test resources when safe

---

**Back to:** [Main Skill File](../SKILL.md)
