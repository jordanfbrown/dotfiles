---
name: jira-to-beads
description: Break down a Jira ticket into beads (feature + tasks) for agent implementation. Creates properly structured parent-child relationships and task dependencies.
---

# Jira to Beads Breakdown

## Overview

This skill breaks down a Jira ticket into properly structured beads that can be implemented by agents using the `ralph.sh` script. It creates:

1. **Feature bead** - Parent bead with ticket ID in title
2. **Task beads** - Child beads linked to feature via `--parent`
3. **Dependencies** - Ordering between tasks for sequential implementation

## Prerequisites

- `jira-cli` installed and authenticated (via `~/.netrc`)
- `bd` (beads) CLI configured in the repo
- Repository has beads initialized (`bd init`)

## Workflow

### Step 1: Read the Jira Ticket

```bash
jira issue view <TICKET-ID> --comments 5
```

Understand:
- What is the goal/problem being solved?
- What are the acceptance criteria?
- What are the technical requirements?

### Step 2: Analyze and Plan the Breakdown

Break the work into tasks that:
- **Fit in ~200k context** - Each task should be completable by an agent in one session
- **Are independently testable** - Each task produces verifiable output
- **Have clear boundaries** - No overlapping file changes between parallel tasks
- **Follow dependency order** - Type changes before implementations, core before UI

**Common task patterns:**
- Type/interface changes (do first - others depend on this)
- Core utility/function updates
- Test utility updates (mocks, fixtures)
- Component updates (can often be parallel)
- Test coverage additions (do last)

### Step 3: Create the Feature Bead

```bash
bd create --title="<TICKET-ID>: <Brief description>" \
  --type=feature \
  --priority=2 \
  --description="## Context

<Paste or summarize the Jira ticket context>

## Acceptance Criteria

<Paste or summarize acceptance criteria>

## Tasks

This feature is broken into the following tasks (see children)."
```

**Capture the feature bead ID** (e.g., `main-abc`) for use as parent.

### Step 4: Create Task Beads

For each task, create a bead with `--parent` pointing to the feature:

```bash
bd create --title="<Descriptive task title>" \
  --type=task \
  --priority=2 \
  --parent=<FEATURE-BEAD-ID> \
  --description="## Context

<Why this task is needed, what it accomplishes>

## Acceptance Criteria

- <Specific, verifiable condition 1>
- <Specific, verifiable condition 2>
- <etc>"
```

**Task title guidelines:**
- Start with action verb: "Update", "Add", "Fix", "Implement", "Refactor"
- Be specific about the file/component: "Update NetWorthAccount type"
- Keep concise but descriptive

### Step 5: Set Up Dependencies

Use `bd dep add` to establish ordering. The syntax is:
```bash
bd dep add <blocked-task> <blocking-task>
# Meaning: <blocked-task> depends on <blocking-task>
```

**Example dependency chain:**
```bash
# Task B depends on Task A (A must complete before B)
bd dep add <task-b-id> <task-a-id>

# Task C depends on Task B
bd dep add <task-c-id> <task-b-id>
```

**Common dependency patterns:**

1. **Type changes first:**
   ```bash
   bd dep add <implementation-task> <type-task>
   ```

2. **Core before UI:**
   ```bash
   bd dep add <ui-task> <core-task>
   ```

3. **Mocks before tests:**
   ```bash
   bd dep add <test-task> <mock-task>
   ```

4. **Fan-out pattern** (multiple tasks depend on one):
   ```bash
   bd dep add <task-b> <task-a>
   bd dep add <task-c> <task-a>
   bd dep add <task-d> <task-a>
   ```

### Step 6: Verify Structure

```bash
# Show feature with children
bd show <FEATURE-BEAD-ID>

# Check what's ready to work
bd ready

# Check what's blocked
bd blocked
```

## Example Breakdown

**Jira ticket:** HHMM-804 - Don't show $0 when balance is undefined

**Feature bead:**
```bash
bd create --title="HHMM-804: Don't show \$0 when balance is undefined" \
  --type=feature --priority=2
# Returns: main-cu0
```

**Task beads:**
```bash
# Layer 1: Type changes (no dependencies)
bd create --title="Update NetWorthAccount type to allow undefined balance" \
  --type=task --priority=2 --parent=main-cu0 \
  --description="## Context

The NetWorthAccount type currently requires a balance. We need to make it optional.

## Acceptance Criteria

- balance field allows undefined/null
- Type changes compile
- Downstream aware of change"
# Returns: main-6nj

# Layer 2: Core implementation (depends on type)
bd create --title="Update convert-to-net-worth-account.ts to not default balance to 0" \
  --type=task --priority=2 --parent=main-cu0 \
  --description="..."
# Returns: main-r57
bd dep add main-r57 main-6nj  # r57 depends on 6nj

# Layer 2: Mock utilities (depends on type)
bd create --title="Update mock-net-worth-account.ts test utilities" \
  --type=task --priority=2 --parent=main-cu0 \
  --description="..."
# Returns: main-jjc
bd dep add main-jjc main-6nj  # jjc depends on 6nj

# Layer 3: Component updates (depend on core)
bd create --title="Update web components to handle undefined balances" \
  --type=task --priority=2 --parent=main-cu0 \
  --description="..."
# Returns: main-yh8
bd dep add main-yh8 main-r57  # yh8 depends on r57

# Layer 4: Tests (depend on mocks and implementation)
bd create --title="Update existing tests for undefined balance handling" \
  --type=task --priority=2 --parent=main-cu0 \
  --description="..."
# Returns: main-ycu
bd dep add main-ycu main-jjc  # ycu depends on jjc (mocks)
bd dep add main-ycu main-r57  # ycu depends on r57 (implementation)
```

**Resulting structure:**
```
main-cu0 (feature) - HHMM-804: Don't show $0...
├── main-6nj (task) - Update type [READY]
├── main-r57 (task) - Update converter [blocked by 6nj]
├── main-jjc (task) - Update mocks [blocked by 6nj]
├── main-yh8 (task) - Update components [blocked by r57]
└── main-ycu (task) - Update tests [blocked by r57, jjc]
```

## Task Sizing Guidelines

**Too big (split it):**
- "Implement the entire feature"
- "Update all components"
- Changes spanning 10+ files

**Just right:**
- "Update the type definition" (1-3 files)
- "Update the converter function" (1-2 files)
- "Update web chart components" (2-5 related files)

**Too small (combine):**
- "Add import statement"
- "Fix typo in comment"
- Single-line changes

## Running the Implementation

After creating beads, use `ralph.sh` (aliased as `r`) to implement:

```bash
r HHMM-804           # Work sequentially (safe)
r HHMM-804 --auto    # Skip confirmations
r HHMM-804 --parallel # Parallel (use with caution)
```

The script will:
1. Find the feature bead by ticket ID
2. Find all child tasks via `--parent`
3. Process them in dependency order via `bd ready`
4. Each agent implements one task and shares context

## Checklist

- [ ] Read Jira ticket thoroughly
- [ ] Plan task breakdown (aim for 5-15 tasks)
- [ ] Create feature bead with ticket ID in title
- [ ] Create task beads with `--parent=<feature-id>`
- [ ] Add dependencies with `bd dep add`
- [ ] Verify with `bd show <feature-id>` and `bd ready`
- [ ] Run `r <TICKET-ID>` to start implementation
