# dotfiles

macOS development environment powered by [Dotbot](https://github.com/anishathalye/dotbot).

## Install

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
- System tooling configs: `ssh/`, `direnv/`, `k9s/`, and OpenCode config in `opencode/`.

## Repo Layout

This repo stays intentionally coarse to avoid churn:

- Entrypoints: `Makefile`, `install`, `install.conf.yaml`, `steps/`
- Packages: `brew/`
- Tool configs: `shell/`, `git/`, `cursor/`, `ghostty/`, `atuin/`, `ssh/`, `direnv/`, `k9s/`, `opencode/`

## Package Management

Packages are defined in `brew/` and installed via `brew-file`.

```bash
brew file install -f brew/Brewfile
brew file install -f brew/Brewfile.cask
brew file install -f brew/Brewfile.appstore
brew file install -f brew/Brewfile.cursor
```

## Notes

- First-time install may prompt for `sudo` to set the default shell (Homebrew zsh).
- App Store installs require signing into the Mac App Store (used by `mas`).
- Configs are symlinked into your home directory. Edit files in `~/.dotfiles/` and re-run `make install` if needed.
- If you need machine-specific git overrides, you can edit `~/.gitconfig` after install and keep those changes uncommitted.
