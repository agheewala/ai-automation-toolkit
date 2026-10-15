# ADA Workflow — BrowserStack Accessibility Fix Workflow

> Defines the step-by-step process the AI follows for BrowserStack ADA fix operations.  
> Authority: Defers to `governance/copilot-instruction.md`.

---

## 1. Invocation Modes

Use the specific `/fixada-*` command that matches your source. Each command triggers a dedicated mode — there is no ambiguity.

| Command | Mode | When to Use |
|:--------|:-----|:------------|
| `/fixada-file <path\scan.csv>` | File | Single CSV BrowserStack export |
| `/fixada-folder <path\folder\>` | Folder | All CSV files in a folder |
| `/fixada-results <https://...>` | Results | Pull violations from a BrowserStack URL |
| `/fixada-preventive <path\>` | Preventive | Pre-scan code check — no BrowserStack report needed |

**Alias also accepted** (routes to same workflow, mode auto-detected from argument):
```
fixadaissue <path|url>
```

---

## 2. Workflow Steps

```
Step 1 — Parse Command
  ├─ Identify trigger: /fixada-file / /fixada-folder / /fixada-results / /fixada-preventive
  ├─ If alias `fixadaissue` used → infer mode from argument (.csv = file, folder = folder, http = results)
  ├─ Validate path or URL exists
  └─ Confirm required env vars (results mode only)

Step 2 — Branch Strategy (Ask User)
  ├─ Option 1: Git worktree (recommended)
  │     └─ How many worktrees? (1–4)
  │           1 = all fixes, parallel work
  │           2–4 = split by severity + parallel work
  ├─ Option 2: Single branch
  └─ Option 3: Current branch

Step 3 — Prerequisites Check
  ├─ PowerShell 7 (auto-install if missing)
  ├─ Git (user.name and user.email configured)
  ├─ Node.js 18+
  └─ Env vars (results mode): BROWSERSTACK_USERNAME, BROWSERSTACK_ACCESS_KEY

Step 4 — Load Violations
  ├─ /fixada-file: Read single CSV file
  ├─ /fixada-folder: Read all CSV files in folder
  ├─ /fixada-results: Fetch from BrowserStack API via URL
  └─ /fixada-preventive: Scan target path against prevention patterns

Step 5 — Triage
  ├─ Skip contrast violations (WCAG 1.4.3, 1.4.11)
  ├─ Skip already-fixed (CSV "Fix" column = ✅)
  └─ Sort by severity: Critical → Major → Moderate → Minor

Step 6 — Apply Fixes (3-Tier Priority per violation)
  ├─ Tier 1: governance/custom-fixes.md (project-specific)
  ├─ Tier 2: BrowserStack "How to fix" suggestion
  ├─ Tier 3: governance/wcag-fix-patterns.md (generic)
  └─ No safe fix → mark ❓ Manual Review

Step 7 — Validate
  ├─ Verify element exists in codebase
  ├─ Check fix matches element context
  └─ WCAG criterion satisfied

Step 8 — Review (Ask User)
  ├─ Show summary of all changes
  ├─ Options: Approve / Reject / Inspect individual files
  └─ On reject: all changes discarded safely

Step 9 — GitFlow
  ├─ Commit with formatted message (templates/commit-message.md)
  ├─ Push to remote
  └─ Create PR (templates/pr-template.md) linked to JIRA ticket

Step 10 — Update Tracking
  └─ Update CSV/Excel "Fix" column with status
```

---

## 3. Fix Status Values

| Status | Meaning |
|:-------|:--------|
| ✅ Fixed | Issue found and fixed in the codebase |
| ⛔ Excluded (contrast) | Contrast issue — requires design decision |
| ⏭️ Skipped | Outside scope or already fixed |
| ❓ Manual Review | No safe automatic fix available |
| 🔍 Not Found | Element not located in codebase |

---

## 4. Preventive Mode Detail

Used when no BrowserStack scan has been run yet.

**What it does:**
- Scans target path (or uncommitted changes) against prevention patterns from `governance/wcag-fix-patterns.md` and `governance/custom-fixes.md`
- Groups findings by WCAG criterion
- Offers report-only or apply-fixes mode

**When to use:**
- Before committing UI changes
- After writing a new view/template/component
- As a pre-PR check for accessibility regressions

---

## 5. Git Worktree — Parallel Work Guide

```
Problem: ADA fix takes time; you don't want to pause feature work.

Solution:
1. Start /fixada-file or /fixada-results command
2. Choose: git worktree, 1 worktree
3. Worktree created at: C:\...\{{PROJECT_NAME}}-ada-wt1\
4. ADA fixes run in the worktree
5. You immediately switch back to main workspace
6. Continue feature work — zero interruption

Result:
  Worktree → ADA fixes complete → PR created
  Main workspace → Feature branch continues unaffected
```

---

## 6. Learning System

When a fix resolves a violation on BrowserStack re-scan:

```
1. Developer confirms violation is resolved
2. Add the working fix to governance/custom-fixes.md
3. Future ADA fix runs use this proven fix first (Tier 1)
4. Team knowledge accumulates over time
```

---

## 7. Exclusions (Never Fix Automatically)

| WCAG Criterion | Type | Reason |
|:---------------|:-----|:-------|
| 1.4.3 Contrast (Minimum) | Color contrast | Design decision required |
| 1.4.11 Non-text Contrast | Component contrast | Design decision required |

---

## Version

| Field | Value |
|:------|:------|
| **Created** | populate with the date this file was (re)generated |
| **Last Updated** | populate with the date this file was last regenerated |
| **Scope** | Global — all modules ({{MODULE_LIST}}) |

---
