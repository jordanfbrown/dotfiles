# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Setup

```bash
git clone git@github.com:jordanfbrown/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

The setup script installs Homebrew dependencies, deploys all packages via Stow, and configures tmux plugins.

## Packages

| Package | Deploys | Description |
|---------|---------|-------------|
| `ag` | `~/.ignore` | Silver Searcher ignore patterns |
| `claude` | `~/.claude/CLAUDE.md` | Global Claude Code instructions |
| `git` | `~/.gitconfig`, `~/.gitignore` | Git config with 1Password SSH signing, difftastic |
| `tmux` | `~/.tmux.conf`, `~/.tmux/` | Tmux with TPM, Ctrl-X prefix, vi keys |
| `vim` | `~/.vimrc` | Vim configuration |
| `zsh` | `~/.zshrc`, `~/.zprofile`, etc. | Zsh with Starship, FZF, z, worktree functions |

## Key Features

### Git Worktree Management

Custom functions for managing git worktrees across `~/wealthsimple` repos:

```bash
wt           # FZF picker for all worktrees
wt 123       # Switch to jb-hhmm-123 (or create it)
wtd          # FZF picker to delete a worktree
wtd 123      # Delete jb-hhmm-123
```

These auto-open the correct IDE, copy untracked files (`.env`, `.envrc`, `mise.toml`), and handle `node_modules`.

### Git Aliases

```bash
g, ga, gaa, gb, gc, gco, gd, gl, gp, gpf, gst  # Common git shortcuts
b 123        # Create/switch to branch jb/hhmm-123
gcj          # Commit using Jira ticket description
nxa test     # Run nx affected from fork point
```

### Tmux

- **Prefix**: `Ctrl-X` (not default Ctrl-B)
- **Reload config**: `prefix + r`
- **Install plugins**: `prefix + I`
- **Vi keys** in copy mode, mouse enabled
- **Plugins**: sensible, resurrect, continuum

## Manual Setup

If you prefer not to use `setup.sh`:

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install stow starship zsh-autosuggestions zsh-syntax-highlighting fzf z tmux

# Deploy packages
cd ~/dotfiles
stow ag git vim zsh tmux claude

# Install tmux plugins (start tmux, then Ctrl-X + I)
```

## Requirements

- macOS (uses Homebrew, APFS copy-on-write)
- 1Password CLI for credential management
