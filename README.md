# macOS Dotfiles

A clean, modular dotfiles configuration for macOS with automated installation and modern CLI tools.

## Features

- **macOS Optimized**: Tailored specifically for macOS with Homebrew integration
- **Modular Architecture**: Clear separation between configurations
- **Modern Tools**: Configured for the latest CLI tools (ghostty, fzf, ripgrep, bat, zoxide, starship, etc.)
- **Firefox Integration**: Automated setup of privacy-hardened Firefox with arkenfox user.js
- **Zero Conflicts**: Whitelist approach prevents config pollution
- **Smart Installation**: Automated setup with dependency management
- **Aerospace WM**: Tiling window manager configuration included

## Structure

```
dotfiles/
├── .config/              # All configuration files
│   ├── zsh/             # Shell configuration
│   │   ├── .zshrc       # Modular zsh loader
│   │   ├── .zshrc.d/    # Modular config components
│   │   │   ├── 00-env.zsh      # Environment setup
│   │   │   ├── 05-settings.zsh # Zsh options and settings
│   │   │   ├── 10-aliases.zsh  # Shell aliases
│   │   │   ├── 20-functions.zsh# Custom functions
│   │   │   ├── 30-fzf.zsh      # FZF configuration
│   │   │   ├── 40-completion.zsh# Tab completion
│   │   │   └── 90-plugins.zsh  # Plugin loading
│   │   ├── plugins/     # Zsh plugins
│   │   └── ...
│   ├── aerospace/       # Tiling window manager
│   ├── ghostty/         # Terminal emulator
│   ├── git/             # Git configuration
│   ├── nvim/            # Neovim configuration
│   └── tmux/            # Tmux configuration
│
├── .zshenv              # Environment variables
├── .gitconfig           # Git configuration
├── Brewfile             # Homebrew package definitions
│
└── scripts/             # Installation and maintenance scripts
    ├── bootstrap.sh     # Fresh macOS setup script
    ├── setup.sh         # Dotfiles setup script
    ├── update.sh        # Update dotfiles and packages
    └── verify.sh        # Verify installation
```

## Installation

### Fresh macOS Setup

For a brand new macOS installation:

```bash
# Clone repository
git clone https://github.com/nsyout/sys-forbidden.git ~/.dotfiles
cd ~/.dotfiles

# Run bootstrap for system setup
./scripts/bootstrap.sh

# Install dotfiles
./scripts/setup.sh
```

### Existing System

```bash
# Clone and run installer
git clone https://github.com/nsyout/sys-forbidden.git ~/.dotfiles
cd ~/.dotfiles
./scripts/setup.sh
```

The setup script will:
1. Install Homebrew if not present
2. Install required tools (git, stow, etc.)
3. Backup existing configurations
4. Deploy configurations using GNU Stow
5. Install packages from Brewfile
6. Configure Zsh as default shell
7. Prompt for Git configuration (optional)
8. Clone and configure Firefox with arkenfox + custom overrides
9. Set up plugins and tools

## Firefox Configuration

The setup automatically clones and configures Firefox from [firefox-config](https://github.com/nsyout/firefox-config) repository:

- **Privacy hardening** via arkenfox user.js
- **Custom overrides** for usability (session restore, Kagi search, etc.)
- **Extension policies** auto-install uBlock Origin, 1Password, Kagi, and more
- **Flexoki theme** with dark/light variants
- **Automatic updates** via the `update` command

Firefox config is kept in `~/projects/repos/firefox-config/` for portability.

## Key Configurations

### Environment Variables (`.zshenv`)

- XDG Base Directory specification
- Editor preferences (Neovim)
- FZF configuration with Rose Pine theme
- Homebrew paths and settings
- SSH FIDO2 support via Homebrew OpenSSH
- GNU utilities paths
- Development paths (Go, Rust, Node, Python)


### Shell Configuration

**Modular Zsh setup**:
- Numbered configuration files in `.zshrc.d/` for ordered loading
- Starship prompt
- Syntax highlighting
- Auto-suggestions
- FZF integration with Rose Pine theme
- Smart directory navigation (zoxide, bd)
- Git utilities
- Custom aliases and functions

**Key aliases**:
- Modern CLI replacements (eza for ls, bat for cat)
- Git shortcuts
- Docker commands
- Safety nets (confirmation prompts)

## Customization

### Adding New Applications

1. Add configuration to `.config/`:
```bash
mkdir -p .config/newapp
# Add your config files
```

2. Update `.gitignore` if needed to track the files

3. Deploy with stow:
```bash
stow --restow .
```

### Local Overrides

Create `.zshrc.local` in your home directory for machine-specific settings:

```bash
# ~/.zshrc.local
export CUSTOM_VAR="value"
alias myalias="command"
```

## Updating

Use the `update` alias (or `dotupdate`) to update everything:

```bash
update
```

This will:
- Check for macOS system updates
- Pull latest dotfiles changes
- Update Homebrew packages
- Update Firefox configuration
- Re-link any new configs

## Package Management

### macOS (Homebrew)

Packages are defined in the `Brewfile` in the repository root:

```bash
# Install/update packages
cd ~/.dotfiles && brew bundle
```


## Manual Setup

If you prefer manual installation:

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Stow
brew install stow

# Clone repository
git clone https://github.com/nsyout/sys-forbidden.git ~/.dotfiles
cd ~/.dotfiles

# Deploy configurations
stow .
```


## Troubleshooting

### Stow Conflicts

If you get conflicts when running stow:

```bash
# Remove conflicting files (backup first!)
rm ~/.zshrc ~/.zshenv

# Re-run stow
stow --restow .
```


### Missing Commands

If commands are missing after installation:

```bash
# Reload environment
source ~/.zshenv
source ~/.config/zsh/.zshrc

# Check PATH
echo $PATH | tr ':' '\n'
```

## Related Projects

- **[sys-btw](https://github.com/nsyout/sys-btw)** - Arch Linux bootstrap and configuration

## Contributing

Feel free to fork and customize for your needs. PRs welcome for:
- Additional platform support
- New tool configurations
- Bug fixes
- Documentation improvements

## License

MIT - See LICENSE file for details