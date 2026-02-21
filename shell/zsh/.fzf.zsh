#!/bin/zsh
# FZF Configuration
# -----------------

# Setup fzf PATH (Apple Silicon)
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi

# Use fd for faster file searching (respects .gitignore)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Atom One Dark color theme
export FZF_DEFAULT_OPTS="
  --height 80%
  --layout=reverse
  --border=rounded
  --info=inline
  --color=bg+:#3e4451,spinner:#61afef,hl:#56b6c2
  --color=fg:#abb2bf,header:#56b6c2,info:#61afef,pointer:#61afef
  --color=marker:#98c379,fg+:#e6efff,prompt:#61afef,hl+:#56b6c2
  --color=border:#3e4451
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {} | pbcopy)+abort'"

# Ctrl+T: File search with bat preview
export FZF_CTRL_T_OPTS="
  --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || eza --color=always {}'
  --preview-window 'right:60%:wrap:border-left'
  --header 'CTRL-/: toggle preview | CTRL-Y: copy'"

# Alt+C: Directory search with eza tree preview
export FZF_ALT_C_OPTS="
  --preview 'eza --tree --color=always --icons --level=2 {} | head -200'
  --preview-window 'right:50%:border-left'
  --header 'Jump to directory'"

# Auto-completion
source "$(brew --prefix)/opt/fzf/shell/completion.zsh"

# Key bindings (Ctrl+T, Alt+C, Ctrl+R)
source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
