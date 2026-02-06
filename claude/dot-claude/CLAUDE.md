# Global Claude Code Memory

## Development Environment
- **Platform**: macOS
- **Primary IDE**: RubyMind (JetBrains)
- **Primary Languages**: Ruby, Kotlin, TypeScript (varies by repository)

## Code Analysis Strategy
- Always check existing codebase patterns before making changes
- Look for `.editorconfig`, `package.json`, `Gemfile`, or build files to understand project conventions
- Check for linting configs (`.eslintrc`, `.rubocop.yml`, `prettier.config.js`) and follow them
- Respect existing indentation style (spaces vs tabs, count)
- Follow existing naming conventions found in the codebase

## Looking Up Documentation
Always use Context7 MCP when I need library/API documentation, code generation, setup or configuration steps without me having to explicitly ask.

## Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:
1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes

## Issue Tracking

We track our tickets and projects in Linear (https://linear.app), a project management tool. We use the linear MCP tool for communicating with Linear.

The ticket numbers follow the format "HHMM-<number>" (our team is HHMM, Household & Money Management). Always reference tickets by their number.

If you create a ticket, and it's not clear which project to assign it to, prompt the user. When creating subtasks, use the project of the parent ticket by default.

When the the status of a task in the ticket description has changed (task → task done), update the description accordingly. When updating a ticket with a progress report that is more than just a checkbox change, add that report as a ticket comment.

When writing tickets, always have 2 sections: "Context" (explain the why) and "Acceptance Criteria" (explain the what).

## Common Commands to Check First
When working on a project, always check for these common commands:

### Ruby Projects
```bash
bundle install
bundle exec rspec
bundle exec rubocop
rake -T  # List available rake tasks
```

### TypeScript/JavaScript Projects  
```bash
yarn install
yarn test
yarn lint
yarn build
yarn dev
# For NX workspaces:
nx build
nx test
nx lint
```

### Kotlin Projects
```bash
./gradlew build
./gradlew test
./gradlew ktlintCheck
```

## Workflow Preferences
- **Linting**: Always run linters before committing (ESLint, RuboCop, Prettier)
- **Testing**: Run relevant tests after making changes
- **Commits**: Follow existing commit message style in the repository
- **File Discovery**: Use project search tools to understand codebase structure before making changes
- **Git Worktrees**: Use `wt` and `wtd` commands for worktree management:
  - Structure: `<repo>/<branch>` (e.g., `front-end-monorepo/main/`, `front-end-monorepo/jb-hhmm-123/`)
  - **Works globally** - run from anywhere, searches all repos in ~/wealthsimple
  - `wt` - FZF picker for all feature worktrees across all repos
  - `wt 123` - Switch to existing `jb-hhmm-123` globally, or create (prompts for repo if not in one)
  - `wtd` - FZF picker to delete any worktree (with confirmation)
  - `wtd 123` - Delete specific worktree (searches globally)
  - Auto-opens correct IDE (WebStorm for JS/TS, RubyMine for Ruby, IntelliJ for Kotlin/Maven)
  - Auto-runs `pnpm install` for pnpm projects, copies node_modules for npm/yarn
  - Auto-copies .env, .envrc, mise.toml and runs `direnv allow` / `mise trust`

## Best Practices
- Never assume library availability - always check `package.json`, `Gemfile`, or `build.gradle` first
- Look at neighboring files to understand patterns and conventions
- Respect existing architecture and don't introduce new patterns without justification
- When creating new components, mirror existing component structure
- Always check imports and dependencies in the files you're editing

## Project-Specific Adaptation
- Each repository may have different:
  - Indentation style (2 spaces, 4 spaces, tabs)
  - Naming conventions (camelCase, snake_case, PascalCase)
  - Linting rules and configurations
  - Test frameworks and structures
  - Build and deployment processes

Always adapt to the specific project's conventions rather than imposing global preferences.

## Visual Diagrams
- **Mermaid Diagrams**: When creating or explaining system architecture, reference the Mermaid diagrams skill

## GitHub CLI
- `gh` commands use keyring authentication automatically - no special handling required

## Security Reminders
- Never commit secrets, API keys, or sensitive data
- Follow security best practices for the specific language/framework
- Be cautious with file permissions and access patterns
