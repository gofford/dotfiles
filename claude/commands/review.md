---
description: Review branch delta - verify then adversarial review
argument-hint: [deep]
---

First verify an upstream is configured:

!`git rev-parse @{upstream} 2>/dev/null || echo "ERROR: No upstream set. Run: git push -u origin <branch>"`

If the output starts with "ERROR", display the message and stop.

The changed files on this branch are:

!`git diff --name-only @{upstream}...HEAD`

If empty, respond: "No changes found between this branch and upstream." and stop.

Target file list: all files listed above.

The diff to review:

!`git diff @{upstream}...HEAD`

## Tester gate

Evaluate whether the changed files contain testable code (Python, dbt models).

If testable: invoke Tester with the target file list and inferred test scope.
If Tester FAILs: report failures and stop. Do not proceed to Reviewer.

If not testable (config-only, docs-only): skip Tester.

## Reviewer gate

Invoke Reviewer with:
- target file list
- tester output (if tester ran)
- the diff above

## Codex challenge (when $ARGUMENTS contains "deep")

If `$ARGUMENTS` contains "deep":
1. Invoke Codex in review mode (blind — it generates its own diff).
   Run in parallel with Reviewer when possible.
2. Synthesize both results:
   - Agreed: findings flagged by both Reviewer and Codex
   - Codex-only: novel findings from external review
   - Reviewer-only: findings Codex did not flag
   - Disagreements: contradictory assessments
3. Present overall Status (PASS or FAIL based on combined analysis).

If `$ARGUMENTS` does not contain "deep", present only the Reviewer's findings.

$ARGUMENTS
