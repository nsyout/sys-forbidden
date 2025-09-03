#!/usr/bin/env zsh

# Helper function for safe sourcing with warnings
safe_source() {
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "Warning: Missing config file: $1" >&2
    fi
}

# fzf configuration
if [ $(command -v "fzf") ]; then
    source $ZDOTDIR/fzf.zsh
fi

# fzf utilities
safe_source "$ZDOTDIR/plugins/fzf-utils/fzf-utils.zsh"