#!/bin/zsh

# Modern zsh options
setopt extended_glob
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt AUTO_CD

# History configuration
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=${ZDOTDIR:-~}/.zsh_history

# Load custom functions and completions
ZCOMPDIR=${ZCOMPDIR:-$ZDOTDIR/completions}
[[ -d $ZCOMPDIR ]] && fpath=($ZCOMPDIR $fpath)
[[ -d $ZCOMPDIR ]] && autoload -Uz $ZCOMPDIR/*

# Modern completion system
autoload -Uz compinit
compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Source custom config files
[[ -e ${ZDOTDIR:-~}/.aliases ]] && source ${ZDOTDIR:-~}/.aliases

# Load plugins with Sheldon
eval "$(sheldon source)"

# Modern utilities initialization
# zoxide (smart cd)
eval "$(zoxide init zsh)"

# atuin (enhanced history)
eval "$(atuin init zsh)"

# direnv (auto-load env vars)
eval "$(direnv hook zsh)"

# fzf
[ -f ${ZDOTDIR:-~}/.fzf.zsh ] && source ${ZDOTDIR:-~}/.fzf.zsh

# prompt
eval "$(oh-my-posh init zsh --config ~/.prompt.omp.json)"


