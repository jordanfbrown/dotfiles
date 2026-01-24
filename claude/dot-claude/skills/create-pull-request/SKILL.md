---
name: create-pull-request
description: Create a GitHub pull request from JIRA ticket
---

# Create Pull Request from JIRA Ticket

## Context

- Current branch: !`git branch --show-current`
- Base branch: !`git rev-parse --abbrev-ref origin/HEAD 2>/dev/null`

## Workflow

### 1. Extract Ticket ID
Get JIRA ticket ID from current branch name (pattern: [a-z]+-[0-9]+, e.g., PLEN-123).

### 2. Fetch JIRA Context
Use jira CLI to get ticket details:
```bash
jira issue view TICKET-ID
```
Extract: summary, description, acceptance criteria, ticket type.

### 3. Analyze Git Changes
```bash
git log BASE_BRANCH..HEAD --oneline
git diff --stat BASE_BRANCH..HEAD
git diff BASE_BRANCH..HEAD
```
Summarize: what changed, why it changed, technical details.

### 4. Find PR Template
Search in order:
1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `.github/PULL_REQUEST_TEMPLATE/pull_request_template.md`
4. `docs/pull_request_template.md`
5. `PULL_REQUEST_TEMPLATE.md`

If none found, use default template.

### 5. Generate PR Content
**Title format:** `[TICKET-ID] Brief summary from JIRA` (truncate to ~50-60 chars)

**Body:** Fill template with:
- JIRA context (summary, description, acceptance criteria)
- Technical changes from diff analysis
- Link: `https://wealthsimple.atlassian.net/browse/TICKET-ID`

### 6. Preview
Show generated PR title and body to user

### 7. Create PR
```bash
git push -u origin $(git branch --show-current)
gh pr create --draft --title "PR_TITLE" --body "PR_BODY"
```

## Default PR Template

```markdown
## Summary
[Brief description of changes]

## JIRA Ticket
[TICKET_LINK]

## What Changed
[Technical changes summary]

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated if needed
```
