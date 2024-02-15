#!/bin/zsh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt extended_glob

# Autoload functions you might want to use with antidote.
ZFUNCDIR=${ZFUNCDIR:-$ZDOTDIR/functions}
fpath=($ZFUNCDIR $fpath)
autoload -Uz $fpath[1]/*

# Source files you might use with antidote.
files=(.zstyles .aliases .utils)

for file in "${files[@]}"; do
    [[ -e ${ZDOTDIR:-~}/$file ]] && source ${ZDOTDIR:-~}/$file
done

# Clone antidote if necessary.
[[ -d ${ZDOTDIR:-~}/.antidote ]] || getantidote ${ZDOTDIR:-~}

# Source antidote.
source ${ZDOTDIR:-~}/.antidote/antidote.zsh

# Initialise plugins
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
    (
        antidote bundle <${zsh_plugins}.txt >${zsh_plugins}.zsh
    )
fi

source ${zsh_plugins}.zsh

# fzf
[ -f ${ZDOTDIR:-~}/.fzf.zsh ] && source ${ZDOTDIR:-~}/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ${ZDOTDIR:-~}/.p10k.zsh ]] || source ${ZDOTDIR:-~}/.p10k.zsh



# Created by `pipx` on 2024-01-22 14:48:55
export PATH="$PATH:/Users/jasongofford/.local/bin"
