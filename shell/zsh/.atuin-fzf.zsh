#!/bin/zsh
# fzf + atuin integration
# Based on: https://news.ycombinator.com/item?id=35256206
# Provides fzf's fuzzy search experience with atuin's history management

atuin-setup() {
    if ! which atuin &> /dev/null; then return 1; fi

    # Bind ctrl-e to atuin's native search
    bindkey '^E' _atuin_search_widget

    # Tell atuin not to bind keys (we'll do it ourselves)
    export ATUIN_NOBIND="true"

    # Initialize atuin
    eval "$(atuin init zsh)"

    # Create fzf-based atuin history widget
    fzf-atuin-history-widget() {
        local selected num
        setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null

        # Atuin search options
        local atuin_opts="--cmd-only"

        # fzf options
        local fzf_opts=(
            --height=${FZF_TMUX_HEIGHT:-80%}
            --tac
            "-n2..,.."
            --tiebreak=index
            "--query=${LBUFFER}"
            "+m"
            "--bind=ctrl-d:reload(atuin search $atuin_opts -c $PWD),ctrl-r:reload(atuin search $atuin_opts)"
        )

        # Run atuin search and pipe to fzf
        selected=$(
            eval "atuin search ${atuin_opts}" | fzf "${fzf_opts[@]}"
        )
        local ret=$?

        if [ -n "$selected" ]; then
            # The += lets it insert at current pos instead of replacing
            LBUFFER+="${selected}"
        fi

        zle reset-prompt
        return $ret
    }

    # Register the widget
    zle -N fzf-atuin-history-widget

    # Bind ctrl-r to our fzf+atuin widget
    bindkey '^R' fzf-atuin-history-widget
}

atuin-setup
