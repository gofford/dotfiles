---
description: Review branch delta versus upstream via Reviewer
agent: reviewer
subtask: true
---

First verify an upstream is configured:

!`git rev-parse @{upstream} 2>/dev/null || echo "ERROR: No upstream set. Run: git push -u origin <branch>"`

If the output above starts with "ERROR", stop and display that message to the user. Do not proceed with the review.

Review all branch changes relative to upstream for the following files:

!`git diff --name-only @{upstream}...HEAD`

Target file list: all files listed above.

Use this exact diff range for review:

!`git diff @{upstream}...HEAD`
