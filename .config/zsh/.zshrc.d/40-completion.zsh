#!/usr/bin/env zsh

# Helper function for safe sourcing with warnings
safe_source() {
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "Warning: Missing config file: $1" >&2
    fi
}

# Completion configuration
# compinit is handled in completion.zsh
_comp_options+=(globdots) # With hidden files
safe_source "$ZDOTDIR/completion.zsh"