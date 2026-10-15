---
description: >
  Review a Bitbucket pull request using the {{PROJECT_NAME}} two-phase process:
  code-level observations + governance & workflow compliance checks.
  Just provide the PR URL and the review is generated automatically.
---

# PR Review — {{PROJECT_NAME}}

You will be invoked when the user provides a Bitbucket PR URL to review.

---

## Your Job

Fetch the PR details and diff from Bitbucket, then produce a unified review
covering both code quality and governance compliance in a single numbered list.

---

## Bitbucket Details

This repo's SCM remote is `{{REPO_REMOTE_NAME}}` (see `.ai/governance/scm-workflow.md` Section 1
for the exact workspace/repo-slug breakdown). Platform: Bitbucket Cloud.

Extract `pull_request_id` from the URL the user provides (e.g. `.../pull-requests/350/diff` → ID is `350`).

---

## Step 1 — Fetch PR Data (run in parallel)

- `get_pull_request_review_summary` — PR metadata, diffstat, CI statuses, unresolved comments
- `get_pull_request_diff` — full unified diff

---

## Step 2 — Phase 1: Code Analysis

Analyse the diff for:

- Logic correctness and regression risk at **all call sites** (not just the intended fix site)
- Behavior changes introduced silently by passing `null` or default values to refactored signatures
- Null / edge case handling
- Variable and method naming clarity
- Unused imports or dead code
- Missing test coverage for new branches or conditions

---

## Step 3 — Phase 2: Governance & Workflow Compliance

Cross-check against the repo governance files in this **priority order**:

### 1. `.ai/governance/copilot-instruction.md` (Master Authority)
- PR description must contain ticket context (expected vs actual behaviour, scope summary)
- Scope containment — only what the ticket requires should be changed
- No silent behaviour changes — every decision must be traceable

### 2. `.ai/behavior/decision-rules.md`
- **STOP #8**: Bug fix touching more than 3 files → flag scope for confirmation
- **FLAG**: Cross-module impact → must be explicitly called out
- **FLAG**: Payment / financial-critical logic changed → recommend feature flag

### 3. `.ai/governance/coding-standards.md`
- C# naming: PascalCase for all methods, interfaces, and classes
- No business logic in controllers — delegate to service layer
- Interface-first pattern (ICommand / IQuery) must be followed

### 4. `.ai/governance/scm-workflow.md`
- Branch naming: prefix per `.ai/governance/scm-workflow.md` + `<TicketID>_<Short_Title>`
- Target branch must be `Development`
- Build evidence must exist before PR is raised

### 5. `.ai/behavior/setting.md` (Risk Posture)
- Build gate: `{{BUILD_COMMAND_MODULE}}` or the full `{{BUILD_COMMAND_FULL}}` — scope depends on ticket Type per `AGENTS.md`. Solution file names: {{SOLUTION_FILES}}. Confirm the exact build tool (MSBuild vs `dotnet build`) against `.ai/behavior/setting.md` for this project's stack.
- No automated test projects exist in this workspace (confirmed in `.ai/behavior/setting.md` Section 5) — do not expect a test gate; flag if the PR claims automated test coverage that doesn't exist, and verify manual regression evidence instead
- Flag if no build evidence (build output/log) is visible in the PR description or pipeline

### 6. `.github/skills/patterns/SKILL.md` (Code Patterns)
- Domain constants must be used — never hardcoded strings
- Changes must follow existing codebase patterns

---

## Step 4 — Output Format (MANDATORY)

Present findings as a **single unified numbered list**. Do NOT produce two separate
sections. Do NOT produce a compliance table.

Each observation point:
- States the **code finding** clearly and concisely
- If a governance/workflow rule applies, append a one-line `> Governance:` note

Observations that are purely governance violations (no code counterpart) are
included as standalone numbered points prefixed with `> Governance:`.

### Example

**1. Null currency silently disables `IsCreditcardPaymentdone` for 5 call sites**
All callers passing `null` will never enter the VALID/PAID block — potential
regression for cart payment, dashboard, and electronic payment flows.
> Governance: `decision-rules.md` — cross-module impact not flagged before proceeding;
> `copilot-instruction.md` — silent behaviour change not documented in PR description.

**2. PR description is empty**
No expected vs actual behaviour, no scope summary provided — makes the PR
untraceable to a business requirement.
> Governance: `copilot-instruction.md` (master) — PR description is required for scope
> and compliance traceability.

---

## Notes

- Always read the governance files from the workspace (`.ai/` folder) for the latest rules.
- If the PR targets a different repo or workspace, adapt the Bitbucket parameters accordingly.
- CI status (Snyk, build) is noted but does NOT replace the governance compliance check —
  Snyk only covers dependency vulnerabilities, not logic or workflow compliance.
