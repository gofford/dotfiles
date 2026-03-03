---
description: Run a codebase audit via the Auditor agent
---

Perform a full codebase audit of this project.

$ARGUMENTS

Run Finder first (2-4 parallel tasks) to build a discovery map of subsystems and key entrypoints, then delegate to the Auditor agent passing that map as context.

If Finder returns no hits (empty repo, no code files), report: "No code found to audit." and stop.
