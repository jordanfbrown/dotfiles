# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Setup

```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## Manual Setup

### Prerequisites

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Stow
brew install stow

# Install required packages
brew install starship zsh-autosuggestions zsh-syntax-highlighting fzf z
```

### Installation

1. Clone this repository:
   ```bash
   git clone <repository-url> ~/dotfiles
   cd ~/dotfiles
   ```

2. Deploy configurations using Stow:
   ```bash
   stow ag git vim zsh tmux claude
   ```

3. Install tmux plugins:
   ```bash
   # Start tmux and press prefix + I to install plugins
   tmux
   # Press Ctrl-A + I (or your prefix key + I)
   ```

## Packages

- **ag**: Silver Searcher ignore patterns
- **git**: Git configuration and aliases
- **vim**: Vim configuration
- **zsh**: Zsh configuration with Starship prompt
- **tmux**: Tmux configuration with plugins
- **claude**: Claude.md documentation

## Features

### Zsh Configuration
- **Starship prompt** for beautiful terminal styling
- **Minimal setup** replacing Oh My Zsh for performance
- **Smart completion** with caching
- **Git aliases** for common operations
- **FZF integration** for fuzzy finding
- **Z directory jumping** for smart navigation
- **History optimization** with 1M command history

### Tmux Configuration
- **Plugin manager** (TPM) for easy plugin management
- **Session resurrection** to restore tmux sessions
- **Sensible defaults** for better tmux experience

### Git Configuration
- Custom aliases and settings
- Managed via Stow for easy version control

## Security

This repository uses 1Password CLI for credential management. No secrets are hardcoded in configuration files.

## Requirements

- macOS
- Homebrew
- GNU Stow
- 1Password CLI (for credential management)