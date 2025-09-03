#!/usr/bin/env bash
# Verify dotfiles installation

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; ((ERRORS++)); }
warn() { echo -e "${YELLOW}⚠${NC} $1"; ((WARNINGS++)); }

echo "=== Dotfiles Installation Verification ==="
echo

# Check symlinks
echo "Checking symlinks:"
[[ -L "$HOME/.zshenv" ]] && pass ".zshenv linked" || fail ".zshenv not linked"

# Check zsh config structure
if [[ -L "$HOME/.config/zsh" ]]; then
    pass ".config/zsh directory linked to $(readlink "$HOME/.config/zsh")"
elif [[ -d "$HOME/.config/zsh" ]]; then
    if [[ -f "$HOME/.config/zsh/.zshrc" ]]; then
        pass ".config/zsh/.zshrc exists"
    else
        fail ".config/zsh/.zshrc missing"
    fi
else
    fail ".config/zsh not found"
fi

[[ -L "$HOME/.config/ghostty" ]] && pass ".config/ghostty linked" || warn ".config/ghostty not linked"
[[ -L "$HOME/.config/aerospace" ]] && pass ".config/aerospace linked" || warn ".config/aerospace not linked"
echo

# Check key commands
echo "Checking installed tools:"
command -v brew &>/dev/null && pass "Homebrew" || fail "Homebrew"
command -v git &>/dev/null && pass "Git" || fail "Git"
command -v stow &>/dev/null && pass "Stow" || fail "Stow"
command -v zsh &>/dev/null && pass "Zsh" || fail "Zsh"
command -v nvim &>/dev/null && pass "Neovim" || fail "Neovim"
command -v tmux &>/dev/null && pass "Tmux" || fail "Tmux"
command -v fzf &>/dev/null && pass "FZF" || fail "FZF"
command -v rg &>/dev/null && pass "Ripgrep" || fail "Ripgrep"
command -v bat &>/dev/null && pass "Bat" || fail "Bat"
command -v lsd &>/dev/null && pass "LSD" || fail "LSD"
command -v zoxide &>/dev/null && pass "Zoxide" || fail "Zoxide"
command -v starship &>/dev/null && pass "Starship" || fail "Starship"
command -v gh &>/dev/null && pass "GitHub CLI" || fail "GitHub CLI"
echo

# Check shell
echo "Checking shell configuration:"
[[ "$SHELL" == *"zsh"* ]] && pass "Zsh is default shell" || warn "Zsh not default shell"

# Test zsh loading
if command -v zsh &>/dev/null; then
    if ZDOTDIR="$HOME/.config/zsh" zsh -c 'source ~/.zshenv && source $ZDOTDIR/.zshrc' &>/dev/null; then
        pass "Zsh configuration loads without errors"
    else
        fail "Zsh configuration has errors"
        echo "Error details:"
        ZDOTDIR="$HOME/.config/zsh" zsh -c 'source ~/.zshenv && source $ZDOTDIR/.zshrc' 2>&1 | head -3
    fi
fi

[[ -f "$HOME/.config/zsh/.zshrc" ]] && pass ".zshrc exists" || fail ".zshrc missing"
[[ -d "$HOME/.config/zsh/.zshrc.d" ]] && pass "Modular zsh config exists" || fail "Modular zsh config missing"
[[ -d "$HOME/.config/zsh/plugins" ]] && pass "Zsh plugins installed" || fail "Zsh plugins missing"
echo

# Check Git config
echo "Checking Git configuration:"
git config --get user.name &>/dev/null && pass "Git user.name set" || warn "Git user.name not set"
git config --get user.email &>/dev/null && pass "Git user.email set" || warn "Git user.email not set"
git config --get init.defaultBranch &>/dev/null && pass "Git default branch set" || warn "Git default branch not set"
echo

# Check environment variables
echo "Checking environment variables:"
[[ -n "$ZDOTDIR" ]] && pass "ZDOTDIR set" || fail "ZDOTDIR not set"
[[ -n "$XDG_CONFIG_HOME" ]] && pass "XDG_CONFIG_HOME set" || fail "XDG_CONFIG_HOME not set"
[[ -n "$FZF_DEFAULT_COMMAND" ]] && pass "FZF configured" || warn "FZF not configured"
echo

# Check Homebrew analytics
echo "Checking privacy settings:"
brew analytics state 2>/dev/null | grep -q "disabled" && pass "Homebrew analytics disabled" || warn "Homebrew analytics enabled"
echo

# Check hostname
echo "System info:"
echo "  Hostname: $(hostname)"
echo "  Shell: $SHELL"
echo "  Homebrew: $(brew --prefix 2>/dev/null)"
echo

echo "=== Verification Complete ==="
echo

# Summary
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}✓ All checks passed! Your dotfiles are properly configured.${NC}"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}⚠ Verification completed with $WARNINGS warning(s).${NC}"
    echo -e "${YELLOW}  Your setup is functional but may need minor adjustments.${NC}"
    exit 0
else
    echo -e "${RED}✗ Verification failed with $ERRORS error(s) and $WARNINGS warning(s).${NC}"
    echo -e "${RED}  Please resolve the errors before using your dotfiles.${NC}"
    echo
    echo "Common fixes:"
    echo "• Re-run setup: ./scripts/setup.sh"
    echo "• Manual stow: stow --restow ."
    echo "• Check symlinks: ls -la ~/.config/"
    exit 1
fi