# SCM Workflow — {{PROJECT_NAME}}

> **Authority**: Verified from Git history, `.git/config`, and `AGENTS.md`.  
> **Last verified**: update this date whenever this file is regenerated.

---

## 1. Repository

| Setting | Value |
|---------|-------|
| **Remote** | `origin` |
| **URL** | `{{REPO_REMOTE_URL}}` |
| **Platform** | {{SCM_PLATFORM}} |
| **Project Prefix** | `PROJ` (replace with this project's actual ticket-tracker project key, and name the tracker) |

> Note: the URL value must always be the **full remote URL** (e.g. `https://bitbucket.org/workspace/repo`),
> never a short remote name such as `origin` (that is the separate "Remote" row above).

---

## 2. Branch Strategy

### Base Branches

| Branch | Purpose | Rules |
|--------|---------|-------|
| `{{BASE_BRANCHES}}` | Active development — **start ALL work here** | Pull before branching; all feature branches merge back here |
| `<production-release branch>` | Production releases | **Never commit directly** — merged from `{{BASE_BRANCHES}}` by release manager only |

> `{{BASE_BRANCHES}}` is populated per-project by `generators/create-scm-workflow.prompt.md` with the
> name of the branch that all work starts from and all PRs target (used inline everywhere in this
> file and in the other workflow files). The `<production-release branch>` placeholder in the second
> row (and in the prohibitions below) is replaced by the same generator with the project's real
> production-release branch name; if the project has no separate production-release branch, the
> generator removes that row and the production-release-specific prohibitions.

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
# Always start from {{BASE_BRANCHES}}
git checkout {{BASE_BRANCHES}}
git pull origin {{BASE_BRANCHES}}

# Create feature branch (prefix per {{BRANCH_PREFIX_TABLE}})
git checkout -b BUG/PROJ-####_Short_Title
```

> ⚠️ **Never start work on `<production-release branch>` or `master`.**

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
> ⛔ **Never push directly to `{{BASE_BRANCHES}}` or `<production-release branch>`.**
> ⛔ **Always wait for explicit "PUSH" approval** before pushing.

---

### Step 5 — Create Pull Request

**Target branch:** `{{BASE_BRANCHES}}` (always — never target `<production-release branch>`)

PR description template: [`.ai/templates/pr-template.md`](../templates/pr-template.md)

**Required PR fields:**

| Field | Value |
|-------|-------|
| **Title** | `[PROJ-####] Short description of change` |
| **Source branch** | `BUG/PROJ-####_Short_Title` |
| **Target branch** | `{{BASE_BRANCHES}}` |
| **Reviewers** | At least 1 reviewer required |
| **Description** | Use PR template — include ticket link |

---

### Step 6 — Link PR to the Ticket

After PR is created in {{SCM_PLATFORM}}, link it back to the ticket in the ticket tracker:
1. Open the ticket (`PROJ-####`)
2. In the ticket's development / linked-work section (UI labels vary by tracker), add a link and paste the {{SCM_PLATFORM}} PR URL

---

## 4. Prohibited Actions

| Action | Why Prohibited |
|--------|---------------|
| `git push --force` | Rewrites shared history — data loss risk |
| `git reset --hard` on pushed commits | Breaks other developers' history |
| Committing directly to `{{BASE_BRANCHES}}` | Bypasses review process |
| Committing directly to `<production-release branch>` | Bypasses release management |
| Pushing without build passing | Breaks CI for everyone |
| Amending published commits | Breaks pull histories |
| Committing `.vscode/mcp.json` | Contains API tokens — security risk |

---

## 5. Pre-Push Checklist

Before running `git push`:

```
□ Build passes: {{BUILD_COMMAND_FULL}} — zero errors
□ Commit message follows [PROJ-####] format
□ Branch created from {{BASE_BRANCHES}} (not `<production-release branch>` or master)
□ No .vscode/mcp.json staged for commit
□ No unintended files staged (check git status)
□ Explicit "PUSH" approval received from user
```

---

## 6. AI Automation Guardrails

When assisting with SCM operations, Copilot **must**:

- ✅ Pull `{{BASE_BRANCHES}}` before creating any branch
- ✅ Ask the user whether to stay on `{{BASE_BRANCHES}}` or create a new branch (A/B choice)
- ✅ Wait for explicit `yes` or `y` before committing
- ✅ Wait for explicit `PUSH` before pushing
- ✅ Ask for reviewer email addresses before creating the PR
- ✅ Always target `{{BASE_BRANCHES}}` for PR merge target

Copilot **must not**:

- ❌ Push without explicit user approval (the `PUSH` keyword)
- ❌ Create branches from `<production-release branch>` or `master`
- ❌ Use `--force` or `--no-verify` on any git operation
- ❌ Amend commits that have already been pushed
- ❌ Create a PR targeting `<production-release branch>` directly
