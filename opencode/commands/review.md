---
description: Review branch delta versus upstream — applies Tester gate then Reviewer
agent: architect
subtask: true
---

First verify an upstream is configured:

!`git rev-parse @{upstream} 2>/dev/null || echo "ERROR: No upstream set. Run: git push -u origin <branch>"`

If the output above starts with "ERROR", stop and display that message to the user. Do not proceed.

The changed files on this branch are:

!`git diff --name-only @{upstream}...HEAD`

If the output above is empty (no changed files), respond with: "No changed files found on this branch versus upstream." and stop.

Target file list: all files listed above.

The diff to review:

!`git diff @{upstream}...HEAD`

Apply your standard Tester → Reviewer gate:
1. Evaluate whether the Tester gate is met for the changed files above (testable code: Python, dbt models).
2. If met: invoke Tester with the target file list and inferred test scope. Include Tester output in the Reviewer invocation.
3. If Tester FAILs: report failures to the user and stop — do not proceed to Reviewer.
4. Invoke Reviewer with: target file list, the diff above, and Tester output (if Tester ran).
