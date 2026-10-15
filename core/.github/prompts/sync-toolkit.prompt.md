---
description: Install or update the AI Automation Toolkit in this project.
---

# /sync-toolkit

Installs the AI Automation Toolkit into this project (**install mode**) or brings an existing
installation up to a newer toolkit version (**update mode**).

> **No scripts.** Every action in this prompt is performed by you, the agent, through your own
> tool calls (`read_file`, `create_file`, file edits, and `run_in_terminal` for read-only git
> queries only). Never write or run an external `.ps1` / `.sh` / `.py` script to copy files,
> run generators, or write state files.

> **Never commit or push.** This prompt never runs `git add`, `git commit`, or `git push` in this
> project. It ends by reporting what changed so the user can review and commit in their own repo.

---

## Arguments

Parse these from the user's invocation text:

- `--source <path>` (**required**): local filesystem path to a clone of the `ai-automation-toolkit`
  repo. If missing, ask the user for it — do not guess.
- `--version <tag>` (optional, **update mode only**): git tag to sync to. Defaults to the source
  clone's current `VERSION` file content if omitted. In install mode this argument is ignored; if
  the user supplied it, tell them so, and remind them that install uses whatever the source clone
  currently has checked out.
- `--mode install|update` (optional): if omitted, auto-detect — `install` if
  `.ai/.toolkit-sync-state/version.json` does not exist in this project, `update` otherwise.
  If the user explicitly passes `--mode install` but `version.json` already exists, stop and warn
  that a re-install would overwrite customized Tier 2 files; continue only on explicit
  confirmation, and in that case treat every existing destination file as a conflict (see
  Install Step 4).

After parsing, verify `<source>` contains `manifest.json`, `VERSION`, `core/`, `generators/`,
`stacks/`, and `data-dictionary-tooling/`. If any is missing, stop and report which one.

Then branch on the resolved mode: run **Install Mode** or **Update Mode** below.

---

## Shared Conventions

These definitions are used by both modes. Do not redefine them in a mode section.

**Path mapping.** `manifest.json` lists files under two different roots:

| Manifest entry | Source location | Location in this project |
|---|---|---|
| Tier 2 entries (e.g. `.github/agents/ticket-processor.agent.md`, `AGENTS.md.template`) | `<source>/core/<entry>` | `<entry>`, with a trailing `.template` suffix stripped (`AGENTS.md.template` → `AGENTS.md`, `.github/copilot-instructions.md.template` → `.github/copilot-instructions.md`) |
| Tier 1 entries starting `generators/`, `data-dictionary-tooling/`, or `stacks/` | `<source>/<entry>` | `<entry>` (same relative path, no stripping) |
| Tier 1 entries found under `core/` (none today; future-proofing) | `<source>/core/<entry>` | `<entry>`, `.template` stripped |
| Tier 3 patterns (`.ai/knowledge-base.md`, `.ai/data-dictionary/**`) | never copied | produced by generators; **never touched by sync** |

An entry's source location is `<source>/<entry>` if that file exists, otherwise
`<source>/core/<entry>`. If neither exists, stop and report the manifest/source mismatch.

**Whole-`core/` rule.** Install copies **every** file under `<source>/core/` — not only the files
named in `manifest.json`. A `core/` file absent from the manifest is a toolkit bug: still copy it,
and list it in your final report under "Files not classified in manifest.json".

**Sync state** lives in `.ai/.toolkit-sync-state/` in this project:

- `version.json` — `{ "toolkitVersion": "<string>", "stack": "<string>", "syncedAt": "<ISO 8601 UTC>" }`
- `baseline/` — a pristine copy of every Tier 2 file exactly as it exists in `<source>/core/`,
  **stored under its manifest path** (so `AGENTS.md.template` stays `AGENTS.md.template`, with its
  `{{...}}` placeholders unfilled). This is the common ancestor for update mode's 3-way merge. It
  is never edited by hand and never contains this project's filled-in content.

---

<!-- ============================================================================
     SECTION: INSTALL MODE
     Owned by Task 15. Update Mode (Task 16) and 3-way merge (Task 17) are separate
     sections below this one; do not add their logic inside this section.
     ============================================================================ -->

## Install Mode

Follow these steps in order. If any step fails, stop and report — do **not** write
`.ai/.toolkit-sync-state/version.json` unless every step through Step 8 completed (its absence is
what makes a re-run detect install mode again).

### Step 1 — Read the manifest

Read `<source>/manifest.json` and `<source>/VERSION`. Extract the Tier 1 `files` list, the Tier 2
`files` list, and the Tier 3 `patterns` list. These lists — not your own guesses — define what
"Tier 1" and "Tier 2" mean for the rest of this procedure.

### Step 2 — Gather inputs (ask once, up front)

Ask the user for everything below in a single round, then reuse the answers; do not re-ask later.

1. **Stack overlay.** List the folders under `<source>/stacks/` and ask which one applies. If none
   fits, the user may choose "none" (skip the overlay; record `"stack": "none"`).
2. **Project name** (`PROJECT_NAME`) — also used by the knowledge-base generator.
3. **System description** (`SYSTEM_DESCRIPTION`), **PVD/design-doc paths** (`PVD_PATHS`, or
   `none`), and **code root** (`CODE_ROOT`) — the knowledge-base generator's configuration block.
4. **Required Copilot model(s)** for the ticket workflow, as the value for the `model:`
   frontmatter field (`{{REQUIRED_MODEL_LIST}}`). Ask for a single model name or a list.

Do not fabricate any of these. If the user does not know one, record it as pending in the final
report instead of inventing a value.

### Step 3 — Copy `core/`, the stack overlay, and the DB tooling

Using the **Path mapping** in Shared Conventions:

1. For **every file under `<source>/core/`** (walk the whole tree; do not copy only the manifest's
   subset), read it and create it in this project at its `core/`-stripped path, removing a
   trailing `.template`. Create folders as needed.
2. Copy every file under `<source>/stacks/<chosen-stack>/` to `stacks/<chosen-stack>/` in this
   project (skip if the stack is `none`). Other stacks' folders are not copied.
3. Copy every file under `<source>/data-dictionary-tooling/` to `data-dictionary-tooling/` in this
   project, verbatim.
4. Copy files **byte-for-byte except for** the `{{PROJECT_NAME}}`, `{{REQUIRED_MODEL_LIST}}` and
   `{{PROJECT_SPECIFIC_FIXES}}` substitutions in Step 5.

### Step 4 — Handle pre-existing destination files

Before writing any destination file that already exists in this project, compare it with what you
would write. Identical → skip silently (this is expected for this prompt file itself, which the
user copied in manually). Different → **do not overwrite silently**: collect all such conflicts,
show the list, and ask the user, per file or for all, to choose **keep existing** (record it as
skipped in the report, and note it will not be reflected in the baseline's merge expectations),
**overwrite**, or **save toolkit version alongside as `<name>.toolkit-new`** for manual merging.
Apply the choices, then continue.

Perform this check per file as part of Step 3, before each write.

### Step 5 — Fill sync-owned placeholders

Three placeholders have no generator that owns them, so install fills them directly in the
project's copies (never in `<source>`, and never in the baseline):

- `{{PROJECT_NAME}}` → the project name from Step 2, in every copied file that contains it.
- `{{REQUIRED_MODEL_LIST}}` → the model value from Step 2, in every copied file that contains it
  (the `model:` frontmatter of the ticket prompts). If the user gave none, leave the token and
  list it as pending.
- `{{PROJECT_SPECIFIC_FIXES}}` in `.ai/governance/custom-fixes.md` → replace with a single
  italic line stating that no project-specific fixes have been recorded yet. That file is
  hand-maintained afterward, per its own note.

Leave every other `{{...}}` token untouched; the generators in Step 6 own them. The only
exceptions are `{{MODULE_LIST}}`, `{{SHARED_LIBS}}` and `{{STACK_SUMMARY}}` in `AGENTS.md`, which
are filled in Step 6a.

### Step 6 — Run the generators, in this verified order

Each generator is a prompt file under `<source>/generators/`. **Read it from the source clone and
execute its instructions directly against this project** — do not copy it into this project first.
Reuse the Step 2 answers wherever a generator asks for `PROJECT_NAME`, `SYSTEM_DESCRIPTION`,
`PVD_PATHS` or `CODE_ROOT`; do not ask the user again.

Each generator ends with a "self-delete this file from `.github/prompts/`" step. Because you run
them from `<source>`, **skip that step** — there is nothing to delete in this project, and you must
never delete or modify anything inside `<source>`.

The order below was verified against each generator's own prerequisite text:

| # | Generator | Verified prerequisite |
|---|---|---|
| 1 | `create-knowledge-base.prompt.md` | None. Must run first: every other generator stops with "run create-knowledge-base first" if `.ai/knowledge-base.md` is missing. |
| 2 | `create-coding-standards.prompt.md` | Requires `.ai/knowledge-base.md`. |
| 3 | `create-build-settings.prompt.md` | Requires `.ai/knowledge-base.md` **and** the output of #2 (it reuses what the coding-standards generator found). |
| 4 | `create-scm-workflow.prompt.md` | Requires `.ai/knowledge-base.md` only; by convention runs after #2 and #3. |
| 5 | `create-implementation-patterns.prompt.md` | Requires `.ai/knowledge-base.md` only (it samples the codebase itself and checks `implement.prompt.md` for leftovers). |
| 6 | `create-domain-agent.prompt.md` | Requires `.ai/knowledge-base.md`; reads `.ai/governance/coding-standards.md` if present, so it must run after #2. |
| 7 | `create-data-dictionary.prompt.md` | No generator dependency, but needs user-supplied CSV exports from the user's database (it will pause and ask). Runs last. |

Rules for this order:

- #1 first, always. #2 before #3. #2 before #6.
- #4 and #5 may run at any point after #1; the table order is the recommended one.
- #7 is last because it pauses for user action (database engine question, CSV exports). If the user
  wants to defer it, skip it, continue to Step 7, and record "data dictionary: not generated" in
  the report with the instruction to run `create-data-dictionary.prompt.md` later. If the user's
  database is not SQL Server, that generator stops itself with a documented known-gap message —
  relay that message; this is not an install failure.
- If any of #1–#6 stops or fails, stop the whole install and report which generator failed and why.

**Step 6a — immediately after generator #1 completes:** fill the three remaining `AGENTS.md` placeholders from the
now-existing `.ai/knowledge-base.md` (not from re-scanning the code): `{{MODULE_LIST}}` (the
project's modules/components), `{{SHARED_LIBS}}` (shared libraries and any sign-off rule recorded
for them; also fill the same token in `.ai/behavior/decision-rules.md`), and `{{STACK_SUMMARY}}`
(one line: language, framework, UI, database). Use "not found in knowledge base" rather than
inventing content when it does not say.

### Step 7 — Make the generators available for later re-runs

Copy every `<source>/generators/*.prompt.md` to `generators/` in this project (same relative path,
per the manifest's Tier 1 entries). They are deliberately **not** placed in `.github/prompts/`:
the generators self-delete from that folder after running, and must not be exposed as live slash
commands in the project. To re-run one later, tell Copilot to execute the instructions in
`generators/<name>.prompt.md` and skip its self-delete step.

### Step 8 — Write the sync state

1. Create `.ai/.toolkit-sync-state/version.json`:
   ```json
   { "toolkitVersion": "<contents of <source>/VERSION, trimmed>", "stack": "<chosen stack or none>", "syncedAt": "<current ISO 8601 UTC timestamp>" }
   ```
   Use the current date/time available to you; if you cannot determine it, ask the user.
2. Create `.ai/.toolkit-sync-state/baseline/`. For **every Tier 2 file in the manifest**, copy the
   file from `<source>/core/<manifest-path>` into `baseline/<manifest-path>` exactly as it is in
   the source (placeholders unfilled, `.template` suffix kept). Do not copy from this project's
   filled-in versions. Do not put Tier 1 or Tier 3 files in the baseline.

### Step 9 — Stop and report

Do **not** run `git add`, `git commit` or `git push`. Print a summary containing:

- Toolkit version and stack installed.
- Every file created, grouped as: core files, stack overlay, data-dictionary tooling, generators,
  sync state (`version.json` + baseline file count).
- Files skipped or saved as `.toolkit-new` in Step 4.
- Each generator that ran and its outcome, plus any skipped (e.g. data dictionary).
- Placeholders still pending (any remaining `{{...}}` token in the project's files — search for
  them and list file + token).
- Files copied from `core/` that were not classified in `manifest.json`.
- A closing instruction: review the changes and commit them in this repo yourself; this command
  made no commits.

---

<!-- ============================================================================
     SECTION: UPDATE MODE  (Task 16 — not yet implemented)
     ============================================================================ -->

## Update Mode

*Not implemented in this version of the prompt.* If the resolved mode is `update`, tell the user
that update mode is not yet available, make no changes, and stop.

<!-- ============================================================================
     SECTION: 3-WAY MERGE  (Task 17 — not yet implemented; invoked from Update Mode for Tier 2 files)
     ============================================================================ -->
