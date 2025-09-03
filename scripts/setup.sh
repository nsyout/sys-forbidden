#!/usr/bin/env bash
# Universal dotfiles installation script

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

# Configuration
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/kailubyte/dotfiles-rework.git}"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        *)       error "Unsupported OS: $(uname -s). This script is for macOS only." ;;
    esac
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Install dependencies for macOS
install_dependencies() {
    step "Installing dependencies for macOS"
    
    # Install Homebrew if not present
    if ! command_exists brew; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ -d "/opt/homebrew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Install required tools
    info "Installing required tools..."
    brew install git stow fzf ripgrep bat zoxide starship neovim tmux
}

# Clone or update dotfiles repository
setup_dotfiles() {
    step "Setting up dotfiles repository"
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        info "Dotfiles directory exists. Updating..."
        cd "$DOTFILES_DIR"
        git pull origin main || git pull origin master
    else
        info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        cd "$DOTFILES_DIR"
    fi
    
    # Initialize submodules if any
    if [[ -f .gitmodules ]]; then
        info "Initializing submodules..."
        git submodule update --init --recursive
    fi
}

# Backup existing configurations
backup_configs() {
    step "Backing up existing configurations"
    
    local files_to_backup=(
        "$HOME/.zshrc"
        "$HOME/.zshenv"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.gitconfig"
        "$HOME/.config"
    )
    
    local backed_up=0
    for file in "${files_to_backup[@]}"; do
        if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
            mkdir -p "$BACKUP_DIR"
            cp -r "$file" "$BACKUP_DIR/" 2>/dev/null || true
            info "Backed up: $(basename "$file")"
            ((backed_up++))
        fi
    done
    
    if [[ $backed_up -gt 0 ]]; then
        info "Backed up $backed_up items to $BACKUP_DIR"
    else
        info "No existing configurations to backup"
    fi
}

# Clean up existing conflicting files
cleanup_conflicts() {
    step "Cleaning up conflicting files"
    
    info "Removing broken symlinks and conflicting files..."
    
    # Remove broken symlinks in home directory
    find "$HOME" -maxdepth 1 -name ".*" -type l -exec test ! -e {} \; -delete 2>/dev/null || true
    
    # Remove broken symlinks in .config
    if [[ -d "$HOME/.config" ]]; then
        find "$HOME/.config" -maxdepth 2 -type l -exec test ! -e {} \; -delete 2>/dev/null || true
    fi
    
    # Clean up specific known conflicts
    local conflicts=(
        "$HOME/.config/plugins"
        "$HOME/.config/prompt" 
        "$HOME/.config/.zshrc.d"
        "$HOME/.config/*.zsh"
    )
    
    for conflict in "${conflicts[@]}"; do
        if [[ -e "$conflict" ]] && [[ ! -L "$conflict" || ! -e "$(readlink "$conflict" 2>/dev/null)" ]]; then
            info "Removing conflict: $conflict"
            rm -rf "$conflict" 2>/dev/null || true
        fi
    done
}

# Deploy configurations using stow
deploy_configs() {
    step "Deploying configurations"
    
    cd "$DOTFILES_DIR"
    
    # Clean up conflicts first
    cleanup_conflicts
    
    # Deploy root-level configs (.zshenv, etc)
    info "Deploying root-level configs..."
    
    # Try clean stow first
    if stow --target="$HOME" . 2>/dev/null; then
        info "✓ Root configs deployed successfully"
    else
        warn "Conflicts detected in root configs"
        info "Attempting to resolve conflicts..."
        
        # Remove existing symlinks and try again
        stow --delete --target="$HOME" . 2>/dev/null || true
        
        if stow --target="$HOME" . 2>/dev/null; then
            info "✓ Root configs deployed after cleanup"
        else
            read -p "Override existing files? (y/N): " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                # Create backup of conflicting files
                for file in .zshenv .gitconfig .tmux.conf; do
                    if [[ -f "$HOME/$file" && ! -L "$HOME/$file" ]]; then
                        cp "$HOME/$file" "$BACKUP_DIR/" 2>/dev/null || true
                        rm "$HOME/$file"
                    fi
                done
                
                if stow --target="$HOME" . 2>/dev/null; then
                    info "✓ Root configs deployed with backup"
                else
                    warn "Failed to deploy root configs"
                fi
            else
                warn "Skipping root configs"
            fi
        fi
    fi
    
    info "Configuration deployment complete"
}

# Install additional packages
install_packages() {
    step "Installing additional packages"
    
    if [[ ! -f "$DOTFILES_DIR/Brewfile" ]]; then
        warn "No Brewfile found at $DOTFILES_DIR/Brewfile"
        return
    fi
    
    info "Installing packages from Brewfile..."
    cd "$DOTFILES_DIR" && brew bundle
}

# Configure shell
configure_shell() {
    step "Configuring shell"
    
    # Set Zsh as default shell if not already
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Setting Zsh as default shell..."
        
        # Add zsh to valid shells if needed
        if ! grep -q "$(which zsh)" /etc/shells; then
            echo "$(which zsh)" | sudo tee -a /etc/shells
        fi
        
        # Change default shell
        chsh -s "$(which zsh)" || warn "Failed to set Zsh as default shell"
    else
        info "Zsh is already the default shell"
    fi
}

# Configure hostname
configure_hostname() {
    step "Configuring Hostname (optional)"
    
    echo "Current hostname: $(hostname)"
    read -p "Enter new hostname (leave blank to keep current): " new_hostname
    
    if [[ -n "$new_hostname" ]]; then
        info "Setting hostname to: $new_hostname"
        
        # Set all the hostname types on macOS
        sudo scutil --set ComputerName "$new_hostname"
        sudo scutil --set HostName "$new_hostname"
        sudo scutil --set LocalHostName "$new_hostname"
        
        # Flush DNS cache
        sudo dscacheutil -flushcache
        
        info "Hostname configured successfully"
        warn "You may need to restart Terminal for changes to take effect"
    else
        info "Keeping current hostname"
    fi
}

# Configure git
configure_git() {
    step "Configuring Git (optional)"
    
    echo "Would you like to configure git? (leave blank to skip)"
    echo
    
    read -p "Git user name: " git_name
    if [[ -n "$git_name" ]]; then
        git config --global user.name "$git_name"
        
        read -p "Git email: " git_email
        if [[ -n "$git_email" ]]; then
            git config --global user.email "$git_email"
        fi
        
        read -p "SSH signing key path (e.g., ~/.ssh/id_ed25519.pub): " git_signing_key
        if [[ -n "$git_signing_key" ]]; then
            git config --global user.signingkey "$git_signing_key"
            git config --global gpg.format ssh
            git config --global gpg.ssh.program "/opt/homebrew/bin/ssh-keygen"
            git config --global commit.gpgsign true
        fi
        
        # Always set default branch to main
        git config --global init.defaultBranch main
        
        info "Git configured successfully"
    else
        info "Skipping git configuration"
    fi
}

# Post-installation tasks
post_install() {
    step "Running post-installation tasks"
    
    # Fix Zsh completion permissions for Homebrew
    if [[ -d "/opt/homebrew/share" ]]; then
        info "Fixing Homebrew directory permissions for Zsh..."
        chmod -R go-w /opt/homebrew/share 2>/dev/null || true
    fi
    
    # Install vim-plug for Neovim
    if command_exists nvim; then
        info "Setting up Neovim..."
        sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' 2>/dev/null || true
    fi
    
    # Install TPM for tmux
    if command_exists tmux; then
        info "Setting up tmux plugin manager..."
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm 2>/dev/null || true
    fi
    
    # Install FZF key bindings
    if command_exists fzf && command_exists brew; then
        info "Setting up FZF..."
        "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash 2>/dev/null || true
    fi
}

# Setup Firefox configuration
setup_firefox() {
    step "Setting up Firefox configuration"
    
    local firefox_repo="https://github.com/nsyout/firefox-config.git"
    local firefox_dir="$HOME/projects/repos/firefox-config"
    
    # Clone or update Firefox config repo
    if [[ -d "$firefox_dir" ]]; then
        info "Updating existing Firefox config repository..."
        cd "$firefox_dir" && git remote set-url origin "$firefox_repo" && git pull || warn "Failed to update Firefox config"
    else
        info "Cloning Firefox config repository..."
        git clone "$firefox_repo" "$firefox_dir" || {
            warn "Failed to clone Firefox config repository"
            warn "You may need to set this up manually or check the repository URL"
            return
        }
    fi
    
    # Run deploy script if it exists
    if [[ -f "$firefox_dir/deploy.sh" ]]; then
        info "Running Firefox deployment script..."
        cd "$firefox_dir" && ./deploy.sh || warn "Firefox deployment script encountered issues"
    else
        warn "deploy.sh not found in Firefox config repo"
        info "Firefox config available at: $firefox_dir"
        info "Run manually: cd $firefox_dir && ./deploy.sh"
    fi
}

# Main installation flow
main() {
    cat << EOF
╔══════════════════════════════════════════╗
║     macOS DOTFILES INSTALLATION SCRIPT   ║
╚══════════════════════════════════════════╝
EOF
    
    # Verify we're on macOS
    OS=$(detect_os)
    info "Running on: $OS"
    
    # Confirm installation
    echo
    read -p "This will install dotfiles for macOS. Continue? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    
    # Run installation steps
    install_dependencies
    setup_dotfiles
    backup_configs
    deploy_configs
    install_packages
    configure_shell
    configure_hostname
    configure_git
    setup_firefox
    post_install
    
    # Success message
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     INSTALLATION COMPLETED SUCCESSFULLY! ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo
    info "Please restart your terminal or run: source ~/.zshenv && source ~/.zshrc"
    info "Backup of old configurations saved to: $BACKUP_DIR"
    
    # Run verification
    echo
    if [[ -f "$DOTFILES_DIR/scripts/verify.sh" ]]; then
        info "Running installation verification..."
        "$DOTFILES_DIR/scripts/verify.sh"
    fi
}

# Run main function
main "$@"