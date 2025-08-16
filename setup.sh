#!/bin/bash

# ABOUTME: Setup script for dotfiles installation using Stow
# ABOUTME: Installs dependencies, deploys configurations, and sets up tmux plugins

set -e

echo "🏠 Setting up dotfiles..."

# Check if we're in the right directory
if [[ ! -f "setup.sh" ]]; then
    echo "❌ Error: Please run this script from the dotfiles directory"
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for current session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Install Stow if not already installed
if ! command -v stow &> /dev/null; then
    echo "🔗 Installing GNU Stow..."
    brew install stow
fi

# Install required packages
echo "📦 Installing required packages..."
brew install starship zsh-autosuggestions zsh-syntax-highlighting fzf z

# Deploy dotfiles using Stow
echo "🔗 Deploying dotfiles with Stow..."
stow ag git vim zsh tmux claude

# Source the new zsh configuration
echo "🐚 Sourcing zsh configuration..."
if [[ -f "$HOME/.zshrc" ]]; then
    source "$HOME/.zshrc" || true
fi

# Setup tmux plugins
echo "🖥️  Setting up tmux plugins..."
if command -v tmux &> /dev/null; then
    # Install tmux plugin manager plugins
    if [[ -f "$HOME/.tmux.conf" ]]; then
        echo "Installing tmux plugins (this may take a moment)..."
        # Start tmux in detached mode and install plugins
        tmux new-session -d -s dotfiles-setup
        tmux send-keys -t dotfiles-setup C-a I
        sleep 3
        tmux kill-session -t dotfiles-setup || true
    fi
else
    echo "⚠️  tmux not found. Install with: brew install tmux"
fi

echo "✅ Dotfiles setup complete!"
echo ""
echo "🎉 Next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. If tmux plugins didn't install automatically, start tmux and press Ctrl-A + I"
echo "3. Configure 1Password CLI for credential management"
echo ""
echo "📁 Deployed packages: ag, git, vim, zsh, tmux, claude"