# Commit Message Rules & Format

> All commits made during AI-assisted development must follow this format.  
> Authority: Defers to `governance/copilot-instruction.md`.

---

## Format

```
[TicketID] Imperative short description (50 chars max)
```

### Rules
- Start with the ticket ID in square brackets.
- Use the **imperative mood** — "Fix", "Add", "Remove", "Update" — not "Fixed", "Added", "Removed".
- Keep the subject line to **50 characters or fewer**.
- Do not end the subject line with a period.
- Capitalise the first word after the bracket.
- If a longer explanation is needed, leave a blank line and add a body (72 chars per line max).

---

## Examples

### Bug Fix
```
[PROJ-1234] Fix null reference on fleet weight group load
```

### Enhancement
```
[PROJ-5678] Add export button to weight group grid
```

### Change Request
```
[PROJ-9012] Update search filter to include USDOT lookup
```

### Accessibility Fix
```
[PROJ-2345] Add aria-label to close modal button
```

### CSS Change
```
[PROJ-9012] Add input width utility class for address field
```

### Rollback Commit
```
[PROJ-1234] Rollback: Restore fleet load query to pre-ticket state
```

---

## Extended Commit Message (When Needed)

Use when the change is non-obvious or affects multiple layers:

```
[TicketID] Short imperative summary (50 chars max)

Longer explanation of what was changed and why. Wrap lines
at 72 characters. Focus on the "why" — the code shows the
"what". Reference affected files or methods if helpful.

Affected layers: Controller, Service Layer
Related: [Other-TicketID] (if applicable)
```

---

## Anti-Patterns (Do NOT Do These)

| Bad Example | Problem |
|---|---|
| `fixed bug` | No ticket reference; past tense; too vague |
| `PROJ-9012 changes` | No brackets; "changes" is meaningless |
| `[PROJ-9012] Updated the search filter functionality to now include the ability to search by USDOT number as well as the existing fields` | Too long; past tense; verbose |
| `WIP` / `temp` / `test` | Not a valid commit message |
| `[PROJ-9012] fix` | Too vague — describe what was fixed |
| Committing with no ticket reference | Every commit must be traceable to a ticket |

---

## Staging Changes Before Commit

Always review changes interactively before committing:

```bash
git add -p
```

This opens each changed hunk for review — approve (`y`), skip (`n`), or split (`s`). Never use `git add .` blindly.

---

## Commit Frequency

- Commit at logical checkpoints — one commit per cohesive change (one layer, one feature, one fix).
- Do NOT bundle unrelated changes into a single commit.
- Do NOT create micro-commits for every line change.
- Aim for commits that can be individually reverted without breaking other changes.

---
