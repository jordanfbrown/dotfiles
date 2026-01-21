---
name: writing-skills
description: Create new Claude Code skills. Use when documenting learnings, patterns, or workflows as reusable skills for future sessions.
---

# Writing Claude Code Skills

## Skill Location & Structure

Skills live in `~/.claude/skills/<skill-name>/SKILL.md`:

```
~/.claude/skills/
├── my-skill/
│   └── SKILL.md
├── another-skill/
│   └── SKILL.md
```

## Required Format

Every skill needs YAML frontmatter:

```markdown
---
name: skill-name
description: Brief description. Use when [trigger condition]. Covers [what it helps with].
---

# Skill Title

Content here...
```

### The Description is Critical

The description determines WHEN Claude uses the skill. Make it specific:

**BAD** - Too vague:
```yaml
description: Helps with testing
```

**GOOD** - Clear trigger and scope:
```yaml
description: Write React component tests in front-end-monorepo. Use when creating or updating test files for web components. Covers async patterns, mocking, and common pitfalls.
```

## Content Principles

### 1. Lead with the Most Common Case

Put the thing people need 80% of the time at the top:

```markdown
## Required Imports & Setup

\`\`\`tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
\`\`\`
```

### 2. Use BAD/GOOD Examples

Show the wrong way first, then the right way:

```markdown
**BAD** - Text content can change:
\`\`\`tsx
expect(await screen.findByText('Submit')).toBeInTheDocument();
\`\`\`

**GOOD** - TestIDs are stable:
\`\`\`tsx
expect(await screen.findByTestId('submit-button')).toBeInTheDocument();
\`\`\`
```

### 3. Include Copy-Paste Templates

Give complete, working examples:

```markdown
## Test Structure Template

\`\`\`tsx
/**
 * @jest-environment jsdom
 */
import React from 'react';
// ... complete example
\`\`\`
```

### 4. Document Common Pitfalls

Capture mistakes so they're not repeated:

```markdown
## Common Pitfalls

1. **Forgetting X** - Why it matters
2. **Using Y instead of Z** - What goes wrong
```

### 5. Keep It Self-Contained

The skill should have everything needed. Don't assume Claude remembers other context.

## Skill Template

```markdown
---
name: skill-name
description: [Action verb] [thing]. Use when [trigger]. Covers [scope].
---

# [Skill Title]

## Quick Start

[Most common use case with code example]

## [Core Concept 1]

[Explanation with examples]

**BAD**:
\`\`\`
[wrong approach]
\`\`\`

**GOOD**:
\`\`\`
[correct approach]
\`\`\`

## [Core Concept 2]

[More patterns...]

## Templates

[Copy-paste starting points]

## Common Pitfalls

1. **[Pitfall 1]** - [Why and how to avoid]
2. **[Pitfall 2]** - [Why and how to avoid]

## Commands Reference

\`\`\`bash
# Relevant commands
\`\`\`
```

## What Makes a Good Skill

| Do | Don't |
|----|-------|
| Document patterns from real experience | Write theoretical best practices |
| Include working code examples | Describe code abstractly |
| Explain WHY, not just WHAT | List rules without context |
| Cover edge cases and pitfalls | Only show happy path |
| Make it scannable with headers | Write walls of text |
| Keep focused on one topic | Cover everything tangentially related |

## When to Create a Skill

Create a skill when you:

1. **Solved a non-obvious problem** - Future sessions will hit it again
2. **Discovered repo-specific patterns** - Not in general docs
3. **Built a multi-step workflow** - Easy to miss steps
4. **Found common pitfalls** - Mistakes worth preventing

## Skill Naming

Use lowercase kebab-case that describes the action:

- `writing-tests` not `tests`
- `debugging-graphql` not `graphql-stuff`
- `front-end-monorepo-testing` not `fem-tests`

## Creating a Skill

```bash
# 1. Create directory
mkdir -p ~/.claude/skills/my-skill-name

# 2. Create skill file
# Write content to ~/.claude/skills/my-skill-name/SKILL.md

# 3. Verify
ls ~/.claude/skills/my-skill-name/
```

## Iterating on Skills

Skills should evolve. When you learn something new:

1. Read the existing skill
2. Add the new learning in the appropriate section
3. If it doesn't fit, consider if the skill scope needs adjustment

## Common Pitfalls When Writing Skills

1. **Too broad** - "How to code" vs "How to write tests in this repo"
2. **Too theoretical** - Include real examples from actual work
3. **Missing the trigger** - Description must say WHEN to use it
4. **No code examples** - Skills without examples don't get used
5. **Assuming context** - Each skill should stand alone
