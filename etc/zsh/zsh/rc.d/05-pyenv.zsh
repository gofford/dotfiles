#!/bin/zsh

##
# Invoke pyenv
#

__command_is_absent pyenv && {
	export PYENV_ROOT="$HOME/.pyenv"
	command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
	eval "$(pyenv init -)"
}