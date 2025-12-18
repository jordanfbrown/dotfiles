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
- **Mermaid Diagrams**: When creating or explaining system architecture, code flows, or process diagrams, always use the mermaid_view tool to display diagrams visually
- **Command**: `~/wealthsimple/scripts/mermaid_view/mermaid_view.js "diagram-code-here"`
- **Usage**: Automatically run this command after creating any Mermaid diagram code to open it in the browser for visual review
- **Note**: Now uses consolidated JavaScript implementation (was previously Ruby + JavaScript)

## GitHub CLI
- `gh` commands in Claude Code require unsetting `GITHUB_TOKEN` environment variable first: `unset GITHUB_TOKEN && gh <command>`
- This allows `gh` to use keyring authentication instead of the invalid token in Claude Code's environment

## Security Reminders
- Never commit secrets, API keys, or sensitive data
- Follow security best practices for the specific language/framework
- Be cautious with file permissions and access patterns

## NPM 401 errors
- If we receive the following error: Error: error Error: https://wealthsimple-711984989527.d.codeartifact.us-east-1.amazonaws.com/npm/helium3/@apollo/cache-control-types/-/cache-control-types-1.0.3.tgz: Request failed "401 Unauthorized"
- We need to login to aws codeartifact:

```
# will require user to do something in browser
aws sso login --profile=package-puller 

# after aws sso login completes
aws codeartifact login --profile=package-puller --tool npm --domain wealthsimple --repository helium3
```
