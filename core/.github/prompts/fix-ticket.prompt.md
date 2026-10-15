---
description: >
  Automated ticket processor. Just provide TicketID and Description,
  and the agent handles analysis, implementation, build, push, and PR.
agent: Ticket Processor
model: {{REQUIRED_MODEL_LIST}}
---

# Automated Ticket Fix

You will be invoked when the user provides a ticket to fix.

> **Platform note:** This `.prompt.md` file (and its `/fix-ticket` slash command) is a **VS Code-only**
> discovery mechanism — GitHub Copilot CLI does not read `.github/prompts/*.prompt.md`. CLI users get
> the same automated workflow by invoking the **Ticket Processor** agent directly — see AGENTS.md
> "Running `fix ticket` from GitHub Copilot CLI" for the exact commands. The underlying workflow in
> `.github/agents/ticket-processor.agent.md` is identical either way.

## Your Job

1. Accept ticket input (TicketID + Type + Description)
2. Invoke the **Ticket Processor** agent
3. Monitor progress and relay updates to user
4. Handle any user prompts (confirmations, approvals)

## Input Format Expected

```
TicketID: <Jira ID or link>
Type: <Bug|Enhancement|CR|Analysis>
Description: <What needs to be fixed>
```

## Invocation

```
runSubagent(
  agentName: "Ticket Processor",
  description: "Fix ticket <TicketID>",
  prompt: "
    TicketID: <ID>
    Type: <Type>
    Description: <Description>
    
    Execute the full automated workflow:
    1. Load domain knowledge and governance rules
    2. Fetch Jira ticket
    3. Perform pre-code analysis
    4. Get user confirmation
    5. Create branch
    6. Implement fix
    7. Validate build
    8. Show testing checklist in chat
    9. Show changes summary
    10. Wait for 'PUSH BRANCH' or 'PUSH' approval
    11. Ask for reviewer emails
    12. Push and create PR
    13. Provide PR-to-Jira linking instructions
  "
)
```

## Example Usage

### User says:
```
fix ticket

TicketID: PROJ-1234
Type: Bug
Description: Escrow balance going negative after payment
```

### You respond:
```
I'll process this ticket using the automated workflow.

[Invoke Ticket Processor agent]

<Agent executes workflow>

<Relay progress updates to user>

<Wait for "PUSH BRANCH" or "PUSH" approval>

<Complete and report results>
```

## User Commands to Recognize

| Command | Action |
|---------|--------|
| `fix ticket` | Start automated ticket processing |
| `process ticket` | Start automated ticket processing |
| `auto fix` | Start automated ticket processing |
| `PUSH BRANCH` | Approve branch push and PR creation (relay to processor) |
| `PUSH` | Approve branch push and PR creation (relay to processor) |
| `Show Diff` | Show detailed file changes (relay to processor) |
| `Modify` | Request additional changes (relay to processor) |

## Shortcuts

For specific workflow types:

| Shortcut | Expands To |
|----------|------------|
| `/fixada-file <file>` | Process accessibility scan CSV |
| `/fixada-folder <folder>` | Process all scans in folder |
| `/fixada-results <url>` | Fetch and process BrowserStack results |

These shortcuts should invoke the accessibility-specific workflow from `.ai/behavior/ada-workflow.md`.


---
