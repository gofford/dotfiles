#!/bin/zsh
#
# .zprofile - Zsh file loaded on login.
#

#
# Browser
#

if [[ "$OSTYPE" == darwin* ]]; then
    export BROWSER="${BROWSER:-open}"
fi

#
# Paths
#

# Ensure path arrays do not contain duplicates.
typeset -gU path fpath

# Set the list of directories that zsh searches for commands.
path=(
    $HOME/{,s}bin(N)
    /opt/{homebrew,local}/{,s}bin(N)
    /usr/local/{,s}bin(N)
    $path
)

#
# Tool Integration
#

# Cache Homebrew prefix once for this session
if command -v brew >/dev/null 2>&1; then
    export BREW_PREFIX="${BREW_PREFIX:-$(brew --prefix)}"
fi

# gcloud
if [[ -n "${BREW_PREFIX:-}" && -f "${BREW_PREFIX}/share/google-cloud-sdk/path.zsh.inc" ]]; then
    source "${BREW_PREFIX}/share/google-cloud-sdk/path.zsh.inc"
    source "${BREW_PREFIX}/share/google-cloud-sdk/completion.zsh.inc"
fi

[ -f "$HOME/.secrets.zsh" ] && source "$HOME/.secrets.zsh"
