# SCM Workflow — {{PROJECT_NAME}}

> **Authority**: Verified from Git history, `.git/config`, and `AGENTS.md`.  
> **Last verified**: update this date whenever this file is regenerated.

---

## 1. Repository

| Setting | Value |
|---------|-------|
| **Remote** | `origin` |
| **URL** | `{{REPO_REMOTE_NAME}}` |
| **Platform** | Bitbucket |
| **Project Prefix** | `PROJ` (replace with this project's actual Jira project key) |

---

## 2. Branch Strategy

### Base Branches

| Branch | Purpose | Rules |
|--------|---------|-------|
| `Development` | Active development — **start ALL work here** | Pull before branching; all feature branches merge back here |
| `Release` | Production releases | **Never commit directly** — merged from Development by release manager only |

### Feature Branch Naming

```
<TYPE>/<TicketID>_<Short_Title>
```

{{BRANCH_PREFIX_TABLE}}

> `{{BRANCH_PREFIX_TABLE}}` is populated per-project by `generators/create-scm-workflow.prompt.md`
> with this project's actual ticket-type-to-branch-prefix mapping (placeholder values, example
> branch names, and the Type Reference table) — do not hardcode any single project's prefixes
> (e.g. `BUG`/`ER`/`CR`) in this `core/` file.

> **Analysis tickets** do not require a branch — they are investigation-only and produce no code changes.

---

## 3. Workflow Steps

### Step 1 — Start Work

```powershell
# Always start from Development
git checkout Development
git pull origin Development

# Create feature branch (prefix per {{BRANCH_PREFIX_TABLE}})
git checkout -b BUG/PROJ-####_Short_Title
```

> ⚠️ **Never start work on `Release` or `master`.**

---

### Step 2 — Implement & Build

Make code changes, then validate build before committing:

```powershell
# Build validation (must pass — zero errors)
{{BUILD_COMMAND_FULL}}

# OR build a single module (if only one module changed)
{{BUILD_COMMAND_MODULE}}
```

> **Build must pass before ANY commit.** Do not commit code with build errors.

---

### Step 3 — Commit

```powershell
git add -A
git commit -m "[PROJ-####] Imperative description of change"
```

**Commit message format:**

```
[PROJ-####] Imperative short description (50 chars max)
```

**Rules:**
- Ticket ID in square brackets — mandatory
- Imperative mood: "Fix", "Add", "Update", "Remove" (not "Fixed", "Added")
- 50 characters or fewer for the subject line
- No trailing period

**Examples:**
```
[PROJ-1252] Fix null reference on order group load
[PROJ-2001] Add export button to order group grid
[PROJ-3500] Update search filter to include customer ID lookup
[PROJ-4100] Add aria-label to close modal button
```

Full commit template: [`.ai/templates/commit-message.md`](../templates/commit-message.md)

---

### Step 4 — Push Branch

```powershell
git push origin BUG/PROJ-####_Short_Title
```

> ⛔ **Never `git push --force`** on shared branches.  
> ⛔ **Never push directly to `Development` or `Release`.**  
> ⛔ **Always wait for explicit "PUSH BRANCH" or "PUSH" approval** before pushing.

---

### Step 5 — Create Pull Request

**Target branch:** `Development` (always — never target `Release`)

PR description template: [`.ai/templates/pr-template.md`](../templates/pr-template.md)

**Required PR fields:**

| Field | Value |
|-------|-------|
| **Title** | `[PROJ-####] Short description of change` |
| **Source branch** | `BUG/PROJ-####_Short_Title` |
| **Target branch** | `Development` |
| **Reviewers** | At least 1 reviewer required |
| **Description** | Use PR template — include Jira link |

---

### Step 6 — Link PR to Jira

After PR is created in Bitbucket, link it back to the Jira ticket:
1. Open the Jira ticket (`PROJ-####`)
2. Under **Development** panel → click **Link** → paste Bitbucket PR URL

---

## 4. Prohibited Actions

| Action | Why Prohibited |
|--------|---------------|
| `git push --force` | Rewrites shared history — data loss risk |
| `git reset --hard` on pushed commits | Breaks other developers' history |
| Committing directly to `Development` | Bypasses review process |
| Committing directly to `Release` | Bypasses release management |
| Pushing without build passing | Breaks CI for everyone |
| Amending published commits | Breaks pull histories |
| Committing `.vscode/mcp.json` | Contains API tokens — security risk |

---

## 5. Pre-Push Checklist

Before running `git push`:

```
□ Build passes: {{BUILD_COMMAND_FULL}} — zero errors
□ Commit message follows [PROJ-####] format
□ Branch created from Development (not Release or master)
□ No .vscode/mcp.json staged for commit
□ No unintended files staged (check git status)
□ Explicit "PUSH BRANCH" or "PUSH" approval received from user
```

---

## 6. AI Automation Guardrails

When assisting with SCM operations, Copilot **must**:

- ✅ Pull `Development` before creating any branch
- ✅ Ask the user whether to stay on `Development` or create a new branch (A/B choice)
- ✅ Wait for explicit `yes` or `y` before committing
- ✅ Wait for explicit `PUSH BRANCH` or `PUSH` before pushing
- ✅ Ask for reviewer email addresses before creating the PR
- ✅ Always target `Development` for PR merge target

Copilot **must not**:

- ❌ Push code without explicit user approval
- ❌ Create branches from `Release` or `master`
- ❌ Use `--force` or `--no-verify` on any git operation
- ❌ Amend commits that have already been pushed
- ❌ Create a PR targeting `Release` directly
