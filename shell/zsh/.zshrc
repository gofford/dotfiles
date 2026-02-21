#!/bin/zsh

# Modern zsh options
setopt extended_glob
setopt AUTO_CD

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=${ZDOTDIR:-~}/.zsh_history

# Load custom completions (fpath only — compinit autoloads them)
ZCOMPDIR=${ZCOMPDIR:-$ZDOTDIR/completions}
[[ -d $ZCOMPDIR ]] && fpath=($ZCOMPDIR $fpath)

# Modern completion system with 24h dump caching
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit -d "${ZDOTDIR}/.zcompdump"
else
  compinit -C -d "${ZDOTDIR}/.zcompdump"
fi

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Source custom config files
[[ -e ${ZDOTDIR:-~}/.aliases ]] && source ${ZDOTDIR:-~}/.aliases

# Disable zsh-utils-editor cursor management — let Ghostty control cursor style
zstyle ':zsh-utils:plugins:editor' set-cursor-style no

# Load plugins with Sheldon
eval "$(sheldon source)"

# Restore emacs line-editing shortcuts overridden by vi keymap
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line

# Real-time history sharing across all shells (zsh-utils-history sets INC_APPEND only)
# Also restore HISTSIZE/SAVEHIST — zsh-utils-history overwrites them to 10000
setopt SHARE_HISTORY
HISTSIZE=50000
SAVEHIST=50000

# zsh-history-substring-search keybindings (must bind after sheldon loads the plugin)
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

# zoxide (smart cd)
eval "$(zoxide init zsh --cmd cd)"

# direnv (auto-load env vars)
eval "$(direnv hook zsh)"

# fzf
[ -f ${ZDOTDIR:-~}/.fzf.zsh ] && source ${ZDOTDIR:-~}/.fzf.zsh

# atuin + fzf integration (must load after fzf)
[ -f ${ZDOTDIR:-~}/.atuin-fzf.zsh ] && source ${ZDOTDIR:-~}/.atuin-fzf.zsh

# prompt
eval "$(oh-my-posh init zsh --config ~/.prompt.omp.json)"

# opencode
export PATH=$HOME/.opencode/bin:$PATH
