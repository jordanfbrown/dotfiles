# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Environment

### Platform
- macOS
- Uses GNU Stow for dotfile management
- Requires Homebrew for package management

### Key Dependencies
- starship
- zsh-autosuggestions
- zsh-syntax-highlighting
- fzf
- z
- tmux
- 1Password CLI (for credential management)

## Common Commands

### Setup and Installation
```bash
# Initial setup
./setup.sh

# Deploy specific package configurations
stow ag git vim zsh tmux claude

# Source zsh configuration
source ~/.zshrc
```

### Tmux Plugin Management
```bash
# Install tmux plugins 
# After starting tmux, press Ctrl-A + I (or configured prefix + I)
```

## Deployment Strategy

### Configuration Deployment
- Uses GNU Stow to symlink configuration files
- Configured packages: ag, git, vim, zsh, tmux, claude
- Configuration files should maintain modular, stow-friendly structure

## Security Considerations
- Uses 1Password CLI for credential management
- No secrets hardcoded in configuration files
- Requires manual credential setup after initial installation

## Development Workflow
- All configuration changes should be made in respective package directories
- Use `stow` to deploy changes
- Verify changes by sourcing configuration files and testing interactively