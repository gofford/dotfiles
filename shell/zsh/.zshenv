#!/bin/zsh

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export ZDOTDIR=$XDG_CONFIG_HOME/zsh

# Default editors (terminal and GUI)
export EDITOR='vi'
export VISUAL='cursor'