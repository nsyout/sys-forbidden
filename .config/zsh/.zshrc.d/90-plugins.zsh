#!/usr/bin/env zsh

# Helper function for safe sourcing with warnings
safe_source() {
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "Warning: Missing config file: $1" >&2
    fi
}

# Prompt - Using Starship instead of custom prompt
eval "$(starship init zsh)"

# zoxide
eval "$(zoxide init zsh)"

# Plugin loading - order matters for some plugins

# Load utility plugins first
safe_source "$ZDOTDIR/plugins/open_command.zsh"
safe_source "$ZDOTDIR/plugins/bd/bd.zsh"
safe_source "$ZDOTDIR/plugins/smartdots/smartdots.zsh"
safe_source "$ZDOTDIR/plugins/which-key/which-key.zsh"
safe_source "$ZDOTDIR/plugins/gitit.zsh"

# Load enhancement plugins
safe_source "$ZDOTDIR/plugins/zsh-you-should-use/you-should-use.plugin.zsh"

# Syntax highlighting - Should be at the end of all plugins
safe_source "$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"