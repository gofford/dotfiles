#!/bin/zsh

##
# Invoke direnv
#

__command_is_present direnv && {
	emulate zsh -c "$(direnv export zsh)"
}