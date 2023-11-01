#!/bin/zsh

##
# Configure path
#

export -U PATH path FPATH fpath MANPATH manpath
export -UT INFOPATH infopath

path=(
    /home/linuxbrew/.linuxbrew/bin(N)
    $path
    ~/.local/bin
)

fpath=(
    $ZDOTDIR/functions
    $fpath
    ~/.local/share/zsh/site-functions
)

if command -v brew > /dev/null; then
  znap eval brew-shellenv 'brew shellenv'
  fpath+=(
      $HOMEBREW_PREFIX/share/zsh/site-functions
  )
fi