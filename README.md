# dotfiles

macOS development environment powered by [Dotbot](https://github.com/anishathalye/dotbot).

```bash
git clone https://github.com/jasongofford/.dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install
```

## Stack

| Category   | Tools                                                                                                                                                                     |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Terminal   | [Ghostty](https://ghostty.org/) with Nord theme                                                                                                                           |
| Shell      | Zsh + [Oh My Posh](https://ohmyposh.dev/) + [Sheldon](https://github.com/rossmacarthur/sheldon)                                                                           |
| History    | [Atuin](https://github.com/atuinsh/atuin) + [fzf](https://github.com/junegunn/fzf) integration                                                                            |
| Navigation | [zoxide](https://github.com/ajeetdsouza/zoxide) (smart cd)                                                                                                                |
| Editor     | [Cursor](https://cursor.sh/)                                                                                                                                              |
| Git        | [Lazygit](https://github.com/jesseduffield/lazygit), [git-spice](https://github.com/abhinav/git-spice) (stacked PRs)                                                      |
| Files      | [eza](https://github.com/eza-community/eza), [bat](https://github.com/sharkdp/bat), [fd](https://github.com/sharkdp/fd), [ripgrep](https://github.com/BurntSushi/ripgrep) |
| Infra      | Docker, [k9s](https://github.com/derailed/k9s), [Terramate](https://github.com/terramate-io/terramate)                                                                    |

## Keybindings

| Key       | Action                             |
| --------- | ---------------------------------- |
| `Ctrl+R`  | Fuzzy history search (fzf + atuin) |
| `Ctrl+\`  | Atuin native UI                    |
| `Ctrl+T`  | File search with preview           |
| `Alt+C`   | Directory jump                     |
| `z <dir>` | Smart cd (zoxide)                  |

## Structure

```
~/.dotfiles/
├── install              # Main entry point
├── install.conf.yaml    # Orchestrates steps
├── steps/               # Modular installation
│   ├── 01-bootstrap     # Homebrew, essentials
│   ├── 02-brew-core     # CLI tools
│   ├── 03-brew-casks    # Desktop apps
│   ├── 04-brew-appstore # Mac App Store
│   ├── 05-shell         # Zsh, prompt, plugins
│   ├── 06-dev           # Git config
│   ├── 07-system        # SSH, direnv
│   └── 08-extensions    # Editor extensions
├── shell/               # Shell configs
│   ├── zsh/             # .zshrc, aliases, fzf
│   ├── sheldon/         # Plugin manager
│   └── omp/             # Prompt theme
├── brew/                # Brewfiles
├── cursor/              # Editor settings
├── ghostty/             # Terminal config
├── atuin/               # History config
└── git/                 # Git config
```

## Commands

```bash
./install                         # Full install
./install -c steps/05-shell.yaml  # Single step
brew bundle --file=brew/Brewfile  # Install packages
git submodule update --init       # Update dotbot
```

## Updating

Configs are symlinked — edit in `~/.dotfiles/`, commit, push.
