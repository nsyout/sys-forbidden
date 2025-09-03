#!/usr/bin/env bash
# macOS Bootstrap Script - Initial system setup for fresh installations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Output helpers
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step() { echo -e "\n${BLUE}==>${NC} $1\n"; }

# Verify we're on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    error "This script is for macOS only!"
fi

# Main bootstrap function
main() {
    cat << EOF
╔══════════════════════════════════════════╗
║     macOS BOOTSTRAP SCRIPT               ║
║     Fresh System Setup                   ║
╚══════════════════════════════════════════╝
EOF

    # Ask for administrator password upfront
    info "Requesting administrator privileges..."
    sudo -v

    # Keep sudo alive
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    # System Preferences
    step "Configuring System Preferences"
    
    # Finder preferences
    info "Setting Finder preferences..."
    defaults write com.apple.finder ShowPathbar -bool true
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    defaults write com.apple.finder AppleShowAllFiles -bool false
    
    # Dock preferences
    info "Configuring Dock..."
    defaults write com.apple.dock autohide -bool true
    defaults write com.apple.dock autohide-delay -float 0.1
    defaults write com.apple.dock autohide-time-modifier -float 0.5
    defaults write com.apple.dock tilesize -int 48
    defaults write com.apple.dock show-recents -bool false
    defaults write com.apple.dock minimize-to-application -bool true
    
    # Mission Control
    info "Configuring Mission Control..."
    defaults write com.apple.dock mru-spaces -bool false
    
    # Trackpad
    info "Configuring Trackpad..."
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
    defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
    defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
    
    # Disable "natural" scrolling (set to false for traditional scrolling)
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
    
    # Keyboard
    info "Configuring Keyboard..."
    defaults write NSGlobalDomain KeyRepeat -int 2
    defaults write NSGlobalDomain InitialKeyRepeat -int 15
    defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
    
    # Screenshot location
    info "Setting screenshot location..."
    mkdir -p "$HOME/Screenshots"
    defaults write com.apple.screencapture location -string "$HOME/Screenshots"
    defaults write com.apple.screencapture disable-shadow -bool true
    
    # Terminal
    info "Configuring Terminal..."
    defaults write com.apple.terminal StringEncodings -array 4
    
    # TextEdit
    info "Configuring TextEdit..."
    defaults write com.apple.TextEdit RichText -int 0
    defaults write com.apple.TextEdit PlainTextEncoding -int 4
    defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
    
    # Disable animations (optional - speeds up UI)
    info "Optimizing UI responsiveness..."
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    defaults write com.apple.dock expose-animation-duration -float 0.1
    defaults write -g QLPanelAnimationDuration -float 0
    
    # Install Xcode Command Line Tools
    step "Installing Xcode Command Line Tools"
    if ! xcode-select -p &>/dev/null; then
        info "Installing Xcode Command Line Tools..."
        xcode-select --install
        
        # Wait for installation
        until xcode-select -p &>/dev/null; do
            sleep 5
        done
        info "Xcode Command Line Tools installed"
    else
        info "Xcode Command Line Tools already installed"
    fi
    
    # Create standard directories
    step "Creating standard directories"
    mkdir -p "$HOME/Developer"
    mkdir -p "$HOME/projects/repos"
    mkdir -p "$HOME/projects/forks"
    mkdir -p "$HOME/projects/playground"
    mkdir -p "$HOME/projects/fonts"
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.cache"
    
    # SSH Setup
    step "Setting up SSH"
    if [[ ! -d "$HOME/.ssh" ]]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        info "SSH directory created"
    fi
    
    if [[ ! -f "$HOME/.ssh/config" ]]; then
        cat > "$HOME/.ssh/config" << 'SSHEOF'
# SSH Configuration
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
    
# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
SSHEOF
        chmod 600 "$HOME/.ssh/config"
        info "SSH config created"
    fi
    
    # Install Homebrew
    step "Installing Homebrew"
    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ -d "/opt/homebrew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        else
            eval "$(/usr/local/bin/brew shellenv)"
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$HOME/.zprofile"
        fi
        info "Homebrew installed"
    else
        info "Homebrew already installed"
        brew update
    fi
    
    # Disable Homebrew analytics
    info "Disabling Homebrew analytics..."
    brew analytics off
    
    # Install essential tools
    step "Installing essential tools"
    info "Installing core utilities..."
    brew install \
        git \
        stow \
        coreutils \
        findutils \
        gnu-sed \
        grep \
        wget \
        curl \
        jq \
        gh
    
    # Restart affected applications
    step "Restarting affected applications"
    for app in "Finder" "Dock" "SystemUIServer"; do
        killall "${app}" &> /dev/null || true
    done
    
    # Success message
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     BOOTSTRAP COMPLETED SUCCESSFULLY!    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo
    
    # Offer to run setup.sh
    echo
    read -p "Would you like to run the dotfiles setup now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Running setup.sh..."
        # Get the directory where this script is located
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        "$SCRIPT_DIR/setup.sh"
    else
        info "You can run ./scripts/setup.sh later to:"
        echo "  - Deploy dotfiles configuration"
        echo "  - Configure hostname"
        echo "  - Configure git settings"
        echo "  - Install packages from Brewfile"
        echo
        warn "Some changes require a logout/restart to take effect"
    fi
}

# Run main function
main "$@"