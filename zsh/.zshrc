# Initialize starship prompt
eval "$(starship init zsh)"

# === MINIMAL ZSH SETUP (replacing Oh My Zsh) ===
# Enable completion system
autoload -Uz compinit
compinit

# Load essential plugins directly
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# FZF key bindings and fuzzy completion
source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
source /opt/homebrew/opt/fzf/shell/completion.zsh

# Z for smart directory navigation (replaces autojump)
. /opt/homebrew/etc/profile.d/z.sh

# Alias cd to z for seamless smart navigation
# alias cd='z'

# Basic git aliases (replacing OMZ git plugin)
alias g='git'                    # Quick git shorthand
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gcam='git commit -a -m'
alias gcb='git checkout -b'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gd='git diff'
alias gl='git pull'
alias glog='git log --oneline --decorate --graph'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpsup='git push --set-upstream origin $(git branch --show-current)'
alias gst='git status'
alias gss='git status --short'   # Condensed status (since you used "git st")
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'

# === HISTORY CONFIGURATION ===
# Set history file location and size for maximum persistence
HISTFILE=~/.zsh_history
HISTSIZE=1000000              # In-memory history size (1M commands)
SAVEHIST=1000000              # History file size (1M commands)

# History behavior options
setopt HIST_IGNORE_DUPS       # Don't record duplicate entries
setopt HIST_IGNORE_ALL_DUPS   # Delete old duplicate entries
setopt HIST_SAVE_NO_DUPS      # Don't save duplicates to history file
setopt HIST_FIND_NO_DUPS      # Don't show duplicates when searching
setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
setopt HIST_VERIFY            # Show command with history expansion before running
setopt SHARE_HISTORY          # Share history between all sessions
setopt APPEND_HISTORY         # Append to history file (don't overwrite)
setopt INC_APPEND_HISTORY     # Write to history file immediately

# === COMPLETION OPTIMIZATIONS ===
# Speed up completions with caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# === EXPORTS ===
# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"

# Development tools
export JAVA_HOME="$(/usr/libexec/java_home)"
export EDITOR="code -w"
export AWS_REGION='us-east-1' 

# Service credentials (TODO: Move to 1Password)
export NEXUS_USERNAME="dev-read"
export JIRA_EMAIL="***REMOVED***"

# === ALIASES ===
# Shell shortcuts
alias src="source ~/.zshrc"
alias zshconfig="cursor ~/.zshrc"

# Development tools
alias ag="ag --path-to-ignore ~/.ignore"
alias be="bundle exec"
alias s="be rspec"
alias ftp="files-to-prompt"

# Git shortcuts
alias gcap="git ci --amend --no-edit && gpf"
alias gpo="gpsup"
alias ga.="git add ."

# Custom scripts
alias gcai="~/wealthsimple/scripts/ai_commit/ai_commit.rb"
alias reddit-scraper='mise exec --cd ~/wealthsimple/scripts/reddit_scraper -- ruby reddit_scraper.rb'
alias staging-acls='mise exec --cd ~/wealthsimple/scripts/generate_staging_acls -- ruby generate_acl_jwts.rb'
alias git-file-history="~/wealthsimple/scripts/git_file_history/analyze_file_history.rb"
alias mermaid-view="~/wealthsimple/scripts/mermaid-view"
alias cpr='JIRA_API_KEY=$(op read op://Employee/JIRA_API_KEY/credential) GITHUB_TOKEN=$(gh auth token) ~/wealthsimple/scripts/create_pull_request/create_pull_request.rb'

# Utilities
alias my-prod-id="echo ***REMOVED*** | pbcopy"

# VPN connection check
check-vpn() {
  # Check if GlobalProtect VPN is connected by looking for active utun interface with IP
  if ! ifconfig | grep -A1 "utun.*UP" | grep -q "inet [0-9]"; then
    echo "❌ Error: GlobalProtect VPN not connected. Please connect to VPN first."
    return 1
  fi
  return 0
}

c() {
  claude --dangerously-skip-permissions "$@"
}

# === FUNCTIONS ===
wtf() {
  if [ $# -eq 0 ]; then
    pbpaste | llm 'explain this'
  else
    pbpaste | llm "$1"
  fi
}

gcj() {
  # Try to extract Jira ticket ID from argument or current branch
  local ticket_id="$1"
  
  if [[ -z "$ticket_id" ]]; then
    # Get current git branch name
    local branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    if [[ -n "$branch_name" ]]; then
      # Extract Jira ticket pattern (letters-numbers) from branch name
      # This regex matches patterns like: plen-18, PLEN-123, abc-456, etc.
      ticket_id=$(echo "$branch_name" | grep -oiE '[a-z]+-[0-9]+' | head -1)
    fi
  fi
  
  if [[ -n "$ticket_id" ]]; then
    echo "Using Jira ticket: $ticket_id"
    JIRA_API_KEY=$(op read op://Employee/JIRA_API_KEY/credential) /Users/jordan.brown/wealthsimple/scripts/git_commit_jira/commit_from_jira.rb "$ticket_id"
  else
    echo "No Jira ticket ID provided and couldn't extract one from branch name."
    echo "Usage: gcj [TICKET_ID]"
    echo "Current branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'not in git repo')"
  fi
}


LLM_API_KEY() { echo "$(op read op://Employee/LLM_API_KEY/credential)"; }

av-staging() {
  VAULT_PASS=$(op read "op://Engineering/***REMOVED***/password") 
  if [ $? -eq 0 ]; then
    ansible-vault view "$@" --vault-password-file <(echo "$VAULT_PASS")
  else
    echo "Error: Failed to retrieve password from 1Password"
    return 1
  fi
}

nxa() {
    local target=$1
    local parallelism=8
    local branchForkWithMain=`git merge-base --fork-point main HEAD`

    if [[ "$1" = "test" ]]; then 
      # Jest manages its own parallelism.
      parallelism=1
    fi

    echo "Running: nx affected -t ${target} --base=$branchForkWithMain --parallel=$parallelism"
    nx affected -t ${target} --base=$branchForkWithMain --parallel=$parallelism
}

b() {
  git checkout -b jb/${1} 2> /dev/null || git checkout jb/${1}
}

aws-creds() {
  # Check if we already have valid AWS credentials
  if ! aws sts get-caller-identity &>/dev/null; then
    echo "No valid AWS credentials found. Running assume..."
    assume ***REMOVED***
  fi
}

wsc() {
  # Get current directory name (application name)
  local app_name=$(basename "$PWD")
  
  # Get current git branch
  local branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  
  if [[ -z "$branch_name" ]]; then
    echo "Error: Not in a git repository or unable to determine current branch"
    return 1
  fi
  
  echo "Creating sandbox for application: $app_name, branch: $branch_name"
  ws sandbox create -a "$app_name" -b "$branch_name"
}

# Load git worktree functions
source "$HOME/.git-worktree-functions.zsh"

source /Users/jordan.brown/.config/wealthsimple/direnv/config.zsh
source /Users/jordan.brown/.config/op/plugins.sh

eval "$(ws hook zsh)"
eval "$(mise activate zsh)"


. "$HOME/.local/bin/env"

unset GITHUB_TOKEN
