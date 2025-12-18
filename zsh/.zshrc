# =============================================================================
# ZSH CONFIGURATION
# =============================================================================

# =============================================================================
# PROMPT AND DISPLAY
# =============================================================================
eval "$(starship init zsh)"

# =============================================================================
# ZSH CORE CONFIGURATION
# =============================================================================
# Enable completion system
autoload -Uz compinit
compinit

# =============================================================================
# HISTORY CONFIGURATION
# =============================================================================
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

# =============================================================================
# COMPLETION CONFIGURATION
# =============================================================================
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Enable menu selection and cycling
zstyle ':completion:*' menu select
setopt AUTO_MENU        # Show completion menu on successive tab press
setopt COMPLETE_IN_WORD # Allow completion in the middle of a word
setopt ALWAYS_TO_END    # Move cursor to end of word after completion
setopt AUTO_CD          # Allow navigation by typing directory names

# =============================================================================
# PLUGINS AND EXTENSIONS
# =============================================================================
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# FZF integration
source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
source /opt/homebrew/opt/fzf/shell/completion.zsh

# Z for smart directory navigation
. /opt/homebrew/etc/profile.d/z.sh

# =============================================================================
# ENVIRONMENT VARIABLES AND EXPORTS
# =============================================================================
# Development tools
export JAVA_HOME="$(/usr/libexec/java_home)"
export EDITOR="code -w"
export AWS_REGION='us-east-1'

# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools"
export PATH="$HOME/.local/bin:$PATH"

export NEXUS_USERNAME="dev-read"
export JIRA_EMAIL="***REMOVED***"

# Disable auto updater for Claude Code
export DISABLE_AUTOUPDATER=1

export FORT_KNOX_GRPC_VERSION=1.72.0

# https://github.com/ruby/openssl/issues/949
export RUBYOPT="-r$HOME/.rubyopenssl_default_store.rb $RUBYOPT"

export HIVE_TOKEN=***REMOVED***


# =============================================================================
# GIT ALIASES
# =============================================================================
alias g='git'
alias ga='git add'
alias ga.='git add .'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gcam='git commit -a -m'
alias gcap='git ci --amend --no-edit && gpf'
alias gcb='git checkout -b'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gd='git diff'
alias gl='git pull'
alias glog='git log --oneline --decorate --graph'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpo='gpsup'
alias gpsup='git push --set-upstream origin $(git branch --show-current)'
alias gst='git status'
alias gss='git status --short'
alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias gcm='git commit -m'
alias grh='git reset HEAD~1'

# =============================================================================
# SHELL ALIASES
# =============================================================================
alias src="source ~/.zshrc"
alias zshconfig="cursor ~/.zshrc"

# =============================================================================
# NAVIGATION ALIASES
# =============================================================================
alias ..="cd .."
alias ...="cd ../.."

# =============================================================================
# DEVELOPMENT ALIASES
# =============================================================================
alias ag="ag --path-to-ignore ~/.ignore"
alias be="bundle exec"
alias s="be rspec"
alias ftp="files-to-prompt"
alias nx="pnpm nx"

# =============================================================================
# CUSTOM SCRIPT ALIASES
# =============================================================================
alias gcai="~/wealthsimple/scripts/ai_commit/ai_commit.rb"
alias reddit-scraper='mise exec --cd ~/wealthsimple/scripts/reddit_scraper -- ruby reddit_scraper.rb'
alias staging-acls='mise exec --cd ~/wealthsimple/scripts/generate_staging_acls -- ruby generate_acl_jwts.rb'
alias git-file-history="~/wealthsimple/scripts/git_file_history/analyze_file_history.rb"
alias mermaid-view="~/wealthsimple/scripts/mermaid-view"
alias cpr='JIRA_API_KEY=$(op read op://Employee/JIRA_API_KEY/credential) GITHUB_TOKEN=$(gh auth token) ~/wealthsimple/scripts/create_pull_request/create_pull_request.rb'
alias ft="~/wealthsimple/scripts/run-femr-test.js"
alias fkl="git stash && gco main && git pull && git stash apply && bundle && bundle exec rake db:migrate"
alias dl="~/wealthsimple/daily-log/dl"

# =============================================================================
# UTILITY ALIASES
# =============================================================================
alias my-prod-id="echo ***REMOVED*** | pbcopy"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================
c() {
  claude --dangerously-skip-permissions "$@"
}

wtf() {
  if [ $# -eq 0 ]; then
    pbpaste | llm 'explain this'
  else
    pbpaste | llm "$1"
  fi
}

LLM_API_KEY() { 
  echo "$(op read op://Employee/LLM_API_KEY/credential)"
}

# =============================================================================
# WORK-SPECIFIC FUNCTIONS
# =============================================================================
check-vpn() {
  if ! ifconfig | grep -A1 "utun.*UP" | grep -q "inet [0-9]"; then
    echo "❌ Error: GlobalProtect VPN not connected. Please connect to VPN first."
    return 1
  fi
  return 0
}

av-staging() {
  VAULT_PASS=$(op read "op://Engineering/***REMOVED***/password") 
  if [ $? -eq 0 ]; then
    ansible-vault view "$@" --vault-password-file <(echo "$VAULT_PASS")
  else
    echo "Error: Failed to retrieve password from 1Password"
    return 1
  fi
}

aws-creds() {
  if ! aws sts get-caller-identity &>/dev/null; then
    echo "No valid AWS credentials found. Running assume..."
    assume ***REMOVED***
  fi
}

wsc() {
  local app_name=$(basename "$PWD")
  local branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  
  if [[ -z "$branch_name" ]]; then
    echo "Error: Not in a git repository or unable to determine current branch"
    return 1
  fi
  
  echo "Creating sandbox for application: $app_name, branch: $branch_name"
  ws sandbox create -a "$app_name" -b "$branch_name"
}

# =============================================================================
# GIT WORKFLOW FUNCTIONS
# =============================================================================
gcj() {
  local ticket_id="$1"
  
  if [[ -z "$ticket_id" ]]; then
    local branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    if [[ -n "$branch_name" ]]; then
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

b() {
  local branch_name
  
  # Check if argument contains letters/hyphens (like proj-411 or hhmm-400)
  if [[ "$1" =~ [a-zA-Z-] ]]; then
    branch_name="jb/$1"
  else
    # Default to jb/hhmm-${number} format for bare numbers
    branch_name="jb/hhmm-$1"
  fi
  
  git checkout -b "$branch_name" 2> /dev/null || git checkout "$branch_name"
}

# =============================================================================
# NX WORKFLOW FUNCTIONS
# =============================================================================
nxa() {
  local target=$1
  local parallelism=8
  local branchForkWithMain=`git merge-base --fork-point main HEAD`

  if [[ "$1" = "test" ]]; then 
    parallelism=1
  fi

  echo "Running: nx affected -t ${target} --base=$branchForkWithMain --parallel=$parallelism"
  nx affected -t ${target} --base=$branchForkWithMain --parallel=$parallelism
}

# =============================================================================
# EXTERNAL INTEGRATIONS
# =============================================================================
source "$HOME/.git-worktree-functions.zsh"
source /Users/jordan.brown/.config/wealthsimple/direnv/config.zsh
source $(brew --prefix)/share/ws-cli/shell/activate.zsh
eval "$(direnv hook zsh)"
eval "$(mise activate zsh)"

# =============================================================================
# ENVIRONMENT CLEANUP
# =============================================================================
unset GITHUB_TOKEN

# BEGIN wealthsimple reposerver
source "$HOME/.local/share/ws-cli/rc/reposerver/env.sh"
# END wealthsimple reposerver
