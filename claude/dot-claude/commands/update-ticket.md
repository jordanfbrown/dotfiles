# Update JIRA Ticket from Branch

Update a JIRA ticket with context and acceptance criteria based on the work done in the current branch.

## Workflow

1. Extract the JIRA ticket ID from the current branch name (pattern: `[a-z]+-[0-9]+`, e.g., `HHMM-888` from `jb-hhmm-888`)

2. Analyze the git changes on this branch compared to main:
   ```bash
   git log origin/main..HEAD --oneline
   git diff origin/main..HEAD
   ```

3. Based on the changes, write a ticket description with:
   - **Context**: What problem this solves or what feature this adds (2-3 sentences)
   - **Acceptance Criteria**: Bulleted list of what the feature should do from a user/product perspective

4. Update the JIRA ticket:
   ```bash
   JIRA_API_TOKEN=$(op read op://Employee/JIRA_API_KEY/credential) jira issue edit TICKET-ID --no-input --body "DESCRIPTION"
   ```

## Guidelines

- Focus on WHAT we're trying to achieve, not HOW it's implemented
- Write from a product/user perspective, not technical implementation details
- Keep acceptance criteria concise and testable
- Use standard bullet format `-` for acceptance criteria items