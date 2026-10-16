---
description: >
  Setup generator (run after create-knowledge-base.prompt.md). Determines the target project's
  ticket-type-to-branch-prefix mapping and its real source-control remote path, and produces
  .ai/governance/scm-workflow.md plus the matching references in every other file that documents
  branch naming or the repo remote.
---

# Create SCM Workflow

You will be invoked once, at integration time, to generate `.ai/governance/scm-workflow.md` for a
new project and to propagate the same branch-prefix and repo-remote facts into every other file in
this automation package that references them.

> **Prerequisite**: `create-knowledge-base.prompt.md` must already have run (for project name and
> general context). This generator does not depend on `create-coding-standards.prompt.md` or
> `create-build-settings.prompt.md`, but by convention runs after them in the documented
> installation order.

> **Self-deleting prompt.** After this file successfully writes
> `.ai/governance/scm-workflow.md` and propagates the branch-prefix/remote facts to every file
> listed below, delete this file from the target project's `.github/prompts/` folder (see
> **Step 6** below). Do not keep it around — a stale generator invites someone to re-run it later
> and overwrite workflow conventions that have since been hand-edited or kept current through
> normal ticket work.

---

## Your Job

1. Read `.ai/knowledge-base.md` for the project name and any already-recorded repo information.
   If it does not exist yet, stop and tell the user to run `create-knowledge-base.prompt.md` first.
2. Detect the git remote and ticket-type/branch-prefix convention (see **Detection Instructions**).
   Ask the user for anything that cannot be reliably detected — do not fabricate a remote URL, a
   Jira/ticket-tracker project prefix, or a branch-prefix scheme.
3. Write `.ai/governance/scm-workflow.md`, filling `{{BRANCH_PREFIX_TABLE}}`, `{{REPO_REMOTE_URL}}`,
   `{{BASE_BRANCHES}}`, and `{{SCM_PLATFORM}}` per the guidance already present in that file's own
   scaffold comments
   (read the existing `.ai/governance/scm-workflow.md` scaffold shipped by this package before
   writing it — the "Project Prefix" row and the `{{BRANCH_PREFIX_TABLE}}` placeholder's own
   comment explain exactly what content each must contain: placeholder values, example branch
   names, and the full ticket-type reference table).
4. Propagate `{{BRANCH_PREFIX_TABLE}}`, `{{REPO_REMOTE_URL}}`, `{{BASE_BRANCHES}}`, and
   `{{SCM_PLATFORM}}` into every other file that
   references them (see **Files You Must Touch** below — this is the authoritative, verified
   list; do not rely on assumption or touch only `scm-workflow.md`).
5. Report to the user: the detected (or user-provided) remote URL/platform, the base-branch
   name(s), the branch-prefix mapping used, and which files were updated.
6. Delete this generator prompt file from the project's `.github/prompts/` folder.

---

## Detection Instructions

Do not assume any single source-control platform or branch-prefix scheme. Detect or ask for:

> **No git repository yet?** The detection steps below use `git remote -v`, `git branch -a`, and
> `git log`. If `CODE_ROOT` is not inside a git repository (no `.git` folder), do not attempt those
> commands. Ask the user directly for the remote URL (or "none yet"), the platform, the ticket-type
> branch prefixes, and the base-branch names. This is expected, not an error. If the user answers
> "none yet", write the literal string `<remote URL not yet configured>` as the value of
> `{{REPO_REMOTE_URL}}` (never leave it blank and never guess a URL), and list this in the final
> report as a pending item: the user must update the remote URL in
> `.ai/governance/scm-workflow.md` and the other files that carry it once a remote exists.

- **Git remote** — run (or ask the user to confirm the output of) `git remote -v` / inspect
  `.git/config` in `CODE_ROOT` for the `origin` remote URL. Identify the hosting platform from the
  URL shape (e.g. `bitbucket.org`, `github.com`, a self-hosted GitHub/Bitbucket/GitLab server
  domain) — do not assume Bitbucket or GitHub without evidence. Record the platform's display
  name (e.g. `Bitbucket`, `GitHub`, `GitLab`, `Azure DevOps`) as the value of `{{SCM_PLATFORM}}`.
  If no remote is configured yet
  (brand-new repo), ask the user for the intended remote path instead of leaving it blank; if the
  user answers "none yet", use the same `<remote URL not yet configured>` literal and pending-item
  reporting defined in the no-git-repository note above, so both cases produce the same value.
- **Ticket-tracker project prefix** — if the project uses Jira (or another ticket tracker with a
  short project-key convention), ask the user for the actual project key (e.g. the letters before
  the dash in a ticket ID like `PROJ-1234`) and the tracker's name. Do not invent one. The tracker
  is a separate system from the git host in some setups (e.g. Bitbucket + Jira), so the shipped
  workflow files refer to it generically as "the ticket tracker" and `{{SCM_PLATFORM}}` names only the
  git-hosting/PR platform; record the tracker's name and project key in the "Project Prefix" row
  of `.ai/governance/scm-workflow.md`.
- **Branch-prefix-per-ticket-type mapping** — ask the user (or detect from existing branch names
  in `git branch -a` / `git log --all --oneline --decorate` if the repository already has history)
  what prefix is used for each ticket type the project's workflow distinguishes (typically at
  minimum: Bug, Enhancement, Change Request — but confirm the actual set this project uses; some
  projects may have fewer or differently named types). Do not assume the `BUG`/`ER`/`CR` scheme —
  that is one project's convention, not a universal one.
- **Base branch names** — confirm the actual name of the "start all work here" branch and the
  "production releases" branch for this project (commonly `main`/`master`/`develop`/`Development`,
  but verify rather than assume — check `git branch -a` or ask the user). The "start all work here"
  branch (the one every ticket branches from and every PR targets) is the value of
  `{{BASE_BRANCHES}}`; the production-release branch name replaces the `<production-release branch>`
  placeholder in `.ai/governance/scm-workflow.md`. If the project has no separate production-release
  branch, ask the user and remove the production-release row and prohibitions instead of guessing.

If any of the above cannot be reliably detected from the repository itself, ask the user directly
— these facts (remote path, ticket prefix, branch-prefix scheme) are operationally critical (they
drive every branch/PR the automated workflow creates) and must never be guessed.

---

## Content to Populate in `.ai/governance/scm-workflow.md`

- **`{{REPO_REMOTE_URL}}`** — the real, **full** remote URL (never a short remote name such as
  `origin`), e.g. `https://bitbucket.org/<workspace>/<repo-slug>` or
  `https://github.com/<org>/<repo>`, used verbatim in the "Repository" table and anywhere else in this file that references it.
- **`{{BRANCH_PREFIX_TABLE}}`** — replace the generic `PROJ` placeholder and the single
  `<TYPE>` example with this project's actual ticket-type-to-prefix mapping: a "Type Reference"
  table (prefix → ticket type → when to use), real branch-name examples using the project's actual
  ticket prefix, and update the "Project Prefix" row in the Repository table and all workflow-step
  example commands (`git checkout -b <PREFIX>/<TicketID>_Short_Title`, commit message format,
  PR title format) to use the real prefix/ticket-ID pattern instead of the `PROJ`/`BUG` placeholders
  — also update the base-branch names throughout the file if they differ from the scaffold's
  `{{BASE_BRANCHES}}`/`<production-release branch>` placeholders.
- **`{{BASE_BRANCHES}}`** — the name of the "start all work here" branch only (a single branch name,
  no backticks or punctuation), used inline in commands, prose, and table cells in every file
  listed below.
- **`{{SCM_PLATFORM}}`** — the git-hosting/PR platform's display name (e.g. `Bitbucket`), used inline
  in prose wherever the workflow refers to the platform (PR creation, MCP server, review). It does
  not name the ticket tracker.

**Inline vs. block usage.** Some of these tokens appear as their own block in one file and inside a
sentence in another (for example, `{{BRANCH_PREFIX_TABLE}}` is a full table in
`.ai/governance/scm-workflow.md` but sits inline in `AGENTS.md` and
`.github/copilot-instructions.md`). When a token appears inline in a sentence rather than as its own
block, produce a concise inline-appropriate phrasing of the same fact (for example, a one-line list of this project's real prefixes followed by
the ticket ID), not the full block verbatim. The facts must stay identical
across files; only the length and shape adapt to the position.

---

## Files You Must Touch

Verified directly against this package's `core/` content — every file in the shipped package that
references these tokens:

| Token | Files to update |
|---|---|
| `{{BRANCH_PREFIX_TABLE}}` | `AGENTS.md` (branch-naming references in the automated-workflow summary and the "Source Control Workflow" section), `README.md` (At a Glance table), `.ai/governance/scm-workflow.md` (full branch-strategy section), `.github/copilot-instructions.md` (ticket-type table Branch column) |
| `{{REPO_REMOTE_URL}}` | `README.md` (At a Glance table), `.ai/governance/scm-workflow.md` (Repository table), `.github/agents/ticket-processor.agent.md` (PR-creation instructions, twice), `.github/prompts/pr-review.prompt.md` (SCM remote reference) |
| `{{BASE_BRANCHES}}` | `README.md` (At a Glance table), `AGENTS.md` (ticket-type branch-naming lines "from `{{BASE_BRANCHES}}`", workflow step 5, branch-strategy bullet, Critical Gotchas branch rule), `.ai/governance/scm-workflow.md` (Base Branches table, workflow steps, prohibitions, checklist, guardrails), `.github/agents/ticket-processor.agent.md` (STEP 4 branch check/prompt/table, PR `destinationBranch`, STOP table, completion next-steps, example), `.ai/behavior/decision-rules.md` (STOP #4, PROCEED checklist), `.ai/governance/copilot-instruction.md` (Section 5.1 branch validation, Section 5.4 Analysis branch table and prompts), `.github/prompts/pr-review.prompt.md` (target-branch check), `.github/copilot-instructions.md` (ticket-type table Branch column and the per-type "Must be on ... branch before starting" rules) |
| `{{SCM_PLATFORM}}` | `.ai/governance/scm-workflow.md` (Repository table "Platform" row, Step 6 PR-linking), `.github/agents/ticket-processor.agent.md` (PR-creation instructions, CLI MCP note, completion steps, Integration section), `AGENTS.md` (CLI MCP-server note, MCP Setup section), `README.md` (At a Glance table, MCP Setup section), `.github/prompts/pr-review.prompt.md` (description, intro, details heading, platform line, closing note) |

`{{CODING_STANDARDS_BODY}}` and `{{THEME_FOLDERS}}` are owned by
`create-coding-standards.prompt.md`; `{{BUILD_COMMAND_FULL}}`, `{{BUILD_COMMAND_MODULE}}`,
`{{SOLUTION_FILES}}`, `{{BUILD_SCOPE_RULES}}`, `{{RISK_THRESHOLDS}}`, and `{{STACK_CHECKLIST}}` are
owned by `create-build-settings.prompt.md` — do not edit those tokens even if they appear in a
file you are otherwise updating (e.g. `AGENTS.md`, `.github/agents/ticket-processor.agent.md`,
`.github/prompts/pr-review.prompt.md`).

---

## Step 6: Self-Delete

Once `.ai/governance/scm-workflow.md` and every file in the table above has been updated and you
have reported the summary to the user, delete this file (`create-scm-workflow.prompt.md`) from
the target project's `.github/prompts/` folder. This generator is single-use; leaving it in place
risks someone re-running it later and clobbering SCM workflow conventions that have since been
hand-edited or kept current through normal ticket work.
