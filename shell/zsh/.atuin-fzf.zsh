#!/bin/zsh
# fzf + atuin integration
# Based on: https://news.ycombinator.com/item?id=35256206
#
# Keybindings:
#   Ctrl+R  = fzf-powered atuin search (fuzzy, fast)
#   Ctrl+\  = atuin native UI (stats, filters, full-featured)
#
# Within fzf search:
#   Ctrl+D  = filter to current directory
#   Ctrl+R  = show all history (reset filter)
#   Enter   = execute command
#   Tab     = insert command (edit before running)

atuin-setup() {
    if ! which atuin &> /dev/null; then return 1; fi

    # Tell atuin not to bind keys (we handle it ourselves)
    export ATUIN_NOBIND="true"

    # Initialize atuin
    eval "$(atuin init zsh)"

    # Bind Ctrl+\ to atuin's native search UI
    # (Keeps Ctrl+E free for standard "end of line")
    bindkey '^\\' _atuin_search_widget

    # Create fzf-based atuin history widget
    fzf-atuin-history-widget() {
        local selected
        setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null

        # Run atuin search and pipe to fzf
        # Uses FZF_DEFAULT_OPTS from .fzf.zsh for Nord theme colors
        selected=$(atuin search --cmd-only | fzf \
            --height=80% \
            --layout=reverse \
            --tac \
            --tiebreak=index \
            --query="${LBUFFER}" \
            --no-multi \
            --no-sort \
            --header="ctrl-d: directory │ ctrl-r: all │ tab: edit │ enter: run" \
            --header-first \
            --bind="ctrl-d:reload(atuin search --cmd-only -c $PWD)+change-header(filtered: $PWD)" \
            --bind="ctrl-r:reload(atuin search --cmd-only)+change-header(all history)" \
            --bind="tab:accept" \
        )
        local ret=$?

        if [ -n "$selected" ]; then
            LBUFFER="${selected}"
        fi

        zle reset-prompt
        return $ret
    }

    # Register the widget
    zle -N fzf-atuin-history-widget

    # Bind Ctrl+R to our fzf+atuin widget
    bindkey '^R' fzf-atuin-history-widget
}

atuin-setup
