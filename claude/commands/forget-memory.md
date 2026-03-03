---
description: Delete a Sediment memory by id
---

Delete the Sediment memory with id: $ARGUMENTS

Rules:
- Confirm the id exists via `mcp__sediment__list` before deleting.
- Use `mcp__sediment__forget` to delete.
- Do not delete multiple memories unless explicitly requested.
