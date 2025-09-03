#!/usr/bin/env bash
# Dotfiles update script
# Updates dotfiles repository, packages, and checks for system updates

set -e

# Configuration
DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

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

# Track warnings for summary
WARNINGS=()

# Check for macOS system updates
check_system_updates() {
    step "Checking for macOS system updates"
    
    local updates
    set +e
    updates=$(softwareupdate -l 2>&1)
    local exit_code=$?
    set -e
    
    if [[ $exit_code -ne 0 ]]; then
        warn "Unable to check for macOS updates"
        return 0
    fi
    
    if echo "$updates" | grep -q "No new software available"; then
        info "macOS is up to date"
    elif echo "$updates" | grep -q -E "^\s*\*.*"; then
        warn "macOS system updates are available:"
        echo "$updates" | grep -E "^\s*\*.*"
        echo
        warn "Run 'sudo softwareupdate -i -a' to install updates"
        WARNINGS+=("macOS system updates available")
    else
        info "macOS is up to date"
    fi
}

# Update dotfiles repository
update_dotfiles_repo() {
    step "Updating dotfiles repository"
    
    if [[ ! -d "$DOTFILES/.git" ]]; then
        error "Dotfiles directory is not a git repository: $DOTFILES"
    fi
    
    cd "$DOTFILES"
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        warn "Uncommitted changes detected in dotfiles repository"
        git status --short
        echo
        read -p "Continue with update? (y/n) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    # Pull latest changes
    info "Pulling latest changes..."
    git pull origin main || git pull origin master || error "Failed to pull latest changes"
    
    info "Repository updated successfully"
}

# Re-stow dotfiles
restow_dotfiles() {
    step "Re-linking dotfiles"
    
    cd "$DOTFILES"
    
    if ! command -v stow &>/dev/null; then
        error "GNU Stow is not installed"
    fi
    
    # Re-deploy root-level configs
    info "Re-deploying root-level configs..."
    
    # Delete existing symlinks (safe - only removes symlinks)
    stow --delete --target="$HOME" --no-folding --ignore='^\.config' . 2>/dev/null || true
    
    # Try clean stow
    if ! stow --target="$HOME" --no-folding --ignore='^\.config' -v . 2>/dev/null; then
        warn "Conflicts detected in root configs"
        read -p "Override existing files? (y/N): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            stow --target="$HOME" --no-folding --ignore='^\.config' --override=".*" -v . || warn "Failed to deploy root configs"
        else
            warn "Skipping root configs"
        fi
    fi
    
    # Re-deploy each config package separately
    local configs=(aerospace ghostty git nvim tmux zsh)
    
    for config in "${configs[@]}"; do
        if [[ ! -d ".config/$config" ]]; then
            continue
        fi
        
        info "Re-deploying $config..."
        
        # Create .config directory if it doesn't exist
        mkdir -p "$HOME/.config"
        
        # Delete existing symlinks for this package
        stow --delete --target="$HOME/.config" --dir=".config" --no-folding "$config" 2>/dev/null || true
        
        # Try clean stow
        if stow --target="$HOME/.config" --dir=".config" --no-folding -v "$config" 2>/dev/null; then
            info "  ✓ $config updated"
        else
            # Handle conflicts for this specific package
            warn "  Conflicts detected in $config"
            read -p "  Override existing $config files? (y/N): " choice
            
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                stow --target="$HOME/.config" --dir=".config" --no-folding --override=".*" -v "$config"
                if [[ $? -eq 0 ]]; then
                    info "  ✓ $config updated with overrides"
                else
                    error "  ✗ Failed to update $config"
                fi
            else
                warn "  ✗ Skipping $config"
            fi
        fi
    done
    
    info "Dotfiles re-linking complete"
}

# Update Homebrew packages
update_packages() {
    step "Updating Homebrew packages"
    
    if ! command -v brew &>/dev/null; then
        warn "Homebrew not installed, skipping package updates"
        return 0
    fi
    
    # Update Homebrew
    info "Updating Homebrew..."
    brew update || warn "Failed to update Homebrew"
    
    # Upgrade packages
    info "Upgrading installed packages..."
    brew upgrade || warn "Some packages failed to upgrade"
    
    # Update from Brewfile if it exists
    if [[ -f "$DOTFILES/Brewfile" ]]; then
        info "Installing/updating packages from Brewfile..."
        cd "$DOTFILES" && brew bundle || warn "Some packages failed to install"
    fi
    
    # Cleanup
    info "Cleaning up Homebrew..."
    brew cleanup --prune=all || warn "Homebrew cleanup had issues"
    
    # Check health
    info "Checking Homebrew health..."
    if ! brew doctor; then
        warn "brew doctor found issues (see above)"
        WARNINGS+=("Homebrew has issues - run 'brew doctor'")
    else
        info "Homebrew is healthy"
    fi
}

# Update Firefox configuration
update_firefox() {
    step "Updating Firefox configuration"
    
    local firefox_dir="$HOME/projects/repos/firefox-config"
    
    if [[ -d "$firefox_dir" ]]; then
        info "Updating Firefox config repository..."
        cd "$firefox_dir" || return
        
        # Check for uncommitted changes
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            warn "Uncommitted changes in Firefox config repository"
            git status --short
            echo
            read -p "Continue with update? (y/n) " -n 1 -r
            echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && return
        fi
        
        # Pull latest changes
        git pull origin main || git pull origin master || warn "Failed to update Firefox config"
        
        # Run deploy script to update Firefox profiles
        if [[ -f "deploy.sh" ]]; then
            info "Running Firefox deployment script to update profiles..."
            ./deploy.sh || warn "Firefox deployment script had issues"
        else
            info "deploy.sh not found, skipping Firefox profile update"
        fi
    else
        info "Firefox config not found, skipping"
    fi
}

# Reload shell configuration
reload_shell() {
    step "Reloading shell configuration"
    
    # Can't source zsh configs in bash, just notify user
    info "Shell configuration updated"
    info "Please restart your terminal or run: exec zsh"
}

# Main function
main() {
    cat << EOF
╔══════════════════════════════════════════╗
║        DOTFILES UPDATE SCRIPT            ║
╚══════════════════════════════════════════╝
EOF
    
    # Check we're on macOS
    if [[ "$(uname -s)" != "Darwin" ]]; then
        error "This script is for macOS only"
    fi
    
    info "Starting dotfiles update..."
    
    # Run updates
    check_system_updates
    update_dotfiles_repo
    restow_dotfiles
    update_packages
    update_firefox
    reload_shell
    
    # Success
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      UPDATE COMPLETED SUCCESSFULLY!      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo
    
    # Summary of warnings
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠ ATTENTION REQUIRED:${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo -e "  ${YELLOW}•${NC} $warning"
        done
        echo
        
        # Specific nag for macOS updates
        if [[ " ${WARNINGS[@]} " =~ "macOS system updates available" ]]; then
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${YELLOW}  UPDATE YOUR MAC!${NC}"
            echo -e "${YELLOW}  Run: sudo softwareupdate -i -a${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo
        fi
    else
        info "✓ Everything is up to date!"
    fi
    
    info "Restart your terminal if you see any issues"
}

# Run main function
main "$@"