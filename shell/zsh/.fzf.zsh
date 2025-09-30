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

# Nord color theme (uses terminal background for seamless look)
export FZF_DEFAULT_OPTS="
  --height 80%
  --layout=reverse
  --border=rounded
  --info=inline
  --color=bg+:#3B4252,spinner:#81A1C1,hl:#88C0D0
  --color=fg:#D8DEE9,header:#88C0D0,info:#5E81AC,pointer:#81A1C1
  --color=marker:#A3BE8C,fg+:#ECEFF4,prompt:#81A1C1,hl+:#8FBCBB
  --color=border:#4C566A
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

# Ctrl+R: History search (handled by atuin-fzf, but fallback styling)
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window 'down:3:wrap'
  --header 'CTRL-D: filter by directory | CTRL-R: all history'"

# Auto-completion
source "$(brew --prefix)/opt/fzf/shell/completion.zsh"

# Key bindings (Ctrl+T, Alt+C, Ctrl+R)
source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
