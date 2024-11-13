# Setup fzf
# ---------
if [[ ! "$PATH" == */usr/local/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/usr/local/opt/fzf/bin"
fi

# Auto-completion
# ---------------
source "$(brew --prefix)/opt/fzf/shell/completion.zsh"

# Key bindings
# ------------
source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
