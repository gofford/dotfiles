---
name: terraform
description: Terraform IaC work: HCL/.tf changes, modules, providers, state/tfstate/backends, workspaces, refactors (moved blocks), testing (terraform test), and safe plan/apply workflows. Not for Terramate orchestration (use terramate).
---

# Terraform Skill

This skill is intentionally **lightweight**: it provides operating rules + routes you to the right deep-dive reference file. The heavy content lives under `references/` to reduce load cost.

## When to Use

Activate when the task is Terraform-specific, for example:
- Editing HCL / `.tf` / `.tfvars`
- Designing/refactoring modules (variables/outputs, examples, composition)
- Provider config/versioning, `.terraform.lock.hcl`, `required_version`
- State/backends/locking/workspaces (`tfstate`, remote state, backend migration)
- Testing (`terraform test`) or choosing a testing approach
- Safe PR workflows for plan/apply and guardrails for high-risk operations

## Don’t Use This Skill For

- **Terramate orchestration / stacks / change detection** → use `terramate`
- **Provider API reference** → use provider docs (this skill focuses on patterns/process)
- Generic cloud architecture questions without Terraform in scope

## First Questions (reduce risk early)

Ask these before recommending changes that could impact real infra:
- What Terraform version are we on?
- Which provider(s) and cloud(s)? Any org policy constraints?
- Where is **state** stored and how is it locked?
- Is **apply allowed** (and in which envs), or is this PR-only?
- Repo conventions: modules vs live env dirs; naming; CI; Atlantis?

## Default Workflow (safe + low-noise)

Prefer this order unless the user says otherwise:
- **Format**: `terraform fmt -recursive`
- **Validate**: `terraform validate`
- **Plan (scoped)**: run plan only for the relevant directory/workspace; avoid broad plans by default
- **Test (as appropriate)**:
  - Cheap checks first (static analysis, validate, security scan)
  - Native tests (`terraform test`) for module-level behavior when available
  - Terratest for higher-confidence integration needs

## Safety Gates (STOP and get explicit approval)

Never “just do it” for:
- State ops: `import`, `state rm`, `state mv`, `force-unlock`, backend changes/migrations
- Refactors that change resource addresses (require `moved` blocks / careful mapping)
- Any `apply`/`destroy`, especially broad scope or production targets

If any of the above is involved, read: **[State & Refactor Safety](references/state-ops-safety.md)**.

## Progressive Disclosure (open the right guide)

| Topic | Read this |
|------|-----------|
| Quick commands, troubleshooting | [Quick Reference](references/quick-reference.md) |
| Modules: structure, interface hygiene | [Module Patterns](references/module-patterns.md) |
| Code conventions, refactors, moved blocks, versioning | [Code Patterns](references/code-patterns.md) |
| Testing approach selection | [Testing Frameworks](references/testing-frameworks.md) |
| CI pipelines, Atlantis patterns, cost controls | [CI/CD Workflows](references/ci-cd-workflows.md) |
| Scanning, secrets/state sensitivity, IAM pitfalls | [Security & Compliance](references/security-compliance.md) |
| High-risk ops: state/backends/import/moved/refactors | [State & Refactor Safety](references/state-ops-safety.md) |

**How to use:** Load only the smallest relevant reference file(s) for the current question; avoid pulling multiple long guides unless necessary.

## License

This skill is licensed under the **Apache License 2.0**. See the LICENSE file for full terms.

**Copyright © 2026 Anton Babenko**
