---
name: creating-subagents
description: Create specialized AI subagents for Claude Code. Use when user asks to create a new agent, custom agent, or subagent. Covers file structure, configuration, tool selection, and prompt writing.
---

# Creating Claude Code Subagents

## Quick Start

Subagents are Markdown files with YAML frontmatter stored in:

| Location | Scope | Priority |
|----------|-------|----------|
| `.claude/agents/` | Project-only | Highest |
| `~/.claude/agents/` | All projects | Lower |

## Required File Format

```markdown
---
name: agent-name
description: Brief description of purpose. Include "use proactively" or "MUST BE USED" to encourage automatic invocation.
tools: Tool1, Tool2, Tool3  # Optional - omit to inherit all tools
model: sonnet  # Optional - sonnet, opus, haiku, or inherit
---

Your system prompt goes here. This defines the agent's behavior,
expertise, and approach to solving problems.
```

## Configuration Fields

| Field | Required | Values |
|-------|----------|--------|
| `name` | Yes | lowercase-with-hyphens |
| `description` | Yes | When/why to use this agent |
| `tools` | No | Comma-separated list (omit = inherit all) |
| `model` | No | `sonnet`, `opus`, `haiku`, `inherit` |
| `permissionMode` | No | `default`, `acceptEdits`, `bypassPermissions`, `plan`, `ignore` |
| `skills` | No | Comma-separated skill names to auto-load |

## Available Tools

Common tools to consider:

- **Read** - Read file contents
- **Edit** - Modify files
- **Write** - Create files
- **Bash** - Execute shell commands
- **Grep** - Search file contents
- **Glob** - Find files by pattern
- **WebFetch** - Fetch web content
- **WebSearch** - Search the web
- **Task** - Spawn other agents

Use `/agents` command to see all available tools including MCP tools.

## Writing the Description

The description determines WHEN Claude uses the agent automatically.

**BAD** - Too vague:
```yaml
description: Reviews code
```

**GOOD** - Clear trigger and scope:
```yaml
description: Expert code reviewer. Use PROACTIVELY after any code changes to check quality, security, and maintainability.
```

**GOOD** - Action-oriented:
```yaml
description: Debugging specialist for errors, test failures, and unexpected behavior. MUST BE USED when encountering any issues.
```

## Writing the System Prompt

### Structure Template

```markdown
You are a [role] specializing in [domain].

When invoked:
1. [First action]
2. [Second action]
3. [Third action]

Key practices:
- [Practice 1]
- [Practice 2]
- [Practice 3]

For each [task type], provide:
- [Output 1]
- [Output 2]
- [Output 3]

[Additional constraints or focus areas]
```

### Prompt Writing Principles

1. **Be specific about the first action** - What should the agent do immediately?
2. **Include a checklist** - Agents follow structured lists well
3. **Define output format** - What should the agent return?
4. **Add constraints** - What should the agent avoid?

## Complete Examples

### Code Reviewer

```markdown
---
name: code-reviewer
description: Expert code review specialist. Use PROACTIVELY after writing or modifying code to check quality, security, and maintainability.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer ensuring high standards of code quality and security.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Begin review immediately

Review checklist:
- Code is clear and readable
- Functions and variables are well-named
- No duplicated code
- Proper error handling
- No exposed secrets or API keys
- Input validation implemented
- Good test coverage
- Performance considerations addressed

Provide feedback organized by priority:
- Critical issues (must fix)
- Warnings (should fix)
- Suggestions (consider improving)

Include specific examples of how to fix issues.
```

### Debugger

```markdown
---
name: debugger
description: Debugging specialist for errors, test failures, and unexpected behavior. Use PROACTIVELY when encountering any issues.
tools: Read, Edit, Bash, Grep, Glob
---

You are an expert debugger specializing in root cause analysis.

When invoked:
1. Capture error message and stack trace
2. Identify reproduction steps
3. Isolate the failure location
4. Implement minimal fix
5. Verify solution works

Debugging process:
- Analyze error messages and logs
- Check recent code changes
- Form and test hypotheses
- Add strategic debug logging
- Inspect variable states

For each issue, provide:
- Root cause explanation
- Evidence supporting the diagnosis
- Specific code fix
- Testing approach
- Prevention recommendations

Focus on fixing the underlying issue, not the symptoms.
```

### Test Runner

```markdown
---
name: test-runner
description: Test automation expert. Use PROACTIVELY to run tests and fix failures after code changes.
tools: Read, Edit, Bash, Grep, Glob
model: sonnet
---

You are a test automation expert ensuring code changes don't break existing functionality.

When invoked:
1. Identify which tests are relevant to recent changes
2. Run the appropriate test suite
3. If tests fail, analyze failures and fix them
4. Preserve original test intent when fixing

Testing workflow:
- Start with the most specific tests for changed code
- Expand to integration tests if unit tests pass
- Run full suite before declaring success

For each failure:
- Explain what the test expects vs what happened
- Determine if the test or implementation is wrong
- Fix the appropriate side
- Re-run to verify
```

## Creating the Agent

### Via Command Line

```bash
# Project-level agent
mkdir -p .claude/agents
cat > .claude/agents/my-agent.md << 'EOF'
---
name: my-agent
description: Description here
---

System prompt here
EOF

# User-level agent
mkdir -p ~/.claude/agents
cat > ~/.claude/agents/my-agent.md << 'EOF'
---
name: my-agent
description: Description here
---

System prompt here
EOF
```

### Via /agents Command (Recommended)

```
/agents
```

Select "Create New Agent" for guided setup with tool selection.

## Model Selection Guidelines

| Model | Use When |
|-------|----------|
| `haiku` | Fast, simple tasks (file search, quick lookups) |
| `sonnet` | Balanced tasks (code review, debugging, analysis) |
| `opus` | Complex reasoning (architecture decisions, difficult bugs) |
| `inherit` | Match main conversation's model |

## Tool Restriction Patterns

**Read-only agent** (safe for exploration):
```yaml
tools: Read, Grep, Glob
```

**Analysis agent** (can run commands, no edits):
```yaml
tools: Read, Grep, Glob, Bash
```

**Full access agent** (can modify code):
```yaml
tools: Read, Edit, Write, Bash, Grep, Glob
```

**Inherit all tools** (including MCP):
```yaml
# Omit the tools field entirely
```

## Invoking Agents

### Automatic (via description triggers)

Claude automatically delegates when tasks match the description.

### Explicit

```
> Use the code-reviewer agent to check my recent changes
> Have the debugger agent investigate this error
```

### Chaining

```
> First use the code-analyzer agent to find issues, then use the fixer agent to resolve them
```

## Common Pitfalls

1. **Vague description** - Be specific about WHEN to use the agent
2. **No immediate action** - Tell the agent what to do FIRST
3. **Too many responsibilities** - Keep agents focused on one domain
4. **Missing output format** - Define what the agent should return
5. **Overly broad tool access** - Limit tools to what's actually needed
6. **Forgetting to test** - Try the agent on a real task before committing

## Verifying Your Agent

After creating:

1. Run `/agents` to confirm it appears
2. Test with an explicit invocation
3. Check if automatic delegation works as expected
4. Refine the description and prompt based on results
