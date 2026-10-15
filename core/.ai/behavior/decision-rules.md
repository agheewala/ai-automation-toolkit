# Decision Rules

> Defines when to proceed, stop, flag, or escalate.  
> Authority: Defers to `governance/copilot-instruction.md`.

---

## 1. STOP Conditions (Mandatory Halt)

Stop all activity and notify the user immediately if any of the following are true:

| # | Condition | Action |
|---|---|---|
| 1 | `TicketID` or `Type` not provided in chat | STOP — ask the user |
| 2 | `Detail Description` missing or too vague to determine scope | STOP — ask the user for clarification |
| 3 | Analysis summary presented to user but not confirmed | STOP — wait for user to confirm before writing code |
| 4 | Current branch is not `Development` (for Bug / Enhancement / Change Request types) | STOP — warn user; do not proceed |
| 5 | Build fails after code changes | STOP — report errors; do not push |
| 6 | A security vulnerability is discovered | STOP — notify team lead; raise dedicated security ticket |
| 7 | Shared library (`{{SHARED_LIBS}}`) change required without team lead sign-off | STOP — escalate |
| 8 | {{RISK_THRESHOLDS}} | STOP — confirm scope with user |
| 9 | New DB objects (columns, tables, stored procs) required — not found in `.ai/data-dictionary/` and no confirmation from user | STOP — confirm before generating DDL |
| 10 | Creating SQL scripts (production data fixes, ad-hoc queries, or stored procedures) without first consulting `.ai/data-dictionary/` and `governance/SQL_Guidelines.md` | STOP — read `governance/SQL_Guidelines.md` Section 0 and the relevant data dictionary file(s) first; validate table/column existence, SUPPORT_USERID, WHERE clauses, and transaction safety |
| 11 | A third-party library would need to be added | STOP — get explicit approval first |
| 12 | The user has NOT typed `Push Code` | STOP — do not push |
| 13 | Any rule in `governance/copilot-instruction.md` would be violated | STOP — flag the conflict |
| 14 | Ticket Type = Analysis AND any branch creation / code change / build / commit / push is being attempted | STOP — Analysis tickets produce a written report only. No code action is permitted under any circumstances. Deliver analysis and end. |

---

## 2. FLAG Conditions (Inform and Wait)

Flag the following to the user and wait for a response before continuing:

| Condition | Flag Message |
|---|---|
| Accessibility impact is unclear | "This change may affect accessibility. Flagging for review before proceeding." |
| Cross-module impact detected | "This change may affect [Module X]. Confirm scope before proceeding." |
| New file creation appears necessary | "A new file appears necessary. Please confirm this is in scope." |
| Refactoring appears needed beyond minimal fix | "A refactor may improve this fix, but it is outside current scope. Proceed minimally or confirm refactor?" |
| Performance concern identified | "This change introduces a query/loop that may have performance impact. Confirm approach." |
| Feature flag recommended | "This change carries deployment risk. Recommend wrapping in a feature flag. Confirm?" |
| PR reviewers not configured | "Default reviewers not set in mcp.json. Who should review this PR?" |

---

## 3. PROCEED Conditions

Proceed without prompting if ALL of the following are true:

```
[ ] TicketID, Type, and Detail Description received in chat
[ ] Analysis summary presented and confirmed by user in chat
[ ] Risk checklist cleared (behavior/setting.md)
[ ] Current branch is `Development` (or user confirmed branch for ANALYSIS type)
[ ] New branch created (or user explicitly declined)
[ ] Change is within the scope stated in the chat input
[ ] No shared library changes required
[ ] No new third-party dependencies required
[ ] No DB changes without user confirmation
[ ] Build passes
[ ] Accessibility impact assessed and clear
```

---

## 4. Escalation Path

```
AI detects an issue
  └─▶ Can it be resolved with information already available?
        ├─ YES → resolve and inform user
        └─ NO
              └─▶ Is it a blocking issue?
                    ├─ YES → STOP + notify user immediately
                    └─ NO → FLAG + wait for user response
```

Never make a guess to unblock yourself. Always ask.

---

## 5. Ambiguity Resolution Rules

| Ambiguity Type | Resolution |
|---|---|
| Field name or method name not known | Mark as `TBD` — ask the user |
| DB column / stored procedure name not known | Check `.ai/data-dictionary/` (schema + stored procedure catalog) first. If still not found, mark as `TBD` — never invent |
| Business rule unclear | Ask the user — never assume |
| UI label text missing | Use `AppResources.TBD` placeholder — ask for the resource key |
| Scope boundary unclear (what is in vs. out) | Ask explicitly — do not expand scope silently |
| Two valid technical approaches exist | Present both options to user with trade-offs — let user decide |

---

## 6. Conflict Resolution Between Files

| Priority | File |
|---|---|
| **1 (Highest)** | `governance/copilot-instruction.md` |
| **2** | `governance/wcag-fix-patterns.md` |
| **3** | `governance/coding-standards.md` |
| **4** | `governance/scm-workflow.md` |
| **5** | `governance/security-and-compliance.md` |
| **6** | `behavior/setting.md` |
| **7** | `behavior/decision-rules.md` (this file) |

If two files give contradictory instructions: **the higher priority file wins**. Flag the conflict to the user.

---

## 7. Output Discipline

- Never produce output that contains invented data.
- Never produce code that is not directly traceable to a requirement in the ticket.
- Never produce speculative "what if" code in the implementation — keep it to analysis only.
- Always label any pseudocode as pseudocode.
- Always label any `TBD` as requiring user input before it can be replaced.
- Always communicate blockers clearly and immediately — never work around them silently.

---
