# dotfiles

macOS development environment powered by [Dotbot](https://github.com/anishathalye/dotbot).

## Install

> Homebrew will be installed automatically if not already present.
> `~/.dotfiles` is the default clone path used in examples, but any clone path works.

```bash
git clone https://github.com/jasongofford/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make bootstrap
make apply
```

## Update

```bash
cd ~/.dotfiles
make update
```

## Upgrade

```bash
cd ~/.dotfiles
make upgrade
```

## Doctor

```bash
make doctor
```

## Re-apply Config Symlinks

Run this after pulling changes that add or modify config files, without reinstalling packages:

```bash
make apply
```

## Run A Single Step

```bash
make step STEP=05-shell
```

## Common Commands

- `make bootstrap` — install/bootstrap system dependencies.
- `make apply` — apply dotfile links and post-link setup.
- `make update` — pull latest repo changes and re-apply config.
- `make upgrade` — upgrade packages/tools and re-apply config.
- `make doctor` — run non-mutating prerequisite and environment checks.
- `make dock` — optional Dock rebuild.

## What's Included (High Level)

- Homebrew packages via `brew-file` using the files in `brew/`.
- Zsh + [Sheldon](https://github.com/rossmacarthur/sheldon) plugins + [Oh My Posh](https://ohmyposh.dev/) prompt.
- [Ghostty](https://ghostty.org/) terminal config.
- [Atuin](https://github.com/atuinsh/atuin) history/search with `fzf` integration.
- Git defaults (delta pager, SSH-based signing) plus tooling like lazygit and git-spice.
- Cursor settings and extensions.
- System tooling configs: `ssh/`, `direnv/`, `k9s/`, Claude config in `claude/`, and Codex config in `codex/`.

## Repo Layout

This repo stays intentionally coarse to avoid churn:

- Entrypoints: `Makefile`, `install`, `steps/`
- Packages: `brew/`
- Tool configs: `shell/`, `git/`, `cursor/`, `ghostty/`, `atuin/`, `ssh/`, `direnv/`, `k9s/`, `claude/`, `codex/`

## Package Management

Packages are defined in `brew/` and installed via `brew-file`.

```bash
brew file install -f brew/Brewfile
brew file install -f brew/Brewfile.cask
brew file install -f brew/Brewfile.mas
brew file install -f brew/Brewfile.cursor
```

## Notes

- First-time install may prompt for `sudo` to set the default shell (Homebrew zsh).
- App Store installs require signing into the Mac App Store (used by `mas`). If you skip this step, run `make step STEP=04-brew-mas` after signing in.
- Configs are symlinked into your home directory. Edit files in your clone and run `make apply` to re-apply.
- Codex is linked into `~/.codex`; Claude is linked into `~/.claude`.
- Codex skills are synced from `codex/skills/manifest.toml` into `~/.codex/skills` via `npx skills` (manifest IDs are `owner/repo@skill`; legacy `owner/repo/skill` is tolerated).
- OpenCode is no longer part of the active install flow.
- RTK is not part of the active install flow.
- Machine-specific git config goes in `~/.gitconfig.local` — it is included automatically and never tracked.
