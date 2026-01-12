# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

```bash
# Initial setup (installs dependencies, deploys all packages)
./setup.sh

# Deploy specific packages
stow ag git vim zsh tmux claude

# Reload zsh after changes
source ~/.zshrc

# Tmux: Install plugins with Ctrl-X + I (prefix is Ctrl-X)
```

## Architecture

This repo uses GNU Stow to symlink dotfiles. Each top-level directory is a "package" that Stow deploys to `$HOME`:

```
dotfiles/
├── ag/          → ~/.ignore
├── claude/      → ~/.claude/CLAUDE.md (global Claude Code instructions)
├── git/         → ~/.gitconfig, ~/.gitignore
├── tmux/        → ~/.tmux.conf, ~/.tmux/plugins/
├── vim/         → ~/.vimrc
└── zsh/         → ~/.zshrc, ~/.zprofile, ~/.zshenv, ~/.git-worktree-functions.zsh
```

### Key Files
- `zsh/.zshrc` - Main shell config with aliases, functions, and plugin loading
- `zsh/.git-worktree-functions.zsh` - Git worktree management (`wt`/`wtd` commands)
- `tmux/.tmux.conf` - Tmux config with Ctrl-X prefix, vi keys, TPM plugins
- `git/.gitconfig` - Git config with 1Password SSH signing, difftastic

### Naming Convention
Files prefixed with `dot-` are renamed by Stow (e.g., `git/dot-gitignore` → `~/.gitignore`).

## Important Shell Functions

### Git Worktree Management (in `.git-worktree-functions.zsh`)
- `wt` - FZF picker for all feature worktrees across ~/wealthsimple repos
- `wt 123` - Switch to `jb-hhmm-123` globally, or create if not exists
- `wtd` - FZF picker to delete any worktree
- `wtd 123` - Delete specific worktree

These auto-open the correct IDE (WebStorm/RubyMine/IntelliJ), copy untracked files, and run `pnpm install` or copy node_modules.

### Other Notable Functions (in `.zshrc`)
- `b 123` - Create/switch to branch `jb/hhmm-123`
- `gcj` - Commit using Jira ticket description
- `nxa test` - Run nx affected tests from fork point

## Security
- 1Password CLI for credentials (op read "op://...")
- SSH signing via 1Password (`op-ssh-sign`)
- `GITHUB_TOKEN` is explicitly unset in `.zshrc` to force `gh` CLI keyring auth