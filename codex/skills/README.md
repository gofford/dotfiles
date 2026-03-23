# Codex Skills

Skill configuration lives in dotfiles. Skill payloads do not.

- Declare each installed skill independently under `[[skills]]`.
- Dotbot runs `codex/scripts/install-skills.sh`, which uses `npx skills`.
- Global Codex skills are installed into `~/.codex/skills/`.
- Keep skills disabled until you actually want them installed.

Current manifest examples target the Dagster skills repo:

- `dagster-expert`
- `dignified-python`

Each manifest entry uses:

- `id`: `owner/repo/skill`
- `enabled`: whether Dotbot should sync it into Codex

Why this shape:

- one repo can provide many independently installed skills
- you enable only the skills you want
- the `skills` CLI manages install layout for Codex
- disabled managed skills are removed on rerun via `npx skills remove`

Installing a skill does not automatically expose it to any subagent. Add `skills.config` later only if you explicitly want agent-level skill wiring.
