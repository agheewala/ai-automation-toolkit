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
> listed below, delete this file from the target project's `.github/prompts/` folder (see the
> final step below). Do not keep it around — a stale generator invites someone to re-run it later
> and overwrite workflow conventions that have since been hand-edited or kept current through
> normal ticket work.

---

## Your Job

1. Read `.ai/knowledge-base.md` for the project name and any already-recorded repo information.
   If it does not exist yet, stop and tell the user to run `create-knowledge-base.prompt.md` first.
2. Detect the git remote and ticket-type/branch-prefix convention (see **Detection Instructions**).
   Ask the user for anything that cannot be reliably detected — do not fabricate a remote URL, a
   Jira/ticket-tracker project prefix, or a branch-prefix scheme.
3. Write `.ai/governance/scm-workflow.md`, filling `{{BRANCH_PREFIX_TABLE}}` and
   `{{REPO_REMOTE_NAME}}` per the guidance already present in that file's own scaffold comments
   (read the existing `.ai/governance/scm-workflow.md` scaffold shipped by this package before
   writing it — the "Project Prefix" row and the `{{BRANCH_PREFIX_TABLE}}` placeholder's own
   comment explain exactly what content each must contain: placeholder values, example branch
   names, and the full ticket-type reference table).
4. Propagate `{{BRANCH_PREFIX_TABLE}}` and `{{REPO_REMOTE_NAME}}` into every other file that
   references them (see **Files You Must Touch** below — this is the authoritative, verified
   list; do not rely on assumption or touch only `scm-workflow.md`).
5. Report to the user: the detected (or user-provided) remote URL/platform, the branch-prefix
   mapping used, and which files were updated.
6. Delete this generator prompt file from the project's `.github/prompts/` folder.

---

## Detection Instructions

Do not assume any single source-control platform or branch-prefix scheme. Detect or ask for:

- **Git remote** — run (or ask the user to confirm the output of) `git remote -v` / inspect
  `.git/config` in `CODE_ROOT` for the `origin` remote URL. Identify the hosting platform from the
  URL shape (e.g. `bitbucket.org`, `github.com`, a self-hosted GitHub/Bitbucket/GitLab server
  domain) — do not assume Bitbucket or GitHub without evidence. If no remote is configured yet
  (brand-new repo), ask the user for the intended remote path instead of leaving it blank.
- **Ticket-tracker project prefix** — if the project uses Jira (or another ticket tracker with a
  short project-key convention), ask the user for the actual project key (e.g. the letters before
  the dash in a ticket ID like `PROJ-1234`). Do not invent one.
- **Branch-prefix-per-ticket-type mapping** — ask the user (or detect from existing branch names
  in `git branch -a` / `git log --all --oneline --decorate` if the repository already has history)
  what prefix is used for each ticket type the project's workflow distinguishes (typically at
  minimum: Bug, Enhancement, Change Request — but confirm the actual set this project uses; some
  projects may have fewer or differently named types). Do not assume the `BUG`/`ER`/`CR` scheme —
  that is one project's convention, not a universal one.
- **Base branch names** — confirm the actual name of the "start all work here" branch and the
  "production releases" branch for this project (commonly `main`/`master`/`develop`/`Development`,
  but verify rather than assume — check `git branch -a` or ask the user).

If any of the above cannot be reliably detected from the repository itself, ask the user directly
— these facts (remote path, ticket prefix, branch-prefix scheme) are operationally critical (they
drive every branch/PR the automated workflow creates) and must never be guessed.

---

## Content to Populate in `.ai/governance/scm-workflow.md`

- **`{{REPO_REMOTE_NAME}}`** — the real remote URL/path (e.g.
  `https://bitbucket.org/<workspace>/<repo-slug>` or `https://github.com/<org>/<repo>`), used
  verbatim in the "Repository" table and anywhere else in this file that references it.
- **`{{BRANCH_PREFIX_TABLE}}`** — replace the generic `PROJ` placeholder and the single
  `<TYPE>` example with this project's actual ticket-type-to-prefix mapping: a "Type Reference"
  table (prefix → ticket type → when to use), real branch-name examples using the project's actual
  ticket prefix, and update the "Project Prefix" row in the Repository table and all workflow-step
  example commands (`git checkout -b <PREFIX>/<TicketID>_Short_Title`, commit message format,
  PR title format) to use the real prefix/ticket-ID pattern instead of the `PROJ`/`BUG` placeholders
  — also update the base-branch names throughout the file if they differ from `Development`/
  `Release`.

---

## Files You Must Touch

Verified directly against this package's `core/` content — every file in the shipped package that
references these tokens:

| Token | Files to update |
|---|---|
| `{{BRANCH_PREFIX_TABLE}}` | `AGENTS.md` (branch-naming references in the automated-workflow summary and the "Source Control Workflow" section), `.ai/governance/scm-workflow.md` (full branch-strategy section) |
| `{{REPO_REMOTE_NAME}}` | `.ai/governance/scm-workflow.md` (Repository table), `.github/agents/ticket-processor.agent.md` (PR-creation instructions, twice), `.github/prompts/pr-review.prompt.md` (SCM remote reference) |

`{{CODING_STANDARDS_BODY}}` and `{{THEME_FOLDERS}}` are owned by
`create-coding-standards.prompt.md`; `{{BUILD_COMMAND_FULL}}`, `{{BUILD_COMMAND_MODULE}}`,
`{{SOLUTION_FILES}}`, `{{BUILD_SCOPE_RULES}}`, `{{RISK_THRESHOLDS}}`, and `{{STACK_CHECKLIST}}` are
owned by `create-build-settings.prompt.md` — do not edit those tokens even if they appear in a
file you are otherwise updating (e.g. `AGENTS.md`, `.github/agents/ticket-processor.agent.md`,
`.github/prompts/pr-review.prompt.md`).

---

## Step: Self-Delete

Once `.ai/governance/scm-workflow.md` and every file in the table above has been updated and you
have reported the summary to the user, delete this file (`create-scm-workflow.prompt.md`) from
the target project's `.github/prompts/` folder. This generator is single-use; leaving it in place
risks someone re-running it later and clobbering SCM workflow conventions that have since been
hand-edited or kept current through normal ticket work.
