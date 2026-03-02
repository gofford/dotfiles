# State & Refactor Safety (Terraform)

This guide is for **high-risk operations**: state/backends/imports/force-unlock and refactors that change resource addresses. These actions can cause drift, accidental recreation, or outages.

## STOP Conditions (explicit approval required)

Do not proceed without explicit user approval when any of these are in scope:

- `apply`, `destroy`, or any auto-approve behavior
- Backend changes/migrations (GCS, Terraform Cloud, etc.)
- `import`
- `state rm`, `state mv`, `state pull/push`-style manipulations
- `force-unlock`
- Refactors that change addresses (requires `moved` blocks or imports)
- Workspace or environment target changes

## Always Collect This Context

- **Terraform version**
- **Backend type** + where state lives + locking mechanism
- **Workspace strategy** (workspaces vs directories vs accounts/projects)
- **Blast radius**: which env/account/project is targeted (dev/staging/prod)
- **Change intent**: why this state/refactor action is needed

## Golden Rules

- **Never edit state files by hand**.
- **Prefer refactors that preserve addresses**; if addresses must change, use `moved` blocks where possible.
- **Treat state as sensitive** (it often contains secrets, resource IDs, IPs, and internal topology).
- **Small steps**: plan after each risky step; avoid stacking multiple risk operations into one run.

## Refactors that Change Addresses

### Prefer `moved` blocks (when possible)

Use `moved` blocks to tell Terraform how to map old addresses to new addresses without destroy/recreate.

Typical cases:
- Rename a resource (`google_compute_firewall.old` → `google_compute_firewall.this`)
- Move a resource into/out of a module
- Switch `count` → `for_each` (requires careful address mapping)

Workflow:
- Make the refactor + add the `moved` block(s)
- Run a **scoped plan**
- Verify the plan shows **no destructive recreation** (unless explicitly intended)

### Count/for_each migrations are risky

Switching addressing mode can trigger widespread recreation.

When migrating:
- Use `for_each` for stable keys where possible
- Add `moved` blocks for each mapped instance
- Plan after each mapping change; don’t “big bang” it

## Imports

Imports are appropriate when:
- You need Terraform to begin managing an existing resource
- State was lost and must be reattached

Guardrails:
- Import **one logical unit at a time**
- Immediately run plan to detect drift after each import
- Ensure config matches reality (labels, naming, optional arguments, defaults)

## Backends and Locking

Backend migrations can brick a team if locking/state locations diverge.

Guardrails:
- Verify GCS bucket permissions and locking configuration for the runner identity
- Confirm read/write access for all environments
- Coordinate changes; avoid parallel migrations by multiple people
- After changes, run init/plan in a safe environment first

## Force Unlock

Force unlock can allow concurrent mutations and corrupt state.

Before force unlock:
- Confirm no other process is legitimately running
- Prefer waiting for the lock holder if possible
- Capture the lock metadata for audit/debugging

## Output Expectations (what “good” looks like)

After the operation/refactor:
- A scoped plan shows only the intended changes
- No unexpected destroy/recreate
- State location/locking is consistent and reproducible for the team
- Any required follow-ups are documented (e.g., “apply required in staging next”)
