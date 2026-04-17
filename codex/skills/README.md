# Codex Skills

Skill configuration lives in dotfiles. Skill payloads do not.

## How it works
- `codex/skills/manifest.toml` is the source of truth for managed skills.
- Declare each managed skill under `[[skills]]`.
- Dotbot runs `codex/scripts/install-skills.sh`, which calls `npx skills`.
- Managed skills from this repo install to `~/.agents/skills/`.
- Bundled/system Codex skills stay in `~/.codex/skills/.system/`.
- Any skill you want to keep managed must remain in the manifest.
- Keep entries disabled until you actually want them installed.
- The installer groups enabled entries by repo and runs one `skills add` per repo with repeated `--skill` flags.

## Manifest examples
Entries can come from multiple repos, for example:

- `dagster-io/skills@dagster-expert`
- `dagster-io/skills@dignified-python`
- `lightdash/lightdash@developing-in-lightdash`
- `vercel-labs/skills@find-skills`

## Entry fields
Each entry uses:

- `id`: `owner/repo@skill` (legacy `owner/repo/skill` is accepted for compatibility)
- `enabled`: whether Dotbot should sync it into Codex

## Why this format

- One repo can provide many independently installed skills.
- You enable only what you want.
- The `skills` CLI manages layout via `skills add <repo> --skill <name>...`.
- Disabled managed skills are removed on rerun via `npx skills remove`.

Installing a skill does not automatically expose it to any subagent. Add `skills.config` later only if you explicitly want agent-level skill wiring.
