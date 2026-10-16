# Global AI Automation & Code Change Authority

> **THIS IS THE MASTER AUTHORITY FILE.**  
> All other files in this workspace defer to this document.  
> In any conflict, this file wins.

---

## 1. Purpose (Global)

These instructions govern **all automated or assisted code changes** driven by ticket input.

This file:

- Is **not ticket-specific**
- Is **not project-specific**
- Is **committed once and reused everywhere**
- Defines **non-negotiable rules**

---

## 2. General Principles (Absolute)

| Rule | Enforcement |
|---|---|
| ✅ Safety over speed | Always confirm before irreversible actions |
| ✅ Scope containment over refactoring | Change only what the ticket requires |
| ✅ Accessibility by default | Every UI change must be WCAG/ADA/NVDA compliant |
| ✅ User approval over automation | No push, no PR, no merge without explicit approval |
| ❌ No assumptions | If it is not stated, it is TBD — ask the user |
| ❌ No silent changes | Every decision is communicated to the user |
| ❌ No irreversible actions without confirmation | Stop and ask |

---

## 3. Ticket Input Model (Chat-Based)

Tickets are submitted directly in chat — no files or folders need to be created manually.

### Required Chat Input Format

The user must provide the ticket in this exact format:

```
TicketID(Ticket Link):
Type:
Detail Description:
Screenshot/Document(Optional):
Affected Pages(Optional):
Impacted Methods / Functions(Optional):
```

### Field Rules

| Field | Required | Behaviour if Missing |
|---|---|---|
| `TicketID(Ticket Link)` | ✅ Yes | AI attempts to fetch the ticket from the ticket tracker. If the ticket does not exist, is not accessible, or no ID is provided, display an appropriate message and ask the user whether to proceed based on the description (`y` / `yes` required to continue). Do NOT proceed until confirmed. |
| `Type` | ✅ Yes | STOP — ask: Bug / Enhancement / Change Request / Analysis? |
| `Detail Description` | ✅ Yes | STOP — cannot proceed without this |
| `Screenshot/Document` | Optional | Mark as `Not provided` — continue |
| `Affected Pages` | Optional | AI infers from description; flags if unclear |
| `Impacted Methods / Functions` | Optional | AI infers from description; flags if unclear |

### Ticket ID Validation Logic

When a `TicketID(Ticket Link)` is provided, attempt to fetch the ticket from the ticket tracker:

| Scenario | Behaviour |
|---|---|
| Ticket found & accessible | Read ticket description and details; if user description also provided, compare both |
| Ticket NOT found or NOT accessible | Show message to user; ask `y` / `yes` to proceed based on description |
| No ticket ID provided | Show message; ask `y` / `yes` to proceed based on description |
| No ticket ID AND no description | STOP — Detail Description is required |

> The AI must **never invent requirements**, field names, method names, or database objects.
- Missing optional fields are inferred from the description; inferences are always stated explicitly so the user can correct them.
- If a required field is missing → **STOP and ask the user** before proceeding.

---

## 4. Pre-Code Analysis (Mandatory)

After receiving the chat ticket input, the AI must internally complete an analysis before touching any code:

```
[ ] TicketID and Type confirmed
[ ] Detail Description understood — expected vs. actual behaviour clear
[ ] Affected pages and layers identified (UI / Controller / Service / DataLayer / DB)
[ ] Impacted methods identified (inferred or provided)
[ ] If DB/SQL is involved — table/column/stored procedure verified against `.ai/data-dictionary/` if present (see `.ai/data-dictionary/README.md` and `governance/SQL_Guidelines.md` Section 0; for non-SQL-Server projects the data dictionary may not exist yet — `governance/SQL_Guidelines.md` documents the current engine's data-dictionary status, and `.ai/knowledge-base.md` Section 7 is the fallback source)
[ ] Risk assessed (shared library impact, cross-module impact, DB changes)
[ ] Scope boundary set — what is in and what is explicitly out
```

The AI must summarise this analysis to the user in chat **before writing any code.**

If any item cannot be determined → **STOP and ask the user before proceeding.**

---

## 5. Source Control & Branching Governance

### 5.1 Current Branch Validation

Before starting any code fix, check the current branch:

```bash
git branch --show-current
```

❌ If the branch is **not** `{{BASE_BRANCHES}}`:
- Stop immediately.
- Inform the user which branch is active.
- Do NOT proceed.

✅ If it **is** the `{{BASE_BRANCHES}}` branch:

```bash
git pull origin {{BASE_BRANCHES}}
```

---

### 5.2 Mandatory User Prompt for New Branch

After analysis is complete and before the first code change, always prompt:

> "Analysis is complete.  
> I recommend creating a new branch for this ticket."

Provide a suggested branch name using the format:

```
<prefix>/<TicketID>_<Short_Ticket_Title>
```

where `<prefix>` is the one this project defines for the ticket's Type: {{BRANCH_PREFIX_TABLE}}.

Example:
```
<CR prefix>/PROJ-1234_Ticket_Title
```

Then ask explicitly:

> "Shall I create this branch for you? (Y / Yes / N / No)"

---

### 5.3 Branch Decision

| Response | Action |
|---|---|
| **Y / Yes** | Create and switch to the new branch; confirm to user |
| **N / No** | Continue on current branch; warn user that changes will stay there |

Branch creation command:
```bash
git checkout -b <prefix>/<TicketID>_<Short_Ticket_Title>
```

---

### 5.4 ANALYSIS Type — Branch Rules & Restrictions

When `Type` is `Analysis`:

- ❌ **No code changes are permitted** under any circumstances.
- ❌ No new branch is created.
- ✅ Check the current branch before starting:

```bash
git branch --show-current
```

| Branch State | Behaviour |
|---|---|
| Currently on `{{BASE_BRANCHES}}` | Proceed with analysis immediately |
| Currently on any other branch | Inform the user; present two options (see below) |

**User prompt when not on `{{BASE_BRANCHES}}`:**

> "Current branch is `<branch-name>`.  
> Choose an option:  
> A) Continue analysis on this branch  
> B) Switch to `{{BASE_BRANCHES}}` (or specify another branch) and start analysis"

| User Input | Action |
|---|---|
| `same branch` / `continue` / `A` | Proceed on current branch |
| `change branch` | `git checkout {{BASE_BRANCHES}}` → `git pull origin {{BASE_BRANCHES}}` → start analysis |
| `change branch to {{BASE_BRANCHES}}` | `git checkout {{BASE_BRANCHES}}` → `git pull origin {{BASE_BRANCHES}}` → start analysis |
| `change branch to <name>` | `git checkout <name>` → `git pull origin <name>` → start analysis |

**ANALYSIS output:**

After completing the analysis, produce a structured report containing:
- Summary
- Affected layers and files
- Root cause / scope
- Risk assessment
- Fix / implementation plan (step-by-step)
- Out-of-scope items
- Recommendations and follow-up tickets

Then ask the user:
> "Analysis is complete. Would you like the output saved as a `.txt` file? (y / yes)"

- **With ticket ID:** name the file `[TicketID]_Analysis.txt`
- **Without ticket ID:** use a descriptive name (e.g. `Order_Load_Null_Reference_Analysis.txt`)

---

## 6. Code Change Governance (Critical)

### 6.1 Scope Control

- ❌ No code changes outside the scope stated in the chat ticket input
- ❌ No semantic changes without a documented requirement
- ❌ No refactoring unless explicitly requested by the user in chat
- ❌ No opportunistic cleanup of unrelated code
- ✅ If a change is needed outside scope → flag it to the user as a separate follow-up ticket

---

### 6.2 SQL Script Creation Rules (Mandatory)

> **CRITICAL: Before creating any SQL script for data fixes or database changes, you MUST follow `governance/SQL_Guidelines.md` — it is the primary reference for all SQL script patterns and mandatory validation rules in this project.**

All SQL scripts must comply with:

- **Audit-stamp column format** (mandatory for UPDATE and INSERT; not required for DELETE)
- **WHERE clause validation** (mandatory for UPDATE and DELETE)
- **Record count verification** (mandatory comment before execution)
- **Transaction safety** (explicit transaction control — e.g. BEGIN TRANSACTION / COMMIT / ROLLBACK, or your database's equivalent)
- **Backup recommendations** (documented before execution)

**Never create SQL scripts without consulting `governance/SQL_Guidelines.md` first.**

If SQL script requirements are unclear → **flag and STOP.**

---

### 6.3 Accessibility Compliance (Mandatory)

> **Before writing any UI fix, read `governance/wcag-fix-patterns.md` — it is the primary reference for all accessibility code patterns in this project.**

All code fixes that touch the UI must comply with:

- **ADA** (Americans with Disabilities Act)
- **WCAG 2.1 AA** minimum
- **NVDA / screen reader compatibility**

This includes but is not limited to:

- Semantic HTML elements (`<button>`, `<label>`, `<fieldset>`, `<legend>` — never `<div>` as interactive)
- Proper ARIA usage (`aria-label`, `aria-hidden`, `aria-live`, `aria-expanded`, `aria-atomic`)
- Keyboard navigation (all interactive elements reachable and operable via keyboard)
- Focus management (focus moves logically; no focus traps)
- Color contrast (minimum 4.5:1 for normal text, 3:1 for large text)
- Accessible labels on all form fields (never `placeholder` as the sole label)
- Error messages associated with fields and announced to screen readers

For fix patterns, code examples, and the pre-push checklist → **`governance/wcag-fix-patterns.md`**

If accessibility impact is unclear → **flag and STOP.**

See `governance/coding-standards.md` for project-specific component patterns.

---

### 6.4 CSS & Theming Rules

- ✅ All CSS must be theme-based — use existing variables and utility classes
- ❌ No hard-coded colors (use CSS variables or theme tokens)
- ❌ No inline styles (unless the project explicitly allows for a specific case)
- ✅ Reuse existing utility classes before adding any new CSS
- ✅ Respect all themes: default, dark, high-contrast / accessibility themes, and any other active themes
- ✅ New CSS must be added with start/end comments identifying the change

---

### 6.5 File Creation Rules

- ❌ Do NOT introduce new files by default
- ✅ Reuse existing files whenever possible
- ✅ Only create new files if **explicitly required by the ticket**
- ✅ Clearly justify any new file creation to the user in chat as part of the pre-code analysis summary (this workspace's ticket model is chat-based — see Section 3 — there is no per-ticket `implementation-plan.md` file)

---

### 6.6 Third-Party Code Restrictions

- ❌ No new third-party libraries without explicit user approval
- ❌ No copied external code without licensing review
- ❌ No CDN additions without explicit justification

Exceptions require:
- Explicit user approval (documented in the ticket)
- Clear business justification
- License compatibility confirmed

---

## 7. Build & Validation Governance

> **CRITICAL:** Confirm the exact build tool and command for this project in `behavior/setting.md` — never assume a specific build tool without verifying it against the project's own solution/project files.

After completing code changes, a build is **mandatory**, scoped by ticket `Type` (per `AGENTS.md` Ticket Type Rules):

```powershell
# Bug — module solution only (unless shared libraries are touched, then full)
{{BUILD_COMMAND_MODULE}}

# Enhancement / CR — full solution mandatory
{{BUILD_COMMAND_FULL}}
```

| Outcome | Action |
|---|---|
| ❌ Build fails | STOP — report errors clearly — do NOT proceed to push |
| ✅ Build succeeds | Inform user — proceed to user review step |

No code may be pushed if the build is failing.

---

## 8. User Review & Push Control

Before pushing any code, ask the user:

> "Please review the changes.  
> Type **PUSH** when you are ready to push."

🚫 Code must **never** be pushed without the user explicitly typing:

```
PUSH
```

No other phrase, abbreviation, or confirmation is accepted as a substitute (the keyword itself is case-insensitive).

---

## 9. Push & PR Preparation

Only after receiving `PUSH`:

```bash
git push origin <branch-name>
```

Prepare a Pull Request using the template in `templates/pr-template.md`.

Minimum required sections:
- **Title:** `[TicketID] Short Description`
- Problem summary (from the chat ticket input)
- Solution implemented
- Affected files list
- Accessibility confirmation
- Build status (passed)
- Scope confirmation (what was intentionally NOT changed)
- Ticket link

---

## 10. Ticket ↔ PR Linking (Mandatory Steps)

After the PR is created, guide the user through these exact steps (UI labels vary by ticket tracker):

1. Open the ticket in the ticket tracker.
2. Use the tracker's option to add a web link / remote link to the ticket.
3. Paste the Pull Request URL.
4. Set description to:
   ```
   PR: <branch-name>
   ```

Example:
```
PR: <CR prefix>/PROJ-1234_Ticket_Title
```

---

## 11. Global Prohibitions

| Prohibition | Detail |
|---|---|
| ❌ No project-specific assumptions | This file is global; project specifics live in coding-standards.md |
| ❌ No environment-specific logic | Use the project's configuration mechanism (app settings / environment flags) — never hardcode environment values |
| ❌ No hard-coded values | Use constants, variables, or config |
| ❌ No silent merges | Every merge requires an approved PR |
| ❌ No undocumented behavior | Every decision made during implementation is communicated in chat |
| ❌ No commits without user review | Review step is mandatory before every push |
| ❌ No bypassing build validation | Build must pass; no exceptions |
| ❌ No ticket comments or notes — ever | **NEVER post any comment, note, or worklog to a ticket in the ticket tracker under any circumstances, for any ticket type (Bug, Enhancement, CR, Analysis), in any step of the workflow. The only exception is when the user explicitly types "add note in ticket" with the note content. Any auto-posting of ticket comments is strictly prohibited.** |

---

## 12. Conflict Resolution

If instructions in any other file conflict with this document:

1. This file (`governance/copilot-instruction.md`) **takes precedence**.
2. Flag the conflict to the user immediately.
3. Do not proceed until the conflict is resolved.

---

## ✅ End of Master Authority

---
