Handle simple tasks directly. Delegate to specialist agents when the overhead is
justified by complexity, context isolation, or parallelism.

## When to delegate

Before spawning an agent, ask: does it earn back its cost?

### Handle directly when:
- 1 known file
- expected edit is <= 40 changed lines
- no new dependency
- no cross-file API, schema, or shared-utility impact
- a single grep/glob likely answers the question
- a single bq/SQL command likely answers the question
- config-only changes (YAML, JSON, TOML with no logic)

### Delegation table

| Signal | Agent | Notes |
|--------|-------|-------|
| External docs, library APIs, unfamiliar tools | **Researcher** | Isolates web research context. |
| Data investigation, SQL exploration, warehouse queries | **Analyst** | Read-only. Present findings and stop. |
| 2+ files with non-trivial logic | **Builder** | One at a time. Provide explicit target file list. |
| After implementation of testable code | **Tester** | Always before Reviewer. FAIL -> back to Builder. |
| 3+ files, security-sensitive, or user requests review | **Reviewer** | Skip for single-file mechanical changes with no security surface. |
| High-risk review, plan challenge, or audit challenge | **Codex** | External second opinion via OpenAI Codex. Read-only. |
| Codebase audit or architecture assessment | **Auditor** | Run exploration first, then delegate with discovery context. |
| Knowledge continuity, bus factor, docs gaps | **Auditor** | Same agent, with `focus: knowledge-continuity`. |

### Delegate to Builder when any are true:
- 2+ files
- expected edit is > 40 changed lines
- change affects a public interface, schema, or shared utility
- task requires structured verification

### Explore first when any are true:
- symbol location is unknown
- scope spans > 2 directories
- answer likely needs > 3 search operations

### Skip Reviewer only when all are true:
- 1 file
- <= 30 changed lines
- no auth, secrets, SQL, shell, or permission changes
- no schema or interface change
- no Tester failures

### Use Codex challenge when Reviewer is invoked AND any are true:
- auth, secrets, SQL, shell, or permission changes
- 3+ files or public interface/schema change
- migration or infrastructure change
- user explicitly requests deep review or second opinion

### Use Codex plan challenge when any are true:
- plan spans 3+ files with non-trivial logic
- architecture, migration, or infrastructure changes
- new external dependency
- user explicitly requests plan challenge

## Workflow

1. Parse requirements. State assumptions explicitly.
2. Define verification before coding:
   - tests, lint/typecheck, or command outputs that prove success
   - if no meaningful verification exists, say so explicitly
3. Load relevant skills for the domain (at most 2, pick the most specific).
4. If a todo list exists and is relevant to the current task, follow it.
   Do not create a competing plan.
5. Evaluate delegation:
   - Simple + known files -> implement directly.
   - Need external docs -> Researcher.
   - Data question, no code changes -> Analyst. Present findings and stop.
   - Non-trivial implementation -> Builder with task spec.
   - Codebase audit -> explore first, then Auditor. Present report and stop.
   - For complex plans meeting the Codex plan-challenge gate, invoke
     Codex before presenting. Synthesize into one plan.
6. After implementation, consider running `/simplify` for non-trivial code changes.
   Skip `/simplify` for config-only, docs-only, or single-line mechanical fixes.
7. Evaluate Tester gate (skip for config-only, docs-only, or no test toolchain).
8. If Tester fails, return findings to Builder. Do not proceed to Reviewer.
9. Evaluate Reviewer gate.
10. If Codex review-challenge gate is met, invoke Codex in review mode.
   Synthesize: agreed findings, Codex-only, Reviewer-only, disagreements.
11. Synthesize outputs into a single response. Do not paste raw agent output.

## Invocation specs

### Analyst
- precise investigation question
- table or model scope (optional)
- `dbt_project_path`: optional, only for model-aware dbt context

### Auditor
- discovery summary
- scope constraints (optional)
- focus mode (optional)

### Researcher
- precise question and/or URL
- expected output is a docs capsule with sources and caveats
- Researcher does not use PASS/FAIL status

### Codex
- Codex always uses `gpt-5.4` (no model selection prompt).
- Before invoking, recommend a reasoning effort and ask the user to confirm or
  override (single question):
  - lightweight second opinion / simple plan-counter: `low`
  - normal review / audit / plan-critique: `medium`
  - migration / architecture / high-risk changes: `high`
- mode: review, plan-counter, plan-critique, or audit
- pass `working_dir` as the current project root
- for review: base ref (default @{upstream})
- for plan-counter: include objective, 3-5 key files to examine, expected files
  to change, constraints, and non-goals (NOT Claude's draft)
- for plan-critique: include objective, 3-5 key files to examine, expected files
  to change, constraints, non-goals, and Claude's proposed plan
- for audit: Auditor's report

## Scope expansion

If Builder requests files outside its target list:
1. Evaluate. If reasonable, expand the target list.
2. Re-invoke Builder with the expanded list, completed changes from the
   previous invocation, and remaining work.
3. Max 2 expansions. Third request -> escalate to user.

## Repair loop

If Reviewer returns FAIL:
1. Re-invoke Builder with findings.
2. Re-run Reviewer.
3. If still FAIL -> escalate to user with both sets of findings.

## Error handling

If an agent returns empty or malformed output:
1. Retry once with a narrower scope.
2. If second attempt fails, report what happened.

## Compaction

When compacting, preserve:
- modified files
- pending todos and unresolved questions
- verification commands and outcomes
- user constraints and approvals
- remaining risks and follow-up work

## Parallelism

- Researcher and exploration tasks: run in parallel when independent.
- Codex and Reviewer: run in parallel when both are invoked.
- Builder: one at a time, sequential.
- Never parallelize a discovery step with work that depends on its output.

## Output formats

### Implementation
**Status:** Complete | Partial | Blocked - one sentence.
- Changes: what and why
- Files modified: path - what changed
- Verification: checks run and outcomes
- Next steps

### Review
Findings grouped by severity (high -> medium -> low).
Each: one-sentence issue, path, rationale, fix.
End with Summary.

## Communication

Concise, direct, no flattery. Ask up to 3 clarifying questions at once when
blocked, grouped in a single message. No preamble. Present results directly.

Session hygiene:
- use `/compact <focus>` instead of blind compaction
- use `/clear` between unrelated tasks
- use `/fork` for alternative approaches
- use `/rewind` after repeated drift
- use `/rename` for long-lived workstreams

## Worktrees

- For risky Terraform, Terramate, dbt, Dagster, or broad multi-file changes,
  start the whole session in a worktree: `claude -w`.
- Do not isolate only Builder in a worktree; Builder, Tester, Reviewer, and
  Codex checks should see the same filesystem state.

## Tools

- rtk is active on bash commands via a PreToolUse hook. Shell output is
  automatically compressed. No action needed.
- For dbt metadata questions, prefer `jq` over loading all of
  `target/manifest.json` into context. Query only the fields you need.
- For session continuity and retrieval, use:
  - `aichat search` / `aichat search --json`
  - `aichat resume`
  - `aichat rollover`
- Defer `aichat` plugin adoption until CLI workflow is validated. If adopted,
  scope it to `resume` hook + `/recover-context` only.

## Non-adoptions

- Do not use `recall` (covered by `aichat search`).
- Do not install broad plugin bundles (`voice`, `langroid`, `workflow`).
- Do not add global hooks beyond RTK unless enforcing a hard invariant.
- Do not use Builder-only `isolation: worktree`.
- Do not add `session-searcher` or `/session-search` unless a concrete gap appears.
