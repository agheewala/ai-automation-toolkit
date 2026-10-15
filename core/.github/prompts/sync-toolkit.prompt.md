---
description: Install or update the AI Automation Toolkit in this project.
---

# /sync-toolkit

Installs the AI Automation Toolkit into this project (**install mode**) or brings an existing
installation up to a newer toolkit version (**update mode**).

> **No scripts.** Every action in this prompt is performed by you, the agent, through your own
> tool calls (`read_file`, `create_file`, file edits, and `run_in_terminal` for git queries only —
> read-only `git -C <source>` commands, plus `git archive`/`tar` extraction into an OS temp
> staging folder during update mode). Never write or run an external `.ps1` / `.sh` / `.py` script to copy files,
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
| Tier 1 entries found under `core/` (today: `.github/prompts/sync-toolkit.prompt.md`) | `<source>/core/<entry>` | `<entry>`, `.template` stripped |
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
what makes a re-run detect install mode again). `version.json` is the very last file written, as
the atomic "install is done" marker.

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

### Step 3 — Plan the copy and scan for conflicts (dry run — write nothing)

Build the full list of destination files using the **Path mapping** in Shared Conventions:

1. For **every file under `<source>/core/`** (walk the whole tree; do not plan only the manifest's
   subset), the destination is its `core/`-stripped path, with a trailing `.template` removed.
2. For every file under `<source>/stacks/<chosen-stack>/`, the destination is
   `stacks/<chosen-stack>/<same relative path>` (skip if the stack is `none`). Other stacks'
   folders are not copied.
3. For every file under `<source>/data-dictionary-tooling/`, the destination is
   `data-dictionary-tooling/<same relative path>`.
4. Files are written **byte-for-byte except for** the `{{PROJECT_NAME}}`, `{{REQUIRED_MODEL_LIST}}`
   and `{{PROJECT_SPECIFIC_FIXES}}` substitutions in Step 5.

For each planned destination, check whether it already exists in this project. If it does,
compare it with the content you would write (including the Step 5 substitutions). Identical →
skip silently (expected for this prompt file itself, which the user copied in manually).
Different → add it to a **conflict list**. **Do not create, modify or overwrite any file in this
step.**

### Step 4 — Resolve conflicts, then copy

1. If the conflict list from Step 3 is non-empty, show it and ask the user, per file or for all,
   to choose **keep existing** (record it as skipped in the report, and note it will not be
   reflected in the baseline's merge expectations), **overwrite**, or **save toolkit version
   alongside as `<name>.toolkit-new`** for manual merging. Wait for the answer. (With an explicit
   `--mode install` over an existing install, every existing destination file is on this list.)
2. Only now perform the writes planned in Step 3: create every planned destination file (creating
   folders as needed), applying each conflict choice. Files with no conflict are simply created.
   Then continue to Step 5.

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
exceptions are `{{MODULE_LIST}}`, `{{SHARED_LIBS}}` and `{{STACK_SUMMARY}}`, which are filled in
Step 6a (in every file that contains them).

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

**Step 6a — immediately after generator #1 completes:** fill the three remaining placeholders from
the now-existing `.ai/knowledge-base.md` (not from re-scanning the code), **in every file of this
project that contains the token** (search the project's copied files; do not assume a single
file): `{{MODULE_LIST}}` (the project's modules/components — appears in `AGENTS.md` and
`.ai/behavior/ada-workflow.md`), `{{SHARED_LIBS}}` (shared libraries and any sign-off rule
recorded for them — appears in `AGENTS.md` and `.ai/behavior/decision-rules.md`), and
`{{STACK_SUMMARY}}` (one line: language, framework, UI, database). Use "not found in knowledge
base" rather than inventing content when it does not say.

### Step 7 — Make the generators available for later re-runs

Copy every `<source>/generators/*.prompt.md` to `generators/` in this project (same relative path,
per the manifest's Tier 1 entries). They are deliberately **not** placed in `.github/prompts/`:
the generators self-delete from that folder after running, and must not be exposed as live slash
commands in the project. To re-run one later, tell Copilot to execute the instructions in
`generators/<name>.prompt.md` and skip its self-delete step.

### Step 8 — Write the sync state

Order matters: the baseline is written first and `version.json` last, so that `version.json`
existing always means the baseline is complete.

1. Create `.ai/.toolkit-sync-state/baseline/`. For **every Tier 2 file in the manifest**, copy the
   file from `<source>/core/<manifest-path>` into `baseline/<manifest-path>` exactly as it is in
   the source (placeholders unfilled, `.template` suffix kept). Do not copy from this project's
   filled-in versions. Do not put Tier 1 or Tier 3 files in the baseline. Verify every Tier 2
   manifest entry now exists in `baseline/` before continuing.
2. **Last**, create `.ai/.toolkit-sync-state/version.json`:
   ```json
   { "toolkitVersion": "<contents of <source>/VERSION, trimmed>", "stack": "<chosen stack or none>", "syncedAt": "<current ISO 8601 UTC timestamp>" }
   ```
   Use the current date/time available to you; if you cannot determine it, ask the user.

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
     SECTION: UPDATE MODE  (Task 16 — detection + Tier 1 overwrite + interim summary)
     Tier 2 three-way merge, baseline refresh and the version.json bump are owned by the
     3-way merge section below (Task 17). Do not add them in this section.
     ============================================================================ -->

## Update Mode

Brings an existing installation up to the target toolkit version. This section handles
everything except Tier 2 merging: it detects missing, deprecated and unrecognized files, and
overwrites Tier 1 files. It ends with an interim summary and a hand-off to the **3-Way Merge**
section.

**State-safety rule (mirrors Install Mode's atomicity rule).** Update Mode steps 1–7 **never write
or modify anything under `.ai/.toolkit-sync-state/`** — neither `version.json` nor `baseline/`.
Both are refreshed only by the 3-Way Merge section, `baseline/` first and `version.json` last, once
Tier 2 handling is complete. Consequence: if this procedure is interrupted at any point,
`version.json` still names the old version, so a re-run simply repeats update mode; every step
below is idempotent (re-copying a missing file, re-overwriting a Tier 1 file and re-listing
deprecated/unrecognized files are all safe to repeat). Never write "partial done" state anywhere.

Use the **Path mapping**, **Whole-`core/` rule** and **Sync state** definitions from Shared
Conventions unchanged. Do not invent a different mapping for update mode.

### Step 1 — Read the installed state

Read `.ai/.toolkit-sync-state/version.json` in this project to get the installed `toolkitVersion`
and `stack`. If it is missing or unparseable, stop: this is not a completed install (re-run in
install mode). Also confirm `.ai/.toolkit-sync-state/baseline/` exists; if not, stop and report
the state as corrupt rather than reconstructing it.

Resolve the **target version**: `--version` if given, otherwise the content of
`<source>/VERSION` (trimmed). If the target equals the installed `toolkitVersion`, say so and ask
whether to continue as a drift check (Tier 1 files are re-checked and re-overwritten; Tier 2 is
re-merged against an unchanged baseline); stop if the user declines. If the target looks older
than the installed version, warn that this is a downgrade and continue only on explicit
confirmation.

### Step 2 — Obtain the target version's content without touching `<source>`'s working tree

Define **`<target>`** as a directory laid out exactly like a toolkit repo root (`manifest.json`,
`VERSION`, `core/`, `generators/`, `stacks/`, `data-dictionary-tooling/`). All later steps and the
3-Way Merge section read the target version only through `<target>`, using the same
`<target>/<entry>`-then-`<target>/core/<entry>` lookup the Path mapping defines for `<source>`.
Never check out, reset, stash or otherwise modify `<source>`'s working tree or branches.

1. **Optional refresh.** If `<source>` has a remote, run `git -C <source> fetch --tags`. This
   updates only refs and tag objects, never the working tree. If the fetch fails (offline / no
   remote), continue with the tags already present locally and note it in the report.
2. **Resolve the target.** Run `git -C <source> rev-parse --verify --quiet "<version>^{commit}"`.
   - **Resolves** → extract that version to a staging directory outside both repos (use the OS
     temp folder, e.g. `<temp>/toolkit-<version>/`; create it fresh, and stop if it already
     contains files). Extraction is byte-exact and **must go through a file, not a shell pipe**
     (PowerShell pipes corrupt binary tar streams):
     `git -C <source> archive --format=tar -o <temp>/toolkit-<version>.tar <version>` then
     `tar -xf <temp>/toolkit-<version>.tar -C <temp>/toolkit-<version>`. `<target>` is that
     staging directory.
   - **Does not resolve** → if `<version>` equals `<source>/VERSION` (the target is simply what
     the clone currently has checked out and was never tagged), set `<target>` = `<source>` and
     treat it as **read-only** — you only read from it. Otherwise stop and report that the
     version is not a tag or commit in `<source>`; list available tags
     (`git -C <source> tag --list`) for the user.
3. **Verify the target.** `<target>` must contain `manifest.json`, `VERSION`, `core/`,
   `generators/`, `stacks/` and `data-dictionary-tooling/` (same check as the Arguments section).
   If any is missing, stop and report which one. Confirm `<target>/VERSION` (trimmed) matches
   `<version>`; if it does not, warn and ask whether to continue.
4. **Read the target manifest.** Read `<target>/manifest.json`: the Tier 1 `files`, Tier 2
   `files`, Tier 3 `patterns` and the `deprecated` array. These lists, not guesses, define the
   tiers for the rest of update mode. Skip Tier 1 entries under `stacks/` that do not belong to
   this project's installed `stack` (Install copied only the chosen stack); if the installed
   stack is `none`, skip all `stacks/` entries; if the installed stack no longer exists under
   `<target>/stacks/`, report it and skip the overlay rather than switching stacks.

   Build the **target file set** the same way Install Step 3 builds its plan: every file under
   `<target>/core/` (destination = `core/`-stripped path with a trailing `.template` removed),
   every file under `<target>/stacks/<installed-stack>/`, and every file under
   `<target>/data-dictionary-tooling/` and `<target>/generators/`. Each file's tier comes from the
   manifest; a file in the set that the manifest does not list is **unclassified** (report it under
   "Files not classified in manifest.json", exactly as Install does, and do not modify it).

### Step 3 — Missing files

For every Tier 1 or Tier 2 file in the target file set whose destination does **not** exist in
this project:

- **Tier 1:** copy it in byte-for-byte from `<target>`, creating folders as needed.
- **Tier 2:** do **not** copy the bare template. Record it as "new Tier 2 file — not copied;
  run the relevant `generators/create-<x>.prompt.md` to produce it" (name the generator whose
  output it is, if one clearly owns it; otherwise say "no generator owns it — ask Copilot to
  install it from `<target>/core/<entry>` with the install-time placeholder substitutions").
  A Tier 2 file is never meant to stay in template form. Add it to the **deferred-baseline list**
  (Step 7), and do **not** write anything to `baseline/` now.

Never create a Tier 3 file.

### Step 4 — Deprecated / stale files

For every entry in the target manifest's `deprecated` array, find it in this project. An entry
containing a `/` is a project-relative path; a bare filename matches any file of that name under
`.ai/`, `.github/agents|prompts|skills/` or `generators/`. List every match, and mark each one
that is also a Tier 2 file in the *installed* baseline (the user may have customized it).

- If nothing matches, say so and move on.
- Otherwise ask the user to confirm the removal, per file or for all. **Delete a file only after
  explicit confirmation for that file. Never delete without it, and never delete on a silence,
  a vague answer, or a default.** Files the user declines to remove are reported as "deprecated —
  kept at user request".
- Add every file actually deleted to the deferred-baseline list (its baseline copy, if any, is
  removed by the 3-Way Merge section, not here).

### Step 5 — Unrecognized extra files (report only)

Scan this project's `.ai/` folder and `.github/agents/`, `.github/prompts/`, `.github/skills/`
for files that are in **none** of: the target's Tier 1/Tier 2 destinations (after path mapping and
`.template` stripping), the Tier 3 patterns, the target `deprecated` list, or `.ai/.toolkit-sync-state/`.
Report each as "unrecognized — not modified, verify manually" (this includes leftover
`*.toolkit-new` files from an earlier install conflict). **Never read-modify, move, overwrite or
delete an unrecognized file.** This step produces a report only.

### Step 6 — Tier 1 overwrite

For every Tier 1 file present in both `<target>` and this project (excluding any file Step 3 just
created), overwrite the project's copy with the target's copy, byte-for-byte, unconditionally —
Tier 1 files hold no project-specific content by definition. Before overwriting, compare the two;
only files whose content actually differs are rewritten and counted in the report (identical files
are "unchanged").

- If a target Tier 1 file contains a `{{...}}` token, copy it verbatim anyway and list file and
  token as a toolkit bug under pending placeholders; do not fill it in.
- Handle `.github/prompts/sync-toolkit.prompt.md` (this very file) **last** among the Tier 1
  files, and tell the user that the updated prompt takes effect on the next invocation; this run
  continues on the instructions already loaded.
- Do not touch `.ai/.toolkit-sync-state/` here (see the State-safety rule above).

### Step 7 — Interim summary and hand-off

Print the interim summary table, then continue directly into the **3-Way Merge** section for the
Tier 2 files (do not end the run here, and do not report the update as complete):

| Bucket | Contents |
|---|---|
| Missing / Added | Tier 1 files copied in; Tier 2 files flagged as new and not copied |
| Deprecated / Flagged | Each deprecated match, with its outcome (deleted after confirmation / kept at user request) |
| Unrecognized / Reported | Each unrecognized file, untouched |
| Tier 1 Overwritten | Each Tier 1 file rewritten, plus a count of unchanged ones |

Also state the target version, the resolved `<target>` path, whether it is a staging extraction
or `<source>` itself, and any warnings raised so far (fetch skipped, downgrade/same-version
confirmations, unclassified files, pending placeholders).

**Hand-off values for the 3-Way Merge section** — keep these in working memory for it; they are
inputs it consumes, not state to persist:

- the resolved target version and `<target>` path (and whether `<target>` is a staging directory
  that the merge section must remove at the very end — staging directories only; never `<source>`);
- the target manifest's Tier 2 file list and Tier 3 patterns;
- the **deferred-baseline list**: Tier 2 files newly flagged in Step 3 (need a baseline entry
  added) and files deleted in Step 4 (need their baseline entry removed);
- the interim summary and warnings above, to be merged into the final report.

<!-- ============================================================================
     END OF UPDATE MODE. The 3-Way Merge section below picks up at the Step 7 hand-off.
     ============================================================================ -->

<!-- ============================================================================
     SECTION: 3-WAY MERGE  (Task 17 — not yet implemented; invoked from Update Mode for Tier 2 files)
     ============================================================================ -->
