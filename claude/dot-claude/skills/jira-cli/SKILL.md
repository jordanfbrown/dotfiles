---
name: jira-cli
description: Use for ALL Jira operations - managing issues, epics, sprints, searching, transitions, and automation. Provides interactive navigation, complex filtering, bulk operations, and script-friendly output.
---

# Jira CLI (jira-cli)

## Overview

JiraCLI is an interactive command line tool for Atlassian Jira. Use it for ALL Jira operations: searching issues, viewing details, managing sprints/epics, transitioning tickets, and automating workflows.

**Core principle:** jira-cli is your primary interface to Jira. Use it for everything.

## Authentication

Authentication is handled via `~/.netrc`. No token prefix needed—just run commands directly:

```bash
jira issue view ISSUE-123
jira issue list
jira me
```

The `.netrc` file contains:
```
machine wealthsimple.atlassian.net
login your-email@wealthsimple.com
password YOUR_API_TOKEN
```

## Essential Commands

### Quick Lookups

```bash
# View issue details
jira issue view ISSUE-123

# View with recent comments
jira issue view ISSUE-123 --comments 5

# Get current user
jira me

# Open issue in browser
jira open ISSUE-123
```

### Issue Management

```bash
# List recent issues (interactive UI)
jira issue list

# List with filters
jira issue list -s"To Do"                    # By status
jira issue list -yHigh                        # By priority
jira issue list -a$(jira me)                  # Assigned to me
jira issue list -r$(jira me)                  # Reported by me
jira issue list --created week                # Created this week
jira issue list -lbackend                     # By label

# Combine filters (high priority, assigned to me, open)
jira issue list -yHigh -a$(jira me) -sopen

# Custom JQL within project context
jira issue list -q "summary ~ cli AND status = 'In Progress'"

# Plain output (for scripting)
jira issue list --plain --no-headers

# Raw JSON output
jira issue list --raw

# CSV output
jira issue list --csv
```

### Writing Tickets

Every ticket description MUST have two sections:

**1. Context** - Explains the WHY
- Why does this work need to happen?
- What problem are we solving?
- What's the current state vs desired state?
- Any relevant background or dependencies

**2. Acceptance Criteria** - Explains the WHAT (bullet points)
- Concrete, verifiable conditions for completion
- Each bullet should be testable (yes/no)
- Cover the scope boundaries (what's in, what's out)
- **Do NOT use `[ ]` checkbox syntax** - JIRA doesn't render it correctly

**Template:**
```markdown
## Context

[Explain why this work is needed. What problem does it solve?
What's the current behavior vs expected behavior?]

## Acceptance Criteria

- First verifiable condition
- Second verifiable condition
- Edge case or error handling requirement
- Any performance/security considerations
```

**Example:**
```markdown
## Context

Users are receiving duplicate notification emails when their account
status changes. This happens because the status change event fires
twice - once from the API and once from the background job. This
creates a poor user experience and increases our email costs.

## Acceptance Criteria

- Status change events are deduplicated within a 5-second window
- Only one notification email is sent per status change
- Existing notification preferences are respected
- Deduplication logic is covered by unit tests
```

### Create and Edit

```bash
# Interactive creation
jira issue create

# Non-interactive creation
jira issue create -tBug -s"Bug summary" -yHigh -b"Description" --no-input

# Create with epic attachment
jira issue create -tStory -s"Story summary" -PEPIC-42

# Edit issue
jira issue edit ISSUE-123 -s"New summary" -yHigh

# Add/remove labels
jira issue edit ISSUE-123 --label p1 --label -p2  # Add p1, remove p2
```

### Multiline Descriptions

For multiline ticket descriptions, use **ANSI-C quoting** (`$'...'`) with `\n` for newlines:

```bash
# ✅ CORRECT: Use $'...' syntax for multiline bodies
jira issue create -tTask -s"Title" -PEPIC-42 \
  -b$'## Context\n\nFirst paragraph explaining the problem.\n\n```\nError: Something went wrong\n```\n\n## Acceptance Criteria\n\n- First condition\n- Second condition' \
  --no-input
```

**What works and what doesn't:**

| Approach | Result |
|----------|--------|
| `-b"Simple text"` | ✅ Works for single line |
| `-b"text\ntext"` (double quotes) | ⚠️ Shows literal `\n` |
| `-b$'text\ntext'` (ANSI-C quoting) | ✅ Renders actual newlines |
| `-b"$(cat <<'EOF'...EOF)"` (heredoc) | ❌ Hangs indefinitely |

**Two-step alternative** if the description is very complex:

```bash
# Step 1: Create with minimal info
jira issue create -tTask -s"Title" -PEPIC-42 --no-input
# Returns: ISSUE-123

# Step 2: Edit to add full description
jira issue edit ISSUE-123 -b'Full description with
actual newlines in single quotes' --no-input
```

### Status Transitions

```bash
# Interactive move
jira issue move

# Direct transition
jira issue move ISSUE-123 "In Progress"
jira issue move ISSUE-123 Done -RFixed -a$(jira me)  # With resolution and assignee

# Add comment during transition
jira issue move ISSUE-123 "In Progress" --comment "Starting work"
```

### Assignment

```bash
# Assign to self
jira issue assign ISSUE-123 $(jira me)

# Assign to user
jira issue assign ISSUE-123 "John Doe"

# Unassign
jira issue assign ISSUE-123 x
```

### Comments and Worklog

```bash
# Add comment
jira issue comment add ISSUE-123 "Comment text"

# Internal comment
jira issue comment add ISSUE-123 "Internal note" --internal

# Add worklog
jira issue worklog add ISSUE-123 "2h 30m" --comment "Work description" --no-input
```

### Linking and Cloning

```bash
# Link issues
jira issue link ISSUE-1 ISSUE-2 Blocks

# Clone issue
jira issue clone ISSUE-123

# Clone with modifications
jira issue clone ISSUE-123 -s"New summary" -yHigh -a$(jira me)

# Clone with text replacement
jira issue clone ISSUE-123 -H"find text:replace text"
```

## Sprint Management

```bash
# List sprints (interactive explorer)
jira sprint list

# Table view
jira sprint list --table

# Current sprint issues
jira sprint list --current

# Current sprint, assigned to me
jira sprint list --current -a$(jira me)

# Previous/next sprint
jira sprint list --prev
jira sprint list --next

# Specific sprint
jira sprint list SPRINT_ID

# Filter sprint issues by priority and assignee
jira sprint list SPRINT_ID -yHigh -a$(jira me)

# Add issues to sprint
jira sprint add SPRINT_ID ISSUE-1 ISSUE-2
```

## Epic Management

```bash
# List epics (interactive explorer)
jira epic list

# Table view
jira epic list --table

# Issues in specific epic
jira epic list EPIC-42

# Filter epic issues
jira epic list EPIC-42 -ax -yHigh  # Unassigned, high priority

# Create epic
jira epic create -n"Epic Name" -s"Epic Summary" -yHigh -b"Description"

# Add issues to epic
jira epic add EPIC-42 ISSUE-1 ISSUE-2

# Remove issues from epic
jira epic remove ISSUE-1 ISSUE-2
```

## Interactive Navigation

The TUI (Text User Interface) provides:

| Key | Action |
|-----|--------|
| `j/k` or arrows | Navigate up/down |
| `h/l` | Navigate left/right |
| `g/G` | Jump to top/bottom |
| `CTRL+f/b` | Page down/up |
| `v` | View issue details |
| `m` | Transition selected issue |
| `ENTER` | Open in browser |
| `c` | Copy URL to clipboard |
| `CTRL+k` | Copy issue key |
| `CTRL+r` or `F5` | Refresh |
| `w` or `TAB` | Toggle sidebar/content (explorer view) |
| `?` | Help |
| `q` or `ESC` | Quit |

## Scripting with jira-cli

For automation, use `--plain` flag to disable interactive UI:

```bash
# Get issue keys only
jira issue list --plain --columns key --no-headers

# Count issues per sprint
for sprint in $(jira sprint list --table --plain --columns id --no-headers); do
  count=$(jira sprint list "$sprint" --plain --no-headers 2>/dev/null | wc -l)
  echo "Sprint $sprint: $count issues"
done

# Bulk assign issues
jira issue list -s"To Do" --plain --columns key --no-headers | while read key; do
  jira issue assign "$key" $(jira me)
done
```

### Useful Script Patterns

```bash
# Tickets created per day this month
jira issue list --created month --plain --columns created --no-headers | \
  awk '{print $2}' | awk -F'-' '{print $3}' | sort -n | uniq -c

# My open issues count
jira issue list -a$(jira me) -s~Done --plain --no-headers | wc -l

# Export issues to CSV
jira issue list --csv > issues.csv
```

## Common Filter Patterns

```bash
# Unassigned issues
jira issue list -ax

# Issues with specific resolution
jira issue list -R"Won't Do"

# Status is NOT done (tilde = NOT)
jira issue list -s~Done

# Created before 6 months ago
jira issue list --created-before -24w

# Created in last hour, updated in last 30 min
jira issue list --created -1h --updated -30m

# Issues I'm watching
jira issue list -w

# View history (recently viewed)
jira issue list --history
```

## Multiple Projects

```bash
# Use specific project
jira issue list -pPROJ

# Use different config file
JIRA_CONFIG_FILE=./other-project.yaml jira issue list

# Or with flag
jira issue list -c ./other-project.yaml
```

## Quick Reference

| Command | Description |
|---------|-------------|
| `jira me` | Get current user |
| `jira open` | Open project in browser |
| `jira open KEY` | Open issue in browser |
| `jira project list` | List all projects |
| `jira board list` | List boards in project |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| 401 Unauthorized | Check ~/.netrc has correct credentials |
| Issue types not found | Run `jira init` again |
| Epic creation fails | Check `epic.name` in config for non-English Jira |

## Integration with Workflow

**Starting work:**
```bash
# Find my to-do items
jira sprint list --current -a$(jira me) -s"To Do"

# Pick one and move to in progress
jira issue move ISSUE-123 "In Progress"
```

**Finishing work:**
```bash
# Move to review/done
jira issue move ISSUE-123 "In Review" --comment "Ready for review"

# Or complete with resolution
jira issue move ISSUE-123 Done -RFixed
```

**Quick status check:**
```bash
# What's on my plate?
jira issue list -a$(jira me) -s~Done --plain
```
