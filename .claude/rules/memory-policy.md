# Memory Policy

Three memory systems exist. Each has a distinct role.

## CLAUDE.md and rules (this layer)
Durable workflow and behavioral instructions. Edited by hand.

## Claude auto memory
Learned repo behaviors and recurring patterns. Managed by Claude automatically.
Let Claude learn. Do not duplicate auto memory content in CLAUDE.md.

## Sediment
Cross-session project conventions and decisions that benefit from explicit storage.

### When to use Sediment
- Recall: when prior decisions or repo conventions likely apply.
- Store: when the user states a durable preference or decision. Project scope. Keep it short.

### Never store in Sediment
- secrets, credentials, large blobs
- which file was just edited
- current task descriptions or error messages
- intermediate investigation results
- anything that only matters for this conversation
