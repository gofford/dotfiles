# CI/CD Integration Reference

## Table of Contents
- [GitHub Actions](#github-actions)
- [GitLab CI](#gitlab-ci)
- [BitBucket Pipelines](#bitbucket-pipelines)
- [Terramate Cloud Integration](#terramate-cloud-integration)
- [Best Practices](#best-practices)

## GitHub Actions

### Pull Request Preview

```yaml
# .github/workflows/pr-preview.yml
name: Terraform PR Preview

on:
  pull_request:
    branches: [main]

jobs:
  preview:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
      id-token: write
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.5.0"
      
      - name: Install Terramate
        run: |
          curl -sL https://github.com/terramate-io/terramate/releases/latest/download/terramate_linux_amd64.tar.gz | tar xz
          sudo mv terramate /usr/local/bin/
      
      - name: List changed stacks
        run: terramate list --changed
      
      - name: Initialize Terraform
        run: terramate run --changed -- terraform init
      
      - name: Plan changed stacks
        run: terramate run --changed -- terraform plan -out=plan.tfplan
```

### Deploy on Merge

```yaml
# .github/workflows/deploy.yml
name: Terraform Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - uses: hashicorp/setup-terraform@v3
      
      - name: Install Terramate
        run: |
          curl -sL https://github.com/terramate-io/terramate/releases/latest/download/terramate_linux_amd64.tar.gz | tar xz
          sudo mv terramate /usr/local/bin/
      
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
      
      - name: List changed stacks
        run: |
          terramate list --changed --git-change-base HEAD~1
      
      - name: Deploy changed stacks
        run: |
          terramate run --changed --git-change-base HEAD~1 -- terraform init
          terramate run --changed --git-change-base HEAD~1 -- terraform apply -auto-approve
```

### With Terramate Cloud

```yaml
# .github/workflows/deploy-cloud.yml
name: Deploy with Terramate Cloud

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - uses: hashicorp/setup-terraform@v3
      
      - name: Install Terramate
        run: |
          curl -sL https://github.com/terramate-io/terramate/releases/latest/download/terramate_linux_amd64.tar.gz | tar xz
          sudo mv terramate /usr/local/bin/
      
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
      
      - name: Deploy with sync
        env:
          TERRAMATE_CLOUD_TOKEN: ${{ secrets.TERRAMATE_CLOUD_TOKEN }}
        run: |
          terramate run --changed --sync-deployment -- terraform init
          terramate run --changed --sync-deployment -- terraform apply -auto-approve
```

## GitLab CI

### Pull Request Preview

```yaml
# .gitlab-ci.yml
stages:
  - plan
  - apply

variables:
  TF_VERSION: "1.5.0"

.terramate_setup: &terramate_setup
  before_script:
    - curl -sL https://github.com/terramate-io/terramate/releases/latest/download/terramate_linux_amd64.tar.gz | tar xz
    - mv terramate /usr/local/bin/
    - terramate version

plan:
  stage: plan
  <<: *terramate_setup
  script:
    - terramate list --changed
    - terramate run --changed -- terraform init
    - terramate run --changed -- terraform plan
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

apply:
  stage: apply
  <<: *terramate_setup
  script:
    - terramate list --changed --git-change-base HEAD~1
    - terramate run --changed --git-change-base HEAD~1 -- terraform init
    - terramate run --changed --git-change-base HEAD~1 -- terraform apply -auto-approve
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

## BitBucket Pipelines

```yaml
# bitbucket-pipelines.yml
image: hashicorp/terraform:1.5

definitions:
  steps:
    - step: &terramate-setup
        name: Setup Terramate
        script:
          - curl -sL https://github.com/terramate-io/terramate/releases/latest/download/terramate_linux_amd64.tar.gz | tar xz
          - mv terramate /usr/local/bin/

pipelines:
  pull-requests:
    '**':
      - step:
          <<: *terramate-setup
          name: Plan Changes
          script:
            - terramate list --changed
            - terramate run --changed -- terraform init
            - terramate run --changed -- terraform plan

  branches:
    main:
      - step:
          <<: *terramate-setup
          name: Deploy Changes
          deployment: production
          script:
            - terramate list --changed --git-change-base HEAD~1
            - terramate run --changed --git-change-base HEAD~1 -- terraform init
            - terramate run --changed --git-change-base HEAD~1 -- terraform apply -auto-approve
```

## Terramate Cloud Integration

### Authentication

```bash
# Generate API token in Terramate Cloud UI
# Set as CI secret: TERRAMATE_CLOUD_TOKEN
```

### Sync Deployments

```yaml
- name: Deploy with tracking
  env:
    TERRAMATE_CLOUD_TOKEN: ${{ secrets.TERRAMATE_CLOUD_TOKEN }}
  run: |
    terramate run --changed --sync-deployment -- terraform apply -auto-approve
```

### Sync Previews (Plans)

```yaml
- name: Plan with preview
  env:
    TERRAMATE_CLOUD_TOKEN: ${{ secrets.TERRAMATE_CLOUD_TOKEN }}
  run: |
    terramate run --changed --sync-preview -- terraform plan
```

### Drift Detection

```yaml
# .github/workflows/drift.yml
name: Drift Detection

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  drift:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Detect drift
        env:
          TERRAMATE_CLOUD_TOKEN: ${{ secrets.TERRAMATE_CLOUD_TOKEN }}
        run: |
          terramate run --sync-drift-status -- terraform plan -detailed-exitcode
```

## Best Practices

### 1. Always Use Change Detection in CI

```yaml
# Good - only affected stacks
terramate run --changed -- terraform apply

# Avoid - runs all stacks every time
terramate run -- terraform apply
```

### 2. Set Correct Base Reference

```yaml
# For PRs - compare to target branch
terramate list --changed

# For main branch deploys - compare to previous commit
terramate list --changed --git-change-base HEAD~1
```

### 3. Fetch Full Git History

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Required for change detection
```

### 4. Use Parallelism Wisely

```yaml
# Parallel init is safe
terramate run --parallel 4 -- terraform init

# Sequential apply respects dependencies
terramate run -- terraform apply
```

### 5. Handle Failures Gracefully

```yaml
# Continue on error to see all failures
terramate run --continue-on-error -- terraform plan

# Fail fast for deployments
terramate run -- terraform apply
```

### 6. Secure Secrets

```yaml
# Use OIDC for cloud provider auth
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
    service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

# Terramate Cloud token
env:
  TERRAMATE_CLOUD_TOKEN: ${{ secrets.TERRAMATE_CLOUD_TOKEN }}
```

### 7. Cache Terraform Providers

```yaml
- uses: actions/cache@v4
  with:
    path: |
      ~/.terraform.d/plugin-cache
    key: ${{ runner.os }}-terraform-${{ hashFiles('**/.terraform.lock.hcl') }}
```
