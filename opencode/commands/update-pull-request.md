---
description: Draft updated PR title/body from template and branch delta
agent: architect
subtask: true
---

Prepare updated pull request content for: `$ARGUMENTS`

Requirements:
- Use the repository pull-request template as the body scaffold.
- Derive content from the branch diff versus upstream (`@{upstream}...HEAD`).
- Draft a Conventional Commit style PR title, max 72 characters.
- Return title and full body ready to paste.

Template discovery order:
1. `.github/pull_request_template.md`
2. `.github/pull_request_template.mdx`
3. `.github/PULL_REQUEST_TEMPLATE.md`
4. Any file under `.github/PULL_REQUEST_TEMPLATE/`

If no template is found, use this default structure:

```
## Summary
- [what changed and why]

## Changes
- [file-by-file summary]

## Test plan
- [ ] [verification steps]

## Notes
[caveats, migration steps, or reviewer guidance]
```

Output format:
- `Title:` `<conventional-commit-style title, <=72 chars>`
- `Body:`
  - Fully rendered template content with sections filled from current branch changes.
  - Keep placeholders only when truly unknown; mark them clearly.

Rules:
- Do not create or open PRs; human handles PR creation.
- Prefer local git metadata and diffs; do not use bash for network I/O.
