# CI/CD Workflows for Terraform

> **Part of:** [terraform](../SKILL.md)
> **Purpose:** CI/CD integration patterns for Terraform on GCP

This document provides detailed CI/CD workflow templates and optimization strategies for infrastructure-as-code pipelines.

---

## Table of Contents

1. [GitHub Actions Workflow](#github-actions-workflow)
2. [GitLab CI Template](#gitlab-ci-template)
3. [Cost Optimization](#cost-optimization)
4. [Automated Cleanup](#automated-cleanup)
5. [Best Practices](#best-practices)

---

## GitHub Actions Workflow

### Complete Example

```yaml
# .github/workflows/terraform.yml
name: Terraform

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2

      - name: Terraform Format
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: TFLint
        run: |
          curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
          tflint --init
          tflint

  test:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Terraform Tests
        run: terraform test

      # Or for Terratest:
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Run Terratest
        run: |
          cd tests
          go test -v -timeout 30m -parallel 4

  plan:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan -out=tfplan

      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: tfplan
          path: tfplan

  apply:
    needs: plan
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2

      - name: Download Plan
        uses: actions/download-artifact@v3
        with:
          name: tfplan

      - name: Terraform Apply
        run: terraform apply tfplan
```

### With Cost Estimation (Infracost)

```yaml
  cost-estimate:
    needs: plan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Infracost
        uses: infracost/actions/setup@v2
        with:
          api-key: ${{ secrets.INFRACOST_API_KEY }}

      - name: Generate Cost Estimate
        run: |
          infracost breakdown --path . \
            --format json \
            --out-file /tmp/infracost.json

      - name: Post Cost Comment
        uses: infracost/actions/comment@v1
        with:
          path: /tmp/infracost.json
          behavior: update
```

---

## GitLab CI Template

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - test
  - plan
  - apply

variables:
  TF_ROOT: ${CI_PROJECT_DIR}

.terraform_template:
  image: hashicorp/terraform:latest
  before_script:
    - cd ${TF_ROOT}
    - terraform init

validate:
  extends: .terraform_template
  stage: validate
  script:
    - terraform fmt -check -recursive
    - terraform validate

test:
  extends: .terraform_template
  stage: test
  script:
    - terraform test
  only:
    - merge_requests
    - main

plan:
  extends: .terraform_template
  stage: plan
  script:
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan
    expire_in: 1 week
  only:
    - merge_requests
    - main

apply:
  extends: .terraform_template
  stage: apply
  script:
    - terraform apply tfplan
  dependencies:
    - plan
  only:
    - main
  when: manual
  environment:
    name: production
```

---

## Cost Optimization

### Strategy

1. **Use mocking for PR validation** (free)
2. **Run integration tests only on main branch** (controlled cost)
3. **Implement auto-cleanup** (prevent orphaned resources)
4. **Tag all test resources** (track spending)

### Example: Conditional Test Execution

```yaml
# GitHub Actions
test:
  runs-on: ubuntu-latest
  steps:
    - name: Run Unit Tests (Mocked)
      run: terraform test

    - name: Authenticate to GCP
      if: github.ref == 'refs/heads/main'
      uses: google-github-actions/auth@v2
      with:
        workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
        service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

    - name: Run Integration Tests
      if: github.ref == 'refs/heads/main'
      run: |
        cd tests
        go test -v -timeout 30m
```

### Cost-Aware Test Tags

```go
// In Terratest
terraformOptions := &terraform.Options{
    TerraformDir: "../examples/complete",
    Vars: map[string]interface{}{
        "labels": map[string]string{
            "environment": "test",
            "ttl":         "2h",
            "created_by":  "ci",
            "job_id":      os.Getenv("GITHUB_RUN_ID"),
        },
    },
}
```

---

## Automated Cleanup

### Cleanup Script (Bash)

```bash
#!/bin/bash
# cleanup-test-resources.sh

# Find and delete Compute Engine instances older than 2 hours with test label
PROJECT_ID=$(gcloud config get-value project)
CUTOFF=$(date -u -d '2 hours ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -v-2H +%Y-%m-%dT%H:%M:%S)

gcloud compute instances list \
  --project="$PROJECT_ID" \
  --filter="labels.environment=test AND creationTimestamp<'${CUTOFF}'" \
  --format="csv[no-heading](name,zone)" | \
  while IFS=, read -r name zone; do
    if [ -n "$name" ]; then
      echo "Deleting instance: $name in $zone"
      gcloud compute instances delete "$name" --zone="$zone" --quiet
    fi
  done
```

### Scheduled Cleanup (GitHub Actions)

```yaml
# .github/workflows/cleanup.yml
name: Cleanup Test Resources

on:
  schedule:
    - cron: '0 */2 * * *'  # Every 2 hours
  workflow_dispatch:        # Manual trigger

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Run Cleanup Script
        run: ./scripts/cleanup-test-resources.sh
```

---

## Best Practices

### 1. Separate Environments

```yaml
# Different workflows for different environments
.github/workflows/
  terraform-dev.yml
  terraform-staging.yml
  terraform-prod.yml
```

Or use reusable workflows:

```yaml
# .github/workflows/terraform-deploy.yml (reusable)
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string

jobs:
  deploy:
    environment: ${{ inputs.environment }}
    # ... deployment steps
```

### 2. Require Approvals for Production

```yaml
apply:
  environment:
    name: production
    # Requires manual approval in GitHub
  when: manual
```

### 3. Use Remote State

```hcl
# backend.tf
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "prod"
  }
}
```

GCS backends provide built-in state locking automatically — no separate lock table needed.

### 4. Handle Concurrent Runs

```yaml
# In CI, use -lock-timeout to handle concurrent runs
- name: Terraform Apply
  run: terraform apply -lock-timeout=10m tfplan
```

### 5. Cache Terraform Plugins

```yaml
# GitHub Actions
- name: Cache Terraform Plugins
  uses: actions/cache@v3
  with:
    path: |
      ~/.terraform.d/plugin-cache
    key: ${{ runner.os }}-terraform-${{ hashFiles('**/.terraform.lock.hcl') }}
```

### 6. Security Scanning in CI

```yaml
security-scan:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3

    - name: Run Trivy
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'config'
        scan-ref: '.'

    - name: Run Checkov
      uses: bridgecrewio/checkov-action@master
      with:
        directory: .
        framework: terraform
```

---

## Atlantis Integration

[Atlantis](https://www.runatlantis.io/) provides Terraform automation via pull request comments.

### atlantis.yaml

```yaml
version: 3
projects:
  - name: production
    dir: environments/prod
    workspace: default
    terraform_version: v1.6.0
    workflow: custom

workflows:
  custom:
    plan:
      steps:
        - init
        - plan:
            extra_args: ["-lock", "false"]
    apply:
      steps:
        - apply
```

### Benefits

- Plan results as PR comments
- Apply via PR comments
- Locking prevents concurrent changes
- Integrates with VCS (GitHub, GitLab, Bitbucket)

---

## Troubleshooting

### Issue: Tests fail in CI but pass locally

**Cause:** Different Terraform/provider versions

**Solution:**

```hcl
# versions.tf - Pin versions
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
```

### Issue: Parallel tests conflict

**Cause:** Resource naming collisions

**Solution:**

```go
// Use unique identifiers
uniqueId := random.UniqueId()
instanceName := fmt.Sprintf("test-instance-%s-%s",
    os.Getenv("GITHUB_RUN_ID"),
    uniqueId)
```

---

**Back to:** [Main Skill File](../SKILL.md)
