#!/usr/bin/env zsh

# Fix PATH order - ensure Homebrew comes before system paths
# Remove any duplicate /usr/bin and /usr/sbin entries first
PATH="${PATH/\/usr\/bin:/}"
PATH="${PATH/\/usr\/sbin:/}"

# Now rebuild PATH with correct order
if [[ -d "/opt/homebrew" ]]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH:/usr/bin:/bin:/usr/sbin:/sbin"
fi

fpath=($ZDOTDIR/plugins $fpath)

# Default editor for local and remote sessions
if [[ -n "$SSH_CONNECTION" ]]; then
  # on the server
  if command -v vim >/dev/null 2>&1; then
    export EDITOR='vim'
  else
    export EDITOR='vi'
  fi
else
  export EDITOR='nvim'
fi

# git SSH yubikey
export GIT_SSH_COMMAND="/opt/homebrew/bin/ssh"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"

# Node.js version from Homebrew
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"