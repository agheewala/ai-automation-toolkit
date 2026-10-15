---
description: Install or update the AI Automation Toolkit in this project.
---

# /sync-toolkit

Installs the AI Automation Toolkit into this project (**install mode**) or brings an existing
installation up to a newer toolkit version (**update mode**).

> **No scripts.** Every action in this prompt is performed by you, the agent, through your own
> tool calls (`read_file`, `create_file`, file edits, and `run_in_terminal` for git and plain
> file-system operations — read-only `git -C <source>` commands, `git archive`/`tar` extraction
> into an OS temp staging folder during update mode, and, in the Tier 2 three-way merge,
> `git merge-file` on scratch copies plus byte-exact `Copy-Item`/`Remove-Item` of individual
> files). Never write or run an external `.ps1` / `.sh` / `.py` script file to copy files,
> run generators, or write state files; each command is issued individually by you.

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
`version.json` still names the old version, so a re-run simply repeats update mode. Each step is
safe to repeat: re-copying a missing file, re-overwriting a Tier 1 file and re-listing
deprecated/unrecognized files are idempotent, and the staging directory is uniquely named per run
(Step 2) so a leftover from an interrupted run never blocks a re-run. The one step whose effect
cannot be re-derived from the project alone is a confirmed deletion in Step 4 (a re-run no longer
finds the deleted file); that is why baseline cleanup is **not** driven by this run's in-memory
list but is reconciled from disk state + the target manifest by the 3-Way Merge section (see the
**Baseline reconciliation contract** in Step 7). Never write "partial done" state anywhere.

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
     temp folder) under a **uniquely-suffixed path**: `<stage>` =
     `<temp>/toolkit-<version>-<yyyyMMddHHmmss>/` using the current UTC time (if the time is not
     available to you, use a random 8-character suffix). Because the name is unique per run, it
     can never collide with a leftover from an earlier interrupted run — **never reuse, empty or
     delete a pre-existing `toolkit-*` directory**; if you notice older `toolkit-<version>*`
     folders in `<temp>`, just mention in the report that they are leftovers the user may delete.
     Create `<stage>` (it must not already exist; if it somehow does, pick a new suffix).
     Extraction is byte-exact and **must go through a file, not a shell pipe**
     (PowerShell pipes corrupt binary tar streams):
     `git -C <source> archive --format=tar -o <stage>.tar <version>` then
     `tar -xf <stage>.tar -C <stage>`. `<target>` is `<stage>`; the tar file is removed together
     with the staging directory at the very end of the 3-Way Merge section.
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
  A Tier 2 file is never meant to stay in template form. Do **not** write anything to `baseline/`
  now (see the **Baseline reconciliation contract** in Step 7).

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
- Do not touch `baseline/` here. A deleted file's baseline entry (if any) is removed by the
  3-Way Merge section's reconciliation (Step 7), which derives it from the target manifest and
  on-disk state, so it is cleaned up even if this run is interrupted right after the deletion.

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
- the interim summary and warnings above, to be merged into the final report;
- optionally, as a convenience only, the files deleted in Step 4 and the new Tier 2 files flagged
  in Step 3. This list is **informational (for the report) and non-authoritative**: the merge
  section must not depend on it, because it is lost if the run is interrupted.

**Baseline reconciliation contract (binding on the 3-Way Merge section).** Before writing
`version.json`, the 3-Way Merge section must reconcile `.ai/.toolkit-sync-state/baseline/`
against the **target manifest** directly, independent of any in-memory list from this run, so the
result is re-derivable from disk + `<target>` on every run:

1. **Remove** every `baseline/` entry whose manifest path is not a Tier 2 file of the target
   manifest — in particular any path listed in the target's `deprecated` array or absent from the
   target manifest — whether or not the project's copy was deleted in Step 4 (this also cleans up
   entries orphaned by an earlier interrupted run, and entries for deprecated files the user
   chose to keep).
2. **Add** (from `<target>/core/<manifest-path>`, placeholders unfilled, `.template` suffix kept)
   every Tier 2 manifest entry that has no `baseline/` entry, and refresh every other Tier 2
   entry once its merge is resolved, per the 3-Way Merge rules.
3. End state: the set of `baseline/` entries equals exactly the target manifest's Tier 2 set.
   Write `baseline/` first and `version.json` last, as the State-safety rule requires.

<!-- ============================================================================
     END OF UPDATE MODE. The 3-Way Merge section below picks up at the Step 7 hand-off.
     ============================================================================ -->

<!-- ============================================================================
     SECTION: 3-WAY MERGE  (Task 17 — invoked from Update Mode Step 7 for Tier 2 files)
     ============================================================================ -->

## Tier 2 Three-Way Merge (continuation of Update Mode)

Picks up from the Update Mode Step 7 hand-off. It merges every Tier 2 file, then reconciles
`.ai/.toolkit-sync-state/baseline/`, then writes `version.json` last, then cleans up and reports.
It ends the whole `/sync-toolkit` update run. **It never runs `git add`, `git commit` or
`git push`** — the final step reports and stops so the user can review and commit themselves.

Definitions (for each Tier 2 manifest entry `<manifest-path>` of the **target** manifest):

- `BASE` = `.ai/.toolkit-sync-state/baseline/<manifest-path>` — the template as it was when last
  synced (placeholders unfilled, `.template` suffix kept).
- `THEIRS` = `<target>/core/<manifest-path>` — the new template.
- `MINE` = this project's current, possibly customized `<project-path>`, where `<project-path>` is
  `<manifest-path>` with a trailing `.template` stripped (Shared Conventions, Path mapping).

Note that `MINE` has its placeholders filled in while `BASE`/`THEIRS` do not. The merge handles
this naturally: a filled-in line counts as a change on the `MINE` side, and only conflicts if
`THEIRS` also changed that same region.

### Step 1 — Build the work list and a scratch folder

1. Take the Tier 2 file list from `<target>/manifest.json` (read it again; do not rely on the
   in-memory hand-off list). This is the **target Tier 2 set**. A Tier 2 file that is only a
   `deprecated` match is not in the set and is not merged.
2. Create a scratch folder `<work>` = `<temp>/toolkit-merge-<yyyyMMddHHmmss>/` (UTC time, or a
   random 8-character suffix if the time is unavailable). It must not already exist; never reuse
   or empty a pre-existing folder. Merges are performed on copies in `<work>` so that `MINE` is
   only ever replaced by a finished result, never left half-written.

### Step 2 — Classify each file before merging

For every entry in the target Tier 2 set, decide its case, first match wins. Record the outcome
and whether its baseline entry is refreshed (see Step 6):

| Case | Action | Outcome | Baseline entry |
|---|---|---|---|
| `MINE` does not exist (already flagged as a new/missing Tier 2 file in Update Mode Step 3, or deleted by the user) | Nothing to merge. | `not present in project` | add / refresh |
| `BASE` does not exist (new Tier 2 file, or damaged baseline) | No common ancestor, so no 3-way merge is possible. If `MINE` is byte-identical to `THEIRS` after the install placeholder substitutions, outcome `unchanged`. Otherwise copy `THEIRS` next to the project file as `<project-path>.toolkit-new` (overwriting an earlier `.toolkit-new`) and do not touch `MINE`. | `NO MERGE BASE — compare manually` | add |
| `MINE` still contains conflict markers from an earlier sync (a line starting `<<<<<<< ` **and** a line starting `>>>>>>> `) | Do not merge on top of markers. Leave `MINE` untouched. | `NEEDS MANUAL RESOLUTION (markers from a previous sync, not merged)` | **keep as is** (not refreshed) |
| `BASE` and `THEIRS` are byte-identical | The toolkit did not change this file. Leave `MINE` untouched. | `unchanged` | refresh (no-op) |
| otherwise | Merge (Step 3). | decided in Step 4 | per Step 4 |

The "keep as is" rule matters: refreshing the baseline to `THEIRS` while `MINE` does not contain
the `THEIRS` changes would make the next merge treat those upstream changes as the user's
deletions and silently drop them. The baseline therefore only advances for a file when `MINE`
actually incorporates (or already equals) the target version of it.

### Step 3 — Run the three-way merge

For each file that reached "otherwise" in Step 2:

1. Copy `MINE` byte-for-byte to `<work>/<project-path>` (create folders as needed).
2. Run, with your own `run_in_terminal` call, a merge **in place on the scratch copy** (no output
   redirection and no pipe — PowerShell pipes can alter line endings and encodings):
   ```powershell
   git merge-file -L "project (current)" -L "baseline (<installed version>)" -L "toolkit <target version>" "<work>/<project-path>" "<BASE path>" "<THEIRS path>"
   ```
   Argument order is *current, base, other*: `MINE`'s copy, then `BASE`, then `THEIRS`. `git merge-file`
   is a plain three-file text merge; it works on loose files and does not need this project, or
   any of the three files, to be inside a git repository. Quote every path (they may contain
   spaces). Read the exit code immediately (`$LASTEXITCODE`).
3. Interpret the exit code:
   - `0` — clean merge.
   - `1`–`127` — that many conflicts; the scratch copy now contains standard conflict markers
     (`<<<<<<< project (current)` … `=======` … `>>>>>>> toolkit <target version>`).
   - anything else (e.g. `255` / negative — usually a binary or unreadable file) — error.

### Step 4 — Apply the result

- **Exit `0` (clean):** if the scratch copy differs from `MINE`, copy it over `<project-path>`
  (`Copy-Item -LiteralPath <scratch> -Destination <project-path> -Force`) and record
  `clean-merged`; if it is identical to `MINE`, record `unchanged`. Baseline: refresh.
- **Exit `1`–`127` (conflicts):** copy the scratch copy, **with its conflict markers**, over
  `<project-path>` and record `NEEDS MANUAL RESOLUTION (<n> conflict(s))`. **Never resolve a
  conflict by silently picking one side, and never drop the markers.** Clean hunks in the same
  file are already merged by `git merge-file`; only genuine conflicts carry markers. Baseline:
  refresh (the next sync merges against this version's template regardless of whether the user
  has resolved today's markers yet; the marker guard in Step 2 protects an unresolved file from
  being merged again on top of its markers).
- **Error:** leave `<project-path>` untouched and record `ERROR — not merged (<reason>)`.
  Baseline: **keep as is**. Continue with the remaining files and list it in the summary so the
  user can re-run `/sync-toolkit` to retry it.

### Step 5 — Post-merge placeholder check

For every file recorded `clean-merged` or conflicted, search the merged `<project-path>` for
`{{...}}` tokens that were **not** present in `MINE` before the merge (the toolkit template
introduced a new placeholder). Do not fill them; list file + token under "Placeholders still
pending" in the final summary.

### Step 6 — Reconcile `baseline/` against the target manifest (before `version.json`)

This is the **Baseline reconciliation contract** from Update Mode Step 7. Derive everything from
disk and `<target>`, not from this run's in-memory notes, so the result is correct even after
several interrupted runs. The baseline is tool-owned state, so removing or rewriting its entries
does not need user confirmation.

1. **Remove.** List every file under `.ai/.toolkit-sync-state/baseline/` recursively. Delete each
   one whose path relative to `baseline/` is **not** in the target Tier 2 set — this covers paths
   in the target's `deprecated` array, paths dropped from Tier 2 or from the manifest, deprecated
   files the user chose to keep, and entries orphaned by an earlier interrupted run. Then remove
   any `baseline/` folders left empty.
2. **Add / refresh.** For every Tier 2 entry whose Step 2/4 baseline decision is *add* or
   *refresh*, copy `<target>/core/<manifest-path>` to `baseline/<manifest-path>` byte-for-byte
   (`Copy-Item -LiteralPath … -Force`, creating folders as needed). These are the raw templates:
   placeholders **unfilled** and the `.template` suffix **kept** (matching Install Step 8 — the
   baseline never holds this project's filled-in content or the stripped project name). Entries
   marked *keep as is* are left exactly as they are, but **only if they already exist**; a
   missing entry is always added.
3. **Verify.** The set of files under `baseline/` must now equal the target Tier 2 set exactly.
   If not, stop and report the difference — and do **not** write `version.json`.

The order is fixed: `baseline/` here first, `version.json` in Step 7 last, so `version.json`
naming a version always means the baseline matches that version's Tier 2 set.

### Step 7 — Write `version.json` (last write to sync state)

Overwrite `.ai/.toolkit-sync-state/version.json` with `toolkitVersion` = the target version
(`<target>/VERSION`, trimmed), `stack` unchanged from the installed value, and `syncedAt` = the
current ISO 8601 UTC time (ask the user if you cannot determine it):
```json
{ "toolkitVersion": "<target version>", "stack": "<installed stack>", "syncedAt": "<now>" }
```

### Step 8 — Clean up this run's temporary files

Remove, and only these: `<work>` (Step 1), and — if Update Mode Step 2 extracted a staging copy —
`<stage>` and `<stage>.tar` (`Remove-Item -LiteralPath <path> -Recurse -Force`). Paths are the
exact ones this run created; never glob `toolkit-*` and never remove other leftovers (just mention
them). **Never remove `<source>`**, including when `<target>` = `<source>`. A cleanup failure is
not an update failure: report the path so the user can delete it. If the run aborts after
staging was created, remove this run's `<work>`/`<stage>`/`<stage>.tar` before stopping.

### Step 9 — Final summary, then stop

Print one report that combines the Update Mode Step 7 interim summary (missing/added, deprecated,
unrecognized, Tier 1 overwritten, warnings) with:

- Target version and previous version.
- Every Tier 2 file with its outcome: `unchanged` / `clean-merged` / `NEEDS MANUAL RESOLUTION`
  (with conflict count, or the reason) / `NO MERGE BASE — compare manually` (with the
  `.toolkit-new` path) / `not present in project` / `ERROR — not merged`.
- A prominent **"Needs manual resolution"** list: files containing conflict markers (search for
  `<<<<<<<` to resolve) and any file not merged, with the instruction to resolve the markers and
  review the diff.
- Baseline: entries added, removed (and why), refreshed, and kept as is.
- Placeholders still pending (Step 5, plus Update Mode findings) and files not classified in
  `manifest.json`.
- Cleanup result (Step 8), and if any file was `ERROR`/kept as is, that re-running `/sync-toolkit`
  retries it.
- A closing instruction: review the changes and commit them in this repo yourself; this command
  made no commits and pushed nothing.

Then **stop**. Do not run `git add`, `git commit` or `git push`.

<!-- ============================================================================
     END OF FILE. Install Mode + Update Mode + 3-Way Merge together are the complete /sync-toolkit.
     ============================================================================ -->
