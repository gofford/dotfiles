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

## Notes

- First-time install may prompt for `sudo` to set the default shell (Homebrew zsh).
- App Store installs require signing into the Mac App Store (used by `mas`). If you skip this step, run `make step STEP=04-brew-mas` after signing in.
- Configs are symlinked into your home directory. Edit files in your clone and run `make apply` to re-apply.
- Machine-specific git config goes in `~/.gitconfig.local` — it is included automatically and never tracked.
