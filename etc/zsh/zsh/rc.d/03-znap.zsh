#!/bin/zsh

##
# Plugin manager
#

local znap=~zsh/repos/zsh-snap/znap.zsh

# Auto-install Znap if it's not there yet.
if ! [[ -r $znap ]]; then   # Check if the file exists and can be read.
  git -C ~zsh/repos clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git
fi

. $znap   # Load Znap.