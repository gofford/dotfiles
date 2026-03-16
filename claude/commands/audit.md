---
description: Codebase audit - architecture health or knowledge continuity
argument-hint: [scope] [continuity] [deep]
---

If `$ARGUMENTS` is empty, run a full architecture audit.

If `$ARGUMENTS` contains "continuity", set Auditor focus to knowledge-continuity.
Otherwise, default to architecture audit.

1. Explore the project structure first (2-4 parallel exploration tasks).
2. Delegate to the Auditor agent with the discovery summary and any scope
   constraints from $ARGUMENTS.
3. If no code is found, report: "No code found to audit." and stop.

## Codex challenge (when $ARGUMENTS contains "deep")

If `$ARGUMENTS` contains "deep":
1. After Auditor completes, invoke Codex in audit mode with the
   Auditor's report.
2. Synthesize:
   - Accepted challenges: where Codex identified valid gaps
   - Rejected challenges: where Auditor's original findings stand
   - Missing risks: high-severity items neither originally flagged
3. Present the merged audit report.

$ARGUMENTS
