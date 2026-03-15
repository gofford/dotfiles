---
description: Delete a Sediment memory by id
agent: architect
subtask: true
---

Delete the Sediment memory with id: $ARGUMENTS

Rules:
- Confirm the id exists via `sediment_list` before deleting.
- Use `sediment_forget` to delete.
- Do not delete multiple memories unless explicitly requested.
