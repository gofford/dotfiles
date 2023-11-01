#!/bin/zsh

##
# History settings
#

setopt EXTENDED_GLOB

HISTFILE=${XDG_DATA_HOME:=~/.local/share}/zsh/history
[[ -d $HISTFILE:h ]] || mkdir -p $HISTFILE:h
SAVEHIST=$(( 100 * 1000 ))
HISTSIZE=$(( 1.2 * SAVEHIST ))

# Use modern file-locking mechanisms, for better safety & performance.
setopt HIST_FCNTL_LOCK

# Keep only the most recent copy of each duplicate entry in history.
setopt HIST_IGNORE_ALL_DUPS

# Auto-sync history between concurrent sessions.
setopt SHARE_HISTORY