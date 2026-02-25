---
description: Evaluate existing PR comments and propose remediation
agent: architect
subtask: true
---

If `$ARGUMENTS` is empty, respond only with: "Usage: /feedback-pull-request <PR number or URL>" and stop.

Analyze feedback for pull request: `$ARGUMENTS`

Use `gh` CLI (read-only) to gather:
- review comments and review summaries
- unresolved conversations/threads
- review decisions (approved / changes requested)
- relevant failing checks if available

For each substantive comment/thread, determine:
1. Whether you agree, partially agree, or disagree
2. Why (technical rationale and risk)
3. The concrete remedial action (or rationale for no code change)

Output format:
1. Overall review posture (go/no-go and top blockers)
2. Comment-by-comment dispositions (agree/partial/disagree + reason)
3. Remedial action plan (file-by-file, prioritized)
4. Suggested response drafts for major threads
5. Proposed next steps for implementation

Rules:
- Analysis and planning only; do not modify files.
- Do not perform mutating GitHub actions.
