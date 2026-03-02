---
description: Knowledge continuity audit — maps documentation gaps and bus factor risks
---

Perform a full knowledge continuity audit of this project.
$ARGUMENTS

Run Finder first (2-3 parallel tasks) to build a discovery map, then delegate to the Auditor agent with `focus: knowledge-continuity` passing that map as context.

If Finder returns no hits (empty repo, no code files), report: "No code found to audit." and stop.
