# dotfiles

macOS development environment powered by [Dotbot](https://github.com/anishathalye/dotbot).

## Install

> Homebrew will be installed automatically if not already present.

```bash
git clone https://github.com/jasongofford/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make install
```

## Update

```bash
cd ~/.dotfiles
git pull --ff-only
make update
```

## Re-apply Config Symlinks

Run this after pulling changes that add or modify config files, without reinstalling packages:

```bash
make link
```

## Run A Single Step

```bash
make step STEP=05-shell
```

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
- Configs are symlinked into your home directory. Edit files in `~/.dotfiles/` and run `make link` to re-apply.
- Codex is linked into `~/.codex`; Claude is linked into `~/.claude`.
- Codex skills are synced from `codex/skills/manifest.toml` into `~/.codex/skills` via `npx skills` (manifest IDs are `owner/repo@skill`; legacy `owner/repo/skill` is tolerated).
- OpenCode is no longer part of the active install flow.
- RTK is not part of the active install flow.
- Machine-specific git config goes in `~/.gitconfig.local` — it is included automatically and never tracked.
