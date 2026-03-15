# Security & Compliance

> **Part of:** [terraform](../SKILL.md)
> **Purpose:** Security best practices and compliance patterns for Terraform on GCP

This document provides security hardening guidance and compliance automation strategies for infrastructure-as-code.

---

## Table of Contents

1. [Security Scanning Tools](#security-scanning-tools)
2. [Common Security Issues](#common-security-issues)
3. [Compliance Testing](#compliance-testing)
4. [Secrets Management](#secrets-management)
5. [State File Security](#state-file-security)

---

## Security Scanning Tools

### Essential Security Checks

```bash
# Static security scanning
trivy config .
checkov -d .

# Compliance testing
terraform-compliance -f compliance/ -p tfplan.json
```

### Trivy Integration

**Install:**

```bash
# macOS
brew install trivy

# Linux
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# In CI
- uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'config'
    scan-ref: '.'
```

**Note:** Trivy is the successor to tfsec, maintained by Aqua Security.

**Example Output:**

```
Result #1 HIGH Firewall rule allows egress to all destinations
────────────────────────────────────────────────────────────────────────────────
  firewall.tf:15-24

   12 | resource "google_compute_firewall" "allow_all_egress" {
   13 |   name    = "allow-all-egress"
   14 |   network = google_compute_network.this.name
   15 |
   16 |   direction = "EGRESS"
   17 |   allow {
   18 |     protocol = "all"
   19 |   }
   20 |   destination_ranges = ["0.0.0.0/0"]
   21 | }
```

### Checkov Integration

```bash
# Run Checkov
checkov -d . --framework terraform

# Skip specific checks
checkov -d . --skip-check CKV_GCP_26

# Generate JSON report
checkov -d . -o json > checkov-report.json
```

---

## Common Security Issues

### ❌ DON'T: Store Secrets in Variables

```hcl
# BAD: Secret in plaintext
variable "database_password" {
  type    = string
  default = "SuperSecret123!"  # ❌ Never do this
}
```

### ✅ DO: Use Secret Manager

```hcl
# Good: Reference secrets from GCP Secret Manager
data "google_secret_manager_secret_version" "db_password" {
  secret = "prod-database-password"
}

resource "google_sql_database_instance" "this" {
  root_password = data.google_secret_manager_secret_version.db_password.secret_data
}
```

### ❌ DON'T: Use Default Network

```hcl
# BAD: Default network has permissive firewall rules
resource "google_compute_instance" "app" {
  name         = "app-instance"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  network_interface {
    network = "default"  # ❌ Avoid default network
  }
}
```

### ✅ DO: Create Dedicated VPC Networks

```hcl
# Good: Custom VPC with private subnets
resource "google_compute_network" "this" {
  name                    = "app-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "private" {
  name          = "app-private-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.this.id

  private_ip_google_access = true
}
```

### ❌ DON'T: Skip Encryption

```hcl
# BAD: Cloud SQL without encryption / GCS without CMEK
resource "google_sql_database_instance" "data" {
  name             = "my-database"
  database_version = "POSTGRES_15"
  # ❌ No CMEK encryption configured
}
```

### ✅ DO: Enable Encryption at Rest

```hcl
# Good: GCS bucket with CMEK encryption
resource "google_storage_bucket" "data" {
  name     = "my-data-bucket"
  location = "US"

  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_key.id
  }
}

# Good: Cloud SQL with CMEK encryption
resource "google_sql_database_instance" "data" {
  name             = "my-database"
  database_version = "POSTGRES_15"

  encryption_key_name = google_kms_crypto_key.sql_key.id
}
```

### ❌ DON'T: Open Firewall Rules to Internet

```hcl
# BAD: Firewall rule open to internet
resource "google_compute_firewall" "allow_all" {
  name    = "allow-all-ingress"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  source_ranges = ["0.0.0.0/0"]  # ❌ Never do this
}
```

### ✅ DO: Use Least-Privilege Firewall Rules

```hcl
# Good: Restrict to specific ports and sources
resource "google_compute_firewall" "app_https" {
  name    = "allow-https-internal"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = ["10.0.0.0/16"]  # ✅ Internal only
}
```

---

## Compliance Testing

### terraform-compliance

**Install:**

```bash
pip install terraform-compliance
```

**Example Compliance Test:**

```gherkin
# compliance/gcp-encryption.feature
Feature: GCP Resources must be encrypted

  Scenario: GCS buckets must have CMEK encryption
    Given I have google_storage_bucket defined
    Then it must contain encryption
    And it must contain default_kms_key_name

  Scenario: Cloud SQL instances must be encrypted
    Given I have google_sql_database_instance defined
    Then it must contain encryption_key_name
```

**Run Tests:**

```bash
# Generate plan in JSON
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

# Run compliance tests
terraform-compliance -f compliance/ -p tfplan.json
```

### Open Policy Agent (OPA)

```rego
# policy/gcs_encryption.rego
package terraform.gcs

deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "google_storage_bucket"
  not resource.change.after.encryption

  msg := sprintf("GCS bucket '%s' must have CMEK encryption enabled", [resource.address])
}
```

---

## Secrets Management

### GCP Secret Manager Pattern

```hcl
# Create secret
resource "google_secret_manager_secret" "db_password" {
  secret_id = "prod-database-password"

  replication {
    auto {}
  }
}

# Generate secure password
resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Use secret in Cloud SQL
data "google_secret_manager_secret_version" "db_password" {
  secret = google_secret_manager_secret.db_password.secret_id
}

resource "google_sql_database_instance" "this" {
  root_password = data.google_secret_manager_secret_version.db_password.secret_data
  # ...
}
```

### Environment Variables

```bash
# Never commit these
export TF_VAR_database_password="secret123"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

**In .gitignore:**

```
*.tfvars
.env
secrets/
```

---

## State File Security

### Encrypt State at Rest

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "prod"
  }
}
```

GCS encrypts all data at rest by default (Google-managed keys). For additional control, use CMEK.

GCS backends provide built-in state locking automatically — no separate lock table needed.

### Secure State Bucket

```hcl
resource "google_storage_bucket" "terraform_state" {
  name     = "my-terraform-state"
  location = "US"

  # Enable versioning (protect against accidental deletion)
  versioning {
    enabled = true
  }

  # Use CMEK encryption for additional control
  encryption {
    default_kms_key_name = google_kms_crypto_key.state_key.id
  }

  # Prevent public access
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}
```

### Restrict State Access

```hcl
# Grant Terraform service account access to the state bucket
resource "google_storage_bucket_iam_member" "terraform_state" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:terraform@my-project.iam.gserviceaccount.com"
}

# Deny all other access by not granting additional roles
# uniform_bucket_level_access ensures no ACL overrides
```

---

## IAM Best Practices

### ✅ DO: Use Least Privilege

```hcl
# Good: Specific role binding with narrow scope
resource "google_storage_bucket_iam_member" "app_read" {
  bucket = google_storage_bucket.app_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.app.email}"
}

resource "google_storage_bucket_iam_member" "app_write" {
  bucket = google_storage_bucket.app_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.app.email}"
}
```

### ❌ DON'T: Use Overly Broad Roles

```hcl
# BAD: Project-level owner role
resource "google_project_iam_member" "bad_binding" {
  project = var.project_id
  role    = "roles/owner"  # ❌ Never grant owner to service accounts
  member  = "serviceAccount:${google_service_account.app.email}"
}
```

---

## Compliance Checklists

### SOC 2 Compliance

- [ ] Encryption at rest for all data stores
- [ ] Encryption in transit (TLS/SSL)
- [ ] IAM policies follow least privilege
- [ ] Logging enabled for all resources
- [ ] MFA required for privileged access
- [ ] Regular security scanning in CI/CD

### HIPAA Compliance

- [ ] PHI encrypted at rest and in transit
- [ ] Access logs enabled
- [ ] Dedicated VPC with private subnets
- [ ] Regular backup and retention policies
- [ ] Audit trail for all infrastructure changes

### PCI-DSS Compliance

- [ ] Network segmentation (separate VPCs)
- [ ] No default passwords
- [ ] Strong encryption algorithms
- [ ] Regular security scanning
- [ ] Access control and monitoring

---

## Resources

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Checkov Documentation](https://www.checkov.io/)
- [terraform-compliance](https://terraform-compliance.com/)
- [Open Policy Agent](https://www.openpolicyagent.org/)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)

---

**Back to:** [Main Skill File](../SKILL.md)
