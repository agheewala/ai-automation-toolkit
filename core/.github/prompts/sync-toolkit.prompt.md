---
description: Install or update the AI Automation Toolkit in this project.
---

# /sync-toolkit

Installs the AI Automation Toolkit into this project (**install mode**), brings an existing
installation up to a newer toolkit version (**update mode**), or re-runs a single generator on an
already-installed project (**generator mode**, `--generator <name>`).

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
- `--generator <name>` (optional, **standalone generator mode**): the name of one toolkit generator
  to re-run on this already-installed project, with or without the `.prompt.md` suffix (for example
  `create-data-dictionary`). When present, run **Generator Mode** below and nothing else: it is
  mutually exclusive with `--mode` and `--version` (if the user supplies either alongside
  `--generator`, say so and ask which they mean). Generators are never copied into this project;
  they are always read from `<source>/generators/`.
- `--mode install|update` (optional): if omitted, auto-detect — `install` if neither
  `.ai/.toolkit-sync-state.json` nor the legacy `.ai/.toolkit-sync-state/version.json` (see Update
  Mode Step 1) exists in this project, `update` otherwise. If the user explicitly passes
  `--mode install` but either of those already exists, stop and warn that a re-install would
  overwrite customized Tier 2 files; continue only on explicit confirmation, and in that case treat
  every existing destination file as a conflict (see Install Step 4).

After parsing, verify `<source>` contains `manifest.json`, `VERSION`, `core/`, `generators/`,
`stacks/`, and `data-dictionary-tooling/`. If any is missing, stop and report which one.

Then branch on the resolved mode: run **Generator Mode** if `--generator` was given, otherwise
**Install Mode** or **Update Mode** below.

---

## Shared Conventions

These definitions are used by all modes. Do not redefine them in a mode section.

**Path mapping.** `manifest.json` lists files under two different roots:

| Manifest entry | Source location | Location in this project |
|---|---|---|
| Tier 2 entries (e.g. `.github/agents/ticket-processor.agent.md`, `AGENTS.md.template`, `README.md.template`) | `<source>/core/<entry>` | `<entry>`, with a trailing `.template` suffix stripped (`AGENTS.md.template` → `AGENTS.md`, `README.md.template` → `README.md`, `.github/copilot-instructions.md.template` → `.github/copilot-instructions.md`) |
| Tier 1 entries starting `data-dictionary-tooling/` | `<source>/<entry>` | `<entry>` (same relative path, no stripping) |
| Tier 1 entries found under `core/` (today: `.github/prompts/sync-toolkit.prompt.md`) | `<source>/core/<entry>` | `<entry>`, `.template` stripped |
| Tier 3 patterns (`.ai/knowledge-base.md`, `.ai/data-dictionary/**`) | never copied | produced by generators; **never touched by sync** |

**Generators are source-only.** `<source>/generators/` is never copied into this project and has no
manifest entries; there is no `generators/` folder in an installed project. Install Mode (Step 6)
and Generator Mode read a generator directly from `<source>/generators/<name>.prompt.md` and
execute it against this project.

**Stack overlays are source-only.** `<source>/stacks/<stack>/` is never copied into this project and
has no manifest entries; there is no `stacks/` folder in an installed project. The overlay's
`notes.md` is only a hint that the `create-build-settings` generator reads directly from
`<source>/stacks/<chosen-stack>/notes.md` while it runs.

An entry's source location is `<source>/<entry>` if that file exists, otherwise
`<source>/core/<entry>`. If neither exists, stop and report the manifest/source mismatch.

**Whole-`core/` rule.** Install copies **every** file under `<source>/core/` — not only the files
named in `manifest.json`. A `core/` file absent from the manifest is a toolkit bug: still copy it,
and list it in your final report under "Files not classified in manifest.json".

**Sync state** lives in one file in this project: `.ai/.toolkit-sync-state.json` (a file directly
under `.ai/`, not a folder). Schema:

```json
{
  "toolkitVersion": "1.3.0",
  "stack": "dotnet-mvc",
  "syncedAt": "2026-10-16T12:00:00Z",
  "files": {
    "AGENTS.md.template": { "lastUpdatedAt": "2026-10-16T12:00:00Z", "lastMergeResult": "installed" },
    ".github/agents/ticket-processor.agent.md": { "lastUpdatedAt": "2026-10-16T12:00:00Z", "lastMergeResult": "installed" }
  }
}
```

- `toolkitVersion` — the toolkit version this project was last synced to: the trimmed content of
  `<source>/VERSION` at install/update time. It is the **only** version recorded. Every Tier 2
  file's last-known-good template (the common ancestor, `BASE`, for update mode's 3-way merge) is
  that version's template, because only Install Mode and the 3-Way Merge section's final state
  write ever change it and Generator Mode never touches it. No template content is stored in this
  project: update mode re-derives `BASE` from the toolkit's git history (Update Mode Step 2,
  item 5).
- `stack` — the stack overlay chosen at install (`none` if none).
- `syncedAt` — ISO 8601 UTC time of the last completed install/update.
- `files` — exactly one entry per Tier 2 manifest path, keyed by the manifest path itself (so
  `AGENTS.md.template` stays `AGENTS.md.template`). Each entry has `lastUpdatedAt` (ISO 8601 UTC)
  and `lastMergeResult`. There is no per-file version and no per-file content.
- `lastMergeResult` — one of: `installed` (written by Install), `unchanged`, `clean-merged`,
  `conflict (<n>)` (for example `conflict (2)`), `no-merge-base`, `utf16-32-not-merged`,
  `markers-not-merged`, `error`, `not-present` (the project's file does not exist), or
  `resolved-manually` (set by the user-driven recovery in the 3-Way Merge section, Step 2). These
  are the short forms of the outcomes the 3-Way Merge section reports (its Step 2/4 table maps
  each one).

This file is the single "the sync is complete" marker, so it must never be left partially written.
**Atomic write — mandatory at every place this file is written** (Install Step 7, 3-Way Merge
Step 6, and the Step 2 recovery option 3). Never overwrite `.ai/.toolkit-sync-state.json`
directly:

1. Build the full new content (valid JSON, UTF-8 without BOM).
2. Write it to `.ai/.toolkit-sync-state.json.tmp`. If a leftover `.tmp` from an interrupted run
   exists, it is this prompt's own scratch file: remove it first
   (`Remove-Item -LiteralPath '.ai/.toolkit-sync-state.json.tmp' -Force`), then create the file
   with your file-creation tool.
3. Verify the write: re-read the `.tmp` file and confirm it parses as JSON, that `toolkitVersion`
   is the intended value, and that the `files` keys are exactly the intended set, e.g.
   `$j = Get-Content -Raw -LiteralPath '.ai/.toolkit-sync-state.json.tmp' | ConvertFrom-Json; $j.toolkitVersion; @($j.files.PSObject.Properties.Name).Count`.
   If any check fails, delete the `.tmp` file, leave the real file untouched, stop and report.
4. Only then move it over the real path:
   `Move-Item -LiteralPath '.ai/.toolkit-sync-state.json.tmp' -Destination '.ai/.toolkit-sync-state.json' -Force`.

The `.tmp` file exists only between steps 2 and 4; it is never left behind by a successful write.

---

<!-- ============================================================================
     SECTION: INSTALL MODE
     Update Mode, the Tier 2 Three-Way Merge and Generator Mode are separate sections below this one;
     do not add their logic inside this section.
     ============================================================================ -->

## Install Mode

Follow these steps in order. If any step fails, stop and report — do **not** write
`.ai/.toolkit-sync-state.json` unless every step before Step 7 completed (its absence is what
makes a re-run detect install mode again). It is the very last file written, atomically (temp file
then rename, per Shared Conventions), as the "install is done" marker.

### Step 1 — Read the manifest

Read `<source>/manifest.json` and `<source>/VERSION`. Extract the Tier 1 `files` list, the Tier 2
`files` list, and the Tier 3 `patterns` list. These lists — not your own guesses — define what
"Tier 1" and "Tier 2" mean for the rest of this procedure.

### Step 2 — Gather core inputs (ask up front)

Ask the user for the core inputs below in a single round, then reuse the answers; do not re-ask
these later. Some generators run in Step 6 will still need additional, generator-specific input
that only becomes relevant when they run — for example `create-scm-workflow.prompt.md` (remote
URL, ticket-tracker key, branch prefixes, base branch, SCM platform) and
`create-data-dictionary.prompt.md` (database engine). Those later questions are expected and are
not a violation of this step; the rule here is only that the core inputs below are collected once
and never asked a second time.

1. **Stack overlay.** List the folders under `<source>/stacks/` and ask which one applies. If none
   fits, the user may choose "none" (no overlay hint; record `"stack": "none"`). The overlay is
   not installed into the project; it is only read from `<source>/stacks/<chosen-stack>/` during
   generation (Step 6).
2. **Project name** (`PROJECT_NAME`) — also used by the knowledge-base generator.
3. **System description** (`SYSTEM_DESCRIPTION`), **PVD/design-doc paths** (`PVD_PATHS`, or
   `none`), and **code root** (`CODE_ROOT`) — the knowledge-base generator's configuration block.
4. **Required Copilot model(s)** for the ticket workflow, as the value for the `model:`
   frontmatter field (`{{REQUIRED_MODEL_LIST}}`). **Default/recommended:** a fallback array of
   `['Claude Sonnet 5 (copilot)', 'Claude Sonnet 5.5 (copilot)']` (first available model wins) —
   this is the verified-working pattern. Ask the user to confirm this default or name a different
   model/list; do not silently assume it without asking once. If they name their own model(s),
   write exactly what they gave as the `model:` value (as a YAML array if more than one, a single
   scalar if only one) — still in the `'Model Name (vendor)'` format if they give a bare name
   without a vendor suffix, ask which vendor (e.g. `copilot`) rather than guessing or dropping the
   suffix, since VS Code's `model:` frontmatter matching depends on the exact string.

Do not fabricate any of these. If the user does not know one, record it as pending in the final
report instead of inventing a value.

### Step 3 — Plan the copy and scan for conflicts (dry run — write nothing)

Build the full list of destination files using the **Path mapping** in Shared Conventions:

1. For **every file under `<source>/core/`** (walk the whole tree; do not plan only the manifest's
   subset), the destination is its `core/`-stripped path, with a trailing `.template` removed.
2. For every file under `<source>/data-dictionary-tooling/`, the destination is
   `data-dictionary-tooling/<same relative path>`. This copy is **unconditional**, regardless of
   the user's database engine: the `*.sqlserver.sql` export queries are copied even if the project
   uses a different engine (the DB-engine question is asked later, by the data-dictionary
   generator, so install cannot know it yet). Step 8 tells the user these files may not apply.
3. Files are written **byte-for-byte except for** the `{{PROJECT_NAME}}`, `{{REQUIRED_MODEL_LIST}}`,
   `{{PROJECT_SPECIFIC_FIXES}}` and `{{STACK_CHECKLIST}}` (wcag-fix-patterns.md only) substitutions
   in Step 5. Those substitutions never apply to `.github/prompts/sync-toolkit.prompt.md` (see
   Step 5). Generators and stack overlays are not part of this plan at all: they stay in
   `<source>/generators/` and `<source>/stacks/`.

For each planned destination, check whether it already exists in this project. If it does,
compare it with the content you would write (including the Step 5 substitutions). Identical →
skip silently (expected for this prompt file itself, which the user copied in manually).
Different → add it to a **conflict list**. **Do not create, modify or overwrite any file in this
step.**

### Step 4 — Resolve conflicts, then copy

1. If the conflict list from Step 3 is non-empty, show it and ask the user, per file or for all,
   to choose **keep existing** (record it as skipped in the report; later updates will treat that
   file as customized), **overwrite**, or **save toolkit version
   alongside as `<name>.toolkit-new`** for manual merging. Wait for the answer. (With an explicit
   `--mode install` over an existing install, every existing destination file is on this list.)
2. Only now perform the writes planned in Step 3: create every planned destination file (creating
   folders as needed), applying each conflict choice. Files with no conflict are simply created.
   Then continue to Step 5.

### Step 5 — Fill sync-owned placeholders

Four placeholder occurrences have no generator that owns them, so install fills them directly in the
project's copies (never in `<source>`):

- `{{PROJECT_NAME}}` → the project name from Step 2, in every copied file that contains it
  (subject to the exclusions below).
- `{{REQUIRED_MODEL_LIST}}` → the model value from Step 2, in every copied file that contains it
  (subject to the exclusions below), which covers the `model:` frontmatter of the ticket prompts
  and the Ticket Processor / Domain Engineer
  agents, plus the "Required Model" prose in `AGENTS.md` and `README.md`. In `model:` frontmatter, write the
  value as the YAML scalar/array the field expects; in prose, write it as a human-readable model
  name or "A or B" list. If the user gave none, leave the token and list it as pending.
- `{{PROJECT_SPECIFIC_FIXES}}` in `.ai/governance/custom-fixes.md` → replace with a single
  italic line stating that no project-specific fixes have been recorded yet. That file is
  hand-maintained afterward, per its own note.
- `{{STACK_CHECKLIST}}` in `.ai/governance/wcag-fix-patterns.md` (only this occurrence — the one
  in `.ai/behavior/setting.md` is owned by `create-build-settings.prompt.md`) → replace with a
  single italic line stating that no project-specific accessibility rules have been recorded yet.
  That file is hand-maintained afterward, per its own note.

Leave every other `{{...}}` token untouched; the generators in Step 6 own them. The only
exceptions are `{{MODULE_LIST}}`, `{{SHARED_LIBS}}` and `{{STACK_SUMMARY}}`, which are filled in
Step 6a (in every file that contains them).

**Never substitute inside instructional/meta files.** Do not perform any Step 5 (or Step 6a)
substitution inside `.github/prompts/sync-toolkit.prompt.md` (this file) or inside any generator
file under `<source>/generators/`. Those files mention these tokens by name as part of their own
instructions — they are not filled content, and substituting there would corrupt the instructions
(and, for this file, make it differ from the toolkit's Tier 1 copy on every update).

**Duplicate occurrences in one file.** If a token appears more than once in the same file — for
example once as the real placeholder and once inside an explanatory note — fill the real
placeholder occurrence(s) and leave the explanatory-note occurrence untouched. An **explanatory
note** is specifically a blockquote (`>`) or HTML comment (`<!-- -->`) whose text is *about the
token itself* (describing what it holds or who fills it). A token used inline as part of a normal
sentence (e.g. "from `{{BASE_BRANCHES}}`") IS a real placeholder and MUST be filled — only skip a
token when it appears inside a blockquote/comment that is explaining the token's purpose, not
using its value. Never fill, rewrite or delete an explanatory-note occurrence (for example, the
notes under `{{PROJECT_SPECIFIC_FIXES}}` in `custom-fixes.md` and under `{{STACK_CHECKLIST}}` in
`wcag-fix-patterns.md` keep their literal token text). The same rule applies to every token a
generator fills in Step 6.

### Step 6 — Run the generators, in this verified order

Each generator is a prompt file under `<source>/generators/`. **Read it from the source clone and
execute its instructions directly against this project** — do not copy it into this project first.
Reuse the Step 2 answers wherever a generator asks for `PROJECT_NAME`, `SYSTEM_DESCRIPTION`,
`PVD_PATHS` or `CODE_ROOT`; do not ask the user for those again. A generator may still ask
generator-specific questions that Step 2 did not cover (see Step 2); ask those when the
generator reaches them.

Each generator ends with a "self-delete this file from `.github/prompts/`" step. Because you run
them from `<source>`, **skip that step** — there is nothing to delete in this project, and you must
never delete or modify anything inside `<source>`.

`create-build-settings.prompt.md` consults the stack overlay hint by reading
`<source>/stacks/<chosen-stack>/notes.md` (the Step 2 answer) directly from the toolkit source
clone; nothing under `stacks/` exists in this project.

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
  the report with the instruction to run it later via
  `/sync-toolkit --source <path> --generator create-data-dictionary`. If the user's
  database is not SQL Server, that generator stops itself with a documented known-gap message —
  relay that message; this is not an install failure.
- If any of #1–#6 stops or fails, stop the whole install and report which generator failed and why.

**Step 6a — immediately after generator #1 completes:** fill the three remaining placeholders from
the now-existing `.ai/knowledge-base.md` (not from re-scanning the code), **in every file of this
project that contains the token** (search the project's copied files; do not assume a single
file): `{{MODULE_LIST}}` (the project's modules/components — appears in `AGENTS.md`, `README.md` and
`.ai/behavior/ada-workflow.md`), `{{SHARED_LIBS}}` (shared libraries and any sign-off rule
recorded for them — appears in `AGENTS.md` and `.ai/behavior/decision-rules.md`), and
`{{STACK_SUMMARY}}` (one line: language, framework, UI, database). Use "not found in knowledge
base" rather than inventing content when it does not say.

### Step 7 — Write the sync state

This is the last write of the install. Write exactly one file, `.ai/.toolkit-sync-state.json`,
using the **atomic write** procedure from Shared Conventions (temp file, verify, rename) — never
directly. Use the current date/time available to you for the timestamps; if you cannot determine
it, ask the user. Content:
```json
{
  "toolkitVersion": "<contents of <source>/VERSION, trimmed>",
  "stack": "<chosen stack or none>",
  "syncedAt": "<current ISO 8601 UTC timestamp>",
  "files": {
    "<manifest-path>": { "lastUpdatedAt": "<same timestamp>", "lastMergeResult": "installed" }
  }
}
```
The `files` map has one entry for **every Tier 2 file in the manifest** (Step 1), keyed by its
manifest path (`.template` suffix kept) — and no Tier 1 or Tier 3 paths. Every entry is
`"installed"`, including files the user kept or saved as `.toolkit-new` in Step 4 (update mode
treats a kept file as customized against the installed template). Before the rename, the
verification step must confirm the `files` key set equals the manifest's Tier 2 set exactly.

### Step 8 — Stop and report

Do **not** run `git add`, `git commit` or `git push`. Print a summary containing:

- Toolkit version and stack installed.
- Every file created, grouped as: core files, data-dictionary tooling,
  sync state (`.ai/.toolkit-sync-state.json`, with its Tier 2 `files` entry count). Generators and stack overlays are not copied
  into the project, so there is no generators group and no stack overlay group.
- Files skipped or saved as `.toolkit-new` in Step 4.
- Each generator that ran and its outcome, plus any skipped (e.g. data dictionary). Tell the user
  that any single generator can be re-run later with `/sync-toolkit --source <path> --generator <name>`
  (see Generator Mode).
- Placeholders still pending: search the project's files only for tokens matching this toolkit's
  `{{UPPER_SNAKE_CASE}}` convention (regex `\{\{[A-Z][A-Z0-9_]*\}\}`) and list file + token. Do
  NOT flag other `{{...}}` syntax (Handlebars, Jinja, Angular, etc.) — that is the project's own.
  **Exclude from this scan**: `.github/prompts/sync-toolkit.prompt.md` and any `*.toolkit-new`
  files — they contain tokens by design (instructional text, or unmerged toolkit copies), so
  listing them is noise. Also ignore a token that appears only inside an explanatory note about itself
  (a blockquote or HTML comment per Step 5, e.g. the retained notes in `custom-fixes.md` and
  `wcag-fix-patterns.md`); a token counts as pending only if a real, unfilled placeholder remains.
  Also list any file still containing the literal `<remote URL not yet configured>` (the
  `create-scm-workflow` "no remote yet" value) and remind the user to update it once a remote exists.
- Files copied from `core/` that were not classified in `manifest.json`.
- **Completeness check.** When confirming that every Tier 1 manifest entry exists in the project,
  check only the entries the manifest actually lists. Generators and stack overlays have no
  manifest entries and are never expected in the project (regardless of which stack was chosen), so
  there is nothing to check for them.
- **Database tooling note.** `data-dictionary-tooling/*.sqlserver.sql` is copied unconditionally
  (Step 3), so if the project's database is not SQL Server (or the data dictionary was deferred),
  say these files were copied but may not apply, and may be deleted.
- A closing instruction: review the changes and commit them in this repo yourself; this command
  made no commits.

---

<!-- ============================================================================
     SECTION: UPDATE MODE  (detection + Tier 1 overwrite + interim summary)
     Tier 2 three-way merge and the sync-state write are owned by the 3-way merge section below.
     Do not add them in this section.
     ============================================================================ -->

## Update Mode

Brings an existing installation up to the target toolkit version. This section handles
everything except Tier 2 merging: it detects missing, deprecated and unrecognized files, and
overwrites Tier 1 files. It ends with an interim summary and a hand-off to the **3-Way Merge**
section.

**State-safety rule (mirrors Install Mode's atomicity rule).** Update Mode steps 1–7 **never write
or modify `.ai/.toolkit-sync-state.json`** (or its `.tmp` scratch file). It is written only by the
3-Way Merge section's final state-write step, atomically (temp file then rename), once Tier 2
handling is complete. Consequence: if this procedure is interrupted at any point, the file still
names the old version, so a re-run simply repeats update mode with the same `<installed>` content
for `BASE`. There is no separate "corrupt baseline" case: nothing is persisted locally except
that one file, and it is only ever replaced whole. Each step is safe to repeat: re-copying a
missing file, re-overwriting a Tier 1 file and re-listing deprecated/unrecognized files are
idempotent, a Tier 2 file already merged by an interrupted run merges again cleanly (both sides
made the same change), and the staging directories are uniquely named per run (Step 2) so a
leftover from an interrupted run never blocks a re-run. Never write "partial done" state anywhere.

Use the **Path mapping**, **Whole-`core/` rule** and **Sync state** definitions from Shared
Conventions unchanged. Do not invent a different mapping for update mode.

### Step 1 — Read the installed state

Read `.ai/.toolkit-sync-state.json` in this project to get the installed `toolkitVersion`, `stack`
and the `files` map. If it is missing, unparseable, or lacks `toolkitVersion` or `files`:

- **Legacy layout.** If `.ai/.toolkit-sync-state/version.json` exists (an install made by a toolkit
  version that kept a `version.json` + `baseline/` folder instead of this file), read
  `toolkitVersion` and `stack` from it and continue as an update. There are no prior `files`
  entries to carry over (every entry is written fresh at the end of the run), and the legacy
  `baseline/` folder is **ignored** — `BASE` always comes from `<installed>` (Step 2, item 5). Do
  not touch the legacy folder during this run; the 3-Way Merge section's Step 6 tells the user it
  is obsolete.
- **Otherwise** stop: this is not a completed install (re-run in install mode). Do not
  reconstruct the file.

Call the recorded `toolkitVersion` the **installed version**.

Resolve the **target version**: `--version` if given, otherwise the content of
`<source>/VERSION` (trimmed). If the target equals the installed version, say so and ask
whether to continue as a drift check (Tier 1 files are re-checked and re-overwritten; Tier 2 is
re-merged with `BASE` identical to `THEIRS`, so every present file comes out `unchanged`); stop if
the user declines. If the target looks older than the installed version, warn that this is a
downgrade and continue only on explicit confirmation.

### Step 2 — Obtain the target and installed versions' content without touching `<source>`'s working tree

Define **`<target>`** as a directory laid out exactly like a toolkit repo root (`manifest.json`,
`VERSION`, `core/`, `generators/`, `stacks/`, `data-dictionary-tooling/`). All later steps and the
3-Way Merge section read the target version only through `<target>`, using the same
`<target>/<entry>`-then-`<target>/core/<entry>` lookup the Path mapping defines for `<source>`.
Define **`<installed>`** the same way for the **installed version** (item 5): it is the source of
every Tier 2 file's `BASE`, read through the same lookup. Never check out, reset, stash or
otherwise modify `<source>`'s working tree or branches.

1. **Optional refresh.** If `<source>` has a remote, run `git -C <source> fetch --tags`. This
   updates only refs and tag objects, never the working tree. If the fetch fails (offline / no
   remote), continue with the tags already present locally and note it in the report.
2. **Resolve the target.** A version string `<version>` names a tag as written or with a leading
   `v` (the toolkit's tags look like `v1.3.0` while its `VERSION` file holds `1.3.0`): try
   `<version>`, then `v<version>` if it does not already start with `v`, and use the first that
   resolves. Run `git -C <source> rev-parse --verify --quiet "<candidate>^{commit}"`. Everywhere
   in update mode, version strings are compared ignoring a leading `v` (`v1.3.0` = `1.3.0`).
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
     `git -C <source> archive --format=tar -o <stage>.tar <candidate>` then
     `tar -xf <stage>.tar -C <stage>`. `<target>` is `<stage>`; the tar file is removed together
     with the staging directory at the very end of the 3-Way Merge section (Step 7).
   - **Does not resolve** → if `<version>` equals `<source>/VERSION` (the target is simply what
     the clone currently has checked out and was never tagged), set `<target>` = `<source>` and
     treat it as **read-only** — you only read from it. Otherwise stop and report that the
     version is not a tag or commit in `<source>`; list available tags
     (`git -C <source> tag --list`) for the user.
3. **Verify the target.** `<target>` must contain `manifest.json`, `VERSION`, `core/`,
   `generators/`, `stacks/` and `data-dictionary-tooling/` (same check as the Arguments section).
   If any is missing, stop and report which one. Confirm `<target>/VERSION` (trimmed) matches
   `<version>` (ignoring a leading `v` on either side); if it does not, warn and ask whether to
   continue.
4. **Read the target manifest.** Read `<target>/manifest.json`: the Tier 1 `files`, Tier 2
   `files`, Tier 3 `patterns` and the `deprecated` array. These lists, not guesses, define the
   tiers for the rest of update mode.

   Build the **target file set** the same way Install Step 3 builds its plan: every file under
   `<target>/core/` (destination = `core/`-stripped path with a trailing `.template` removed),
   and every file under `<target>/data-dictionary-tooling/`. Generators under
   `<target>/generators/` and stack overlays under `<target>/stacks/` are **not** part of the
   target file set: they are source-only and never installed into the project. Each file's
   tier comes from the
   manifest; a file in the set that the manifest does not list is **unclassified** (report it under
   "Files not classified in manifest.json", exactly as Install does, and do not modify it).
5. **Obtain `<installed>` (the source of every `BASE`).** `<installed>` is a directory laid out
   like a toolkit repo root holding the **installed version** from Step 1 (call the string
   `<installed-version>`). Build it with exactly the mechanism of item 2 and the verification of
   item 3, parameterized as follows. This happens now, before any file in this project is
   written, because a missing installed version affects the whole run.
   - **Same version as the target** (drift check, `<installed-version>` equals the target
     version): `<installed>` = `<target>`; no second extraction.
   - **Otherwise, resolve** `<installed-version>` with item 2's tag-candidate rule.
     - **Resolves** → extract it with the same procedure as item 2 to a second, separately
       named staging directory `<stage-installed>` =
       `<temp>/toolkit-installed-<installed-version>-<yyyyMMddHHmmss>/` (same uniqueness rules
       and the same "never reuse, empty or delete a pre-existing directory"; same
       tar-via-file, never-a-pipe requirement):
       `git -C <source> archive --format=tar -o <stage-installed>.tar <candidate>` then
       `tar -xf <stage-installed>.tar -C <stage-installed>`. `<installed>` = `<stage-installed>`.
     - **Does not resolve, but `<installed-version>` equals `<source>/VERSION`** → `<installed>` =
       `<source>`, read-only (the same shortcut item 2 applies to `<target>`).
     - **Does not resolve and is not `<source>/VERSION`** (tag deleted, shallow clone, wrong
       clone, …) → the installed version's content is unavailable. This affects the **whole run**,
       since every Tier 2 file's `BASE` comes from `<installed>`. **Stop before merging or
       writing anything** and report: the installed version's tag is missing from `<source>`,
       with the output of `git -C <source> tag --list`. Ask the user how to proceed, and do not
       guess or skip this check:
       (a) **abort** — restore the tag in `<source>` (fetch tags, unshallow, or point `--source`
       at the right clone), then re-run; nothing has been changed, so remove this run's staging
       directories and end the run; or
       (b) **continue without a merge base** — `<installed>` = *none*, and every Tier 2 file gets
       the `NO MERGE BASE` treatment defined for that case in the 3-Way Merge section's Step 2
       (a `.toolkit-new` copy next to each file plus a loud "needs manual resolution"), for this
       run only.
   - **Verify `<installed>`** with item 3's check (`manifest.json`, `VERSION`, `core/`,
     `generators/`, `stacks/`, `data-dictionary-tooling/` present). If it is not usable, treat it
     exactly like the missing-tag case (the same choice between (a) and (b)). A `VERSION`
     mismatch (ignoring a leading `v`) is a warning plus the same "continue?" question as item 3.
   - `<installed>/manifest.json` is not otherwise used: `BASE` is found by the
     `<installed>/<entry>`-then-`<installed>/core/<entry>` lookup, and the set of files to
     process comes from the **target** manifest.

### Step 3 — Missing files

For every Tier 1 or Tier 2 file in the target file set whose destination does **not** exist in
this project:

- **Tier 1:** copy it in byte-for-byte from `<target>`, creating folders as needed.
- **Tier 2:** do **not** copy the bare template. Record it as "new Tier 2 file — not copied;
  run the relevant generator to produce it (`/sync-toolkit --source <path> --generator create-<x>`)"
  (name the generator whose
  output it is, if one clearly owns it; otherwise say "no generator owns it — ask Copilot to
  install it from `<target>/core/<entry>` with the install-time placeholder substitutions").
  A Tier 2 file is never meant to stay in template form. Its `files` entry in the sync state is
  written as `not-present` by the 3-Way Merge section's final state write.

Never create a Tier 3 file.

### Step 4 — Deprecated / stale files

For every entry in the target manifest's `deprecated` array, find it in this project. An entry
containing a `/` is a project-relative path; a bare filename matches any file of that name under
`.ai/` or `.github/agents|prompts|skills/`. List every match, and mark each one
that is also a Tier 2 file (a key of the state file's `files` map, or listed in a manifest) — the
user may have customized it.

- If nothing matches, say so and move on.
- Otherwise ask the user to confirm the removal, per file or for all. **Delete a file only after
  explicit confirmation for that file. Never delete without it, and never delete on a silence,
  a vague answer, or a default.** Files the user declines to remove are reported as "deprecated —
  kept at user request".
- **Legacy `generators/` copies.** Toolkit versions before generators became source-only copied
  `generators/create-*.prompt.md` into the project; the target manifest lists those paths in
  `deprecated`, so they are handled by the rules above (explicit per-file confirmation). If the
  project's `generators/` folder is left empty after confirmed deletions, tell the user it can be
  removed; remove it only on their explicit confirmation.
- **Legacy `stacks/` copies.** Toolkit versions before stack overlays became source-only copied
  `stacks/<stack>/notes.md` into the project; the target manifest lists that path in `deprecated`,
  so it is handled by the rules above (explicit per-file confirmation). If the project's `stacks/`
  folder is left empty after a confirmed deletion, tell the user it can be removed; remove it only
  on their explicit confirmation.
- A deleted or kept deprecated file needs no sync-state handling here: the state file's `files` map
  is rebuilt from the target Tier 2 set when it is written (3-Way Merge Step 6), so a deprecated
  path never appears in it.

### Step 5 — Unrecognized extra files (report only)

Scan this project's `.ai/` folder and `.github/agents/`, `.github/prompts/`, `.github/skills/`
for files that are in **none** of: the target's Tier 1/Tier 2 destinations (after path mapping and
`.template` stripping), the Tier 3 patterns, the target `deprecated` list, or the toolkit's own
sync-state paths (`.ai/.toolkit-sync-state.json`, its `.tmp` scratch file, and the legacy
`.ai/.toolkit-sync-state/` folder, which the final summary reports separately).
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
  token as a toolkit bug under pending placeholders; do not fill it in. Exempt from this listing:
  `.github/prompts/sync-toolkit.prompt.md`, which mentions tokens
  by name as instructional text by design.
- Handle `.github/prompts/sync-toolkit.prompt.md` (this very file) **last** among the Tier 1
  files, and tell the user that the updated prompt takes effect on the next invocation; this run
  continues on the instructions already loaded.
- Do not touch `.ai/.toolkit-sync-state.json` here (see the State-safety rule above).

### Step 7 — Interim summary and hand-off

Print the interim summary table, then continue directly into the **3-Way Merge** section for the
Tier 2 files (do not end the run here, and do not report the update as complete):

| Bucket | Contents |
|---|---|
| Missing / Added | Tier 1 files copied in; Tier 2 files flagged as new and not copied |
| Deprecated / Flagged | Each deprecated match, with its outcome (deleted after confirmation / kept at user request) |
| Unrecognized / Reported | Each unrecognized file, untouched |
| Tier 1 Overwritten | Each Tier 1 file rewritten, plus a count of unchanged ones |

Also state the target version, the installed version, the resolved `<target>` and `<installed>`
paths (each: a staging extraction, or `<source>` itself, or — for `<installed>` only — *none* if the
user chose to continue without a merge base), and any warnings raised so far (fetch skipped,
downgrade/same-version confirmations, unclassified files, pending placeholders).

**Hand-off values for the 3-Way Merge section** — keep these in working memory for it; they are
inputs it consumes, not state to persist:

- the resolved target version and `<target>` path, the installed version and `<installed>` path
  (or *none*), and for each whether it is a staging directory (`<stage>` / `<stage-installed>`)
  that the merge section must remove at the very end — staging directories only; never `<source>`;
- the target manifest's Tier 2 file list and Tier 3 patterns;
- the interim summary and warnings above, to be merged into the final report;
- optionally, as a convenience only, the files deleted in Step 4 and the new Tier 2 files flagged
  in Step 3. This list is **informational (for the report) and non-authoritative**: the merge
  section must not depend on it, because it is lost if the run is interrupted.

<!-- ============================================================================
     END OF UPDATE MODE. The 3-Way Merge section below picks up at the Step 7 hand-off.
     ============================================================================ -->

<!-- ============================================================================
     SECTION: 3-WAY MERGE  (invoked from Update Mode Step 7 for Tier 2 files)
     ============================================================================ -->

## Tier 2 Three-Way Merge (continuation of Update Mode)

Picks up from the Update Mode Step 7 hand-off. It merges every Tier 2 file, then writes
`.ai/.toolkit-sync-state.json` last (atomically), then cleans up and reports.
It ends the whole `/sync-toolkit` update run. **It never runs `git add`, `git commit` or
`git push`** — the final step reports and stops so the user can review and commit themselves.

Definitions (for each Tier 2 manifest entry `<manifest-path>` of the **target** manifest):

- `BASE` = `<installed>/core/<manifest-path>` — the template as it was at the project's installed
  version, i.e. the version last synced (placeholders unfilled, `.template` suffix kept), found
  with the usual `<installed>/<manifest-path>`-then-`<installed>/core/<manifest-path>` lookup.
  `<installed>` was built in Update Mode Step 2, item 5, from the single `toolkitVersion` recorded
  in `.ai/.toolkit-sync-state.json` (the value as it was **before** this run updates it). `BASE`
  does not exist when `<installed>` is *none* (the user chose to continue without a merge base) or
  when the file is absent from `<installed>`.
- `THEIRS` = `<target>/core/<manifest-path>` — the new template.
- `MINE` = this project's current, possibly customized `<project-path>`, where `<project-path>` is
  `<manifest-path>` with a trailing `.template` stripped (Shared Conventions, Path mapping).

Note that `MINE` has its placeholders filled in while `BASE`/`THEIRS` do not. The merge handles
this naturally: a filled-in line counts as a change on the `MINE` side, and only conflicts if
`THEIRS` also changed that same region.

### Step 1 — Build the work list and a scratch folder

1. Take the Tier 2 file list from `<target>/manifest.json` (read it again; do not rely on the
   in-memory hand-off list). This is the **target Tier 2 set**. A Tier 2 file that is only a
   `deprecated` match is not in the set and is not merged. Confirm `<installed>` (resolved in
   Update Mode Step 2, item 5, before anything was written) is available as handed off; do not
   resolve tags again here. If it is *none*, no `BASE` copies are made and every file classifies
   as `NO MERGE BASE` in Step 2.
2. Create a scratch folder `<work>` = `<temp>/toolkit-merge-<yyyyMMddHHmmss>/` (UTC time, or a
   random 8-character suffix if the time is unavailable). It must not already exist; never reuse
   or empty a pre-existing folder. Merges are performed on copies in `<work>` so that `MINE` is
   only ever replaced by a finished result, never left half-written.
3. **Line-ending normalization (mandatory before any comparison or merge).** `MINE` usually has
   the project's native line endings (CRLF on Windows with `autocrlf`), while `BASE` and `THEIRS`
   are raw template copies (typically LF, extracted via `git archive`/`tar`). Compared or merged
   as-is, every line would differ purely by line ending: the "`BASE` == `THEIRS` -> unchanged"
   shortcut would never fire, customized regions would conflict spuriously, and untouched regions
   would pull LF endings into a CRLF file. So, for every Tier 2 entry where the file exists,
   work only on LF-normalized scratch copies, and never compare or merge the originals:

   - `<work>/base/<manifest-path>` — LF copy of `BASE` (the source file is
     `<installed>/core/<manifest-path>`, not anything in this project; skipped when `BASE` does
     not exist)
   - `<work>/theirs/<manifest-path>` — LF copy of `THEIRS`
   - `<work>/mine/<project-path>` — LF copy of `MINE`, **plus** `MINE`'s **dominant line-ending
     style**, recorded now: count `\r\n` sequences vs. bare `\n`; the larger count wins, and a
     tie or a file with no line breaks counts as `LF`. If `MINE` has both kinds (mixed), note
     "mixed line endings normalized" for the final summary.

   **Byte-level only — never decode file content as text.** Newline conversion in this workflow
   (here, in the marker guard, and in Step 4) must operate on the raw byte array: the only bytes
   ever touched are `0x0D` (CR) and `0x0A` (LF). Do **not** use `ReadAllText` / `WriteAllText` /
   `Get-Content` / `Set-Content` / `Encoding.GetString` / `Encoding.GetBytes` on file content, with
   *any* encoding: `ReadAllText` auto-detects and strips a BOM whatever encoding is passed, and a
   single-byte codec such as Latin-1 would turn every character above U+00FF (e.g. an em-dash) into
   `?` on write-back. Working on bytes leaves a UTF-8 BOM and every multi-byte UTF-8 sequence
   (which never contains `0x0D`/`0x0A`) untouched. Algorithm for **CRLF -> LF**: read all bytes;
   copy them to a new byte list, skipping each `0x0D` that is immediately followed by `0x0A`; write
   the list back with `WriteAllBytes`. A lone `0x0D` not followed by `0x0A` is kept as-is.

   **UTF-16 / UTF-32 guard.** These encodings store newlines as `0D 00 0A 00` (or wider), so the
   byte-level conversion below does not apply and would corrupt them. If `MINE`, `BASE` or `THEIRS`
   starts with `FF FE`, `FE FF`, `FF FE 00 00` or `00 00 FE FF`, do not normalize or merge that
   file: handle it as `NEEDS MANUAL RESOLUTION (UTF-16/32 file, not merged)` (Step 2 table).

   Make each copy with one `run_in_terminal` call per file (create the target folder first with
   `New-Item -ItemType Directory -Force`); no pipe or redirection is used. Illustrative snippet
   (tested; adapt the syntax if needed, but keep the algorithm above):
   ```powershell
   $b=[IO.File]::ReadAllBytes("<src>"); $o=New-Object 'System.Collections.Generic.List[byte]' $b.Length; for($i=0;$i -lt $b.Length;$i++){ if($b[$i] -eq 13 -and $i+1 -lt $b.Length -and $b[$i+1] -eq 10){continue}; $o.Add($b[$i]) }; [IO.File]::WriteAllBytes("<dest>",$o.ToArray())
   ```
   Detect `MINE`'s style by counting bytes: every `0x0A` preceded by `0x0D` is a CRLF, every other
   `0x0A` is a bare LF:
   ```powershell
   $b=[IO.File]::ReadAllBytes("<MINE>"); $c=0;$l=0; for($i=0;$i -lt $b.Length;$i++){ if($b[$i] -eq 10){ if($i -gt 0 -and $b[$i-1] -eq 13){$c++}else{$l++} } }; "CRLF=$c LF=$l"
   ```
   Every "identical" / "differs" test in Steps 2 and 4 means: compare the **normalized** copies
   (`(Get-FileHash -LiteralPath a).Hash -eq (Get-FileHash -LiteralPath b).Hash`), never the
   originals. The normalized copies live only in `<work>`; the original `BASE`, `THEIRS` and
   `<target>`/`<installed>` files are never modified.

### Step 2 — Classify each file before merging

For every entry in the target Tier 2 set, decide its case, first match wins. Record the outcome
and how its sync-state entry is written (see Step 6). **Refresh** = `lastUpdatedAt` is set to the
time of this run and `lastMergeResult` to the value shown. **Record only** = `lastMergeResult`
is set to the value shown but `lastUpdatedAt` is left as it was in the state file read at the
start of this run (or set to now if the entry is new or the project came from the legacy layout),
because the project file was not brought up to date.

| Case | Action | Outcome | State entry |
|---|---|---|---|
| `MINE` does not exist (already flagged as a new/missing Tier 2 file in Update Mode Step 3, or deleted by the user) | Nothing to merge. | `not present in project` | record only: `not-present` |
| `MINE`, `BASE` or `THEIRS` is UTF-16/UTF-32 (starts with a `FF FE` / `FE FF` / `00 00 FE FF` BOM; see Step 1 item 3) | Byte-level newline handling is not valid for these encodings. Leave `MINE` untouched. | `NEEDS MANUAL RESOLUTION (UTF-16/32 file, not merged)` | record only: `utf16-32-not-merged` |
| `BASE` does not exist: `<installed>` is *none* (user chose to continue without a merge base), or the file does not exist in `<installed>` at all (for example a Tier 2 file added to the toolkit after the project's installed version) | No common ancestor, so no 3-way merge is possible. If the normalized `MINE` is identical to the normalized `THEIRS` after the install placeholder substitutions, outcome `unchanged`. Otherwise copy `THEIRS` next to the project file as `<project-path>.toolkit-new` (overwriting an earlier `.toolkit-new`) and do not touch `MINE`. **Upstream changes in `.toolkit-new` are NOT in `MINE`** — see the risk note below the table. | `unchanged`, or `NO MERGE BASE — NEEDS MANUAL RESOLUTION (compare manually)` | `unchanged`: refresh. Otherwise record only: `no-merge-base` |
| `MINE` still contains an unresolved conflict-marker block from an earlier sync (the full triple, in order — see **Marker guard** below) | Do not merge on top of markers. Leave `MINE` untouched. | `NEEDS MANUAL RESOLUTION (markers from a previous sync, not merged)` | record only: `markers-not-merged` |
| Normalized `BASE` and normalized `THEIRS` are identical | The toolkit did not change this file (any raw difference was line endings only). Leave `MINE` untouched. | `unchanged` | refresh: `unchanged` |
| otherwise | Merge (Step 3). | decided in Step 4 | per Step 4 |

**Marker guard.** A file counts as "still containing conflict markers" only if its text contains,
**in this order**: a line starting `<<<<<<< `, later a line that is exactly `=======`, later a line
starting `>>>>>>> `. All three must be present and in that order; two of the three, or the same
three out of order, do not trigger it. Test the normalized `MINE` copy **on its bytes** (no text
decoding): split the byte array at each `0x0A`, skip a leading UTF-8 BOM (`EF BB BF`) on line 1,
and match the ASCII marker bytes line by line with a 3-state scan — state 0 wants a line starting
with seven `<` (0x3C) then a space; state 1 wants a line that is exactly seven `=` (0x3D); state 2
wants a line starting with seven `>` (0x3E) then a space. Fired = state 3 reached; the matched line
numbers are the three line numbers recorded. Illustrative snippet (tested):
```powershell
$b=[IO.File]::ReadAllBytes("<work>/mine/<project-path>"); $st=0; if($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF){$st=3}; $state=0; $hits=@(); $ln=1
for($i=$st;$i -le $b.Length;$i++){ if($i -eq $b.Length -or $b[$i] -eq 10){ $len=$i-$st; $ch=60+$state; $ok=$len -ge 7; for($k=0;$ok -and $k -lt 7;$k++){ if($b[$st+$k] -ne $ch){$ok=$false} }; if($ok){ if($state -eq 1){$ok=($len -eq 7)}else{$ok=($len -ge 8 -and $b[$st+7] -eq 32)} }; if($ok){$hits+=$ln; $state++; if($state -eq 3){break}}; $st=$i+1; $ln++ } }
"guard fired: $($state -eq 3) lines: $($hits -join ',')"
```
This narrows, but does not eliminate, false positives: a Tier 2 file that documents conflict
markers in a code block (a tutorial/example containing the full triple) is still flagged. When the
guard fires, report the line numbers of the three matched lines so the user can tell a stale
marker block from example text, and include the recovery steps below in the final summary.

**Recovery from a marker-guard flag** (the guard only inspects `MINE`; it never edits files):

1. *Real, leftover markers:* resolve them in the file (keep the right side, delete the marker
   lines). The upstream hunks that were in the markers are then part of your file, so nothing is
   lost; the next `/sync-toolkit` merges the file normally against the version recorded in
   `.ai/.toolkit-sync-state.json`. Optionally record the file as resolved (option 3).
2. *False positive (example text that happens to hold the full triple):* the file was **not**
   merged this run, and the state file now records the target version as installed, so a re-run
   will not merge it. Reconcile it by hand: compare `<project-path>` with the toolkit's new
   template (`core/<manifest-path>` in `<source>` at the target version's tag; placeholders
   unfilled, `.template` suffix kept) and apply the toolkit's changes yourself, then record the
   file as resolved (option 3).
3. *Record a file as reconciled* (after the user has resolved it by hand, or decided the
   upstream changes are not wanted): update that one file's entry in
   `.ai/.toolkit-sync-state.json` — `lastMergeResult` → `resolved-manually`, `lastUpdatedAt` →
   now — using the same **atomic write** as Shared Conventions (read the whole file, change only
   that entry, write everything to `.ai/.toolkit-sync-state.json.tmp`, verify it parses and the
   key set is unchanged, then `Move-Item … -Force`). Leave `toolkitVersion`, `stack`, `syncedAt`
   and every other entry as they are. This is bookkeeping only: it records the outcome for
   whoever reads the file and does not change what a future merge uses as `BASE` (that is always
   derived from `toolkitVersion`). Use it only after the file has really been reconciled.

**Risk of the `NO MERGE BASE` row (do not understate it).** At the end of this run the state
file's `toolkitVersion` becomes the target version, so on the next sync `BASE` for this file is
the target template and the upstream changes saved in `<project-path>.toolkit-new` will be
silently considered "already applied" — they are never offered again unless the user acts. This
file is therefore reported as **needs manual resolution** (same tier as an unresolved conflict),
not as a passive note: the user must manually reconcile `<project-path>.toolkit-new` into
`<project-path>` and then delete the `.toolkit-new` file **now**, before the next sync.

**The same risk applies to every file that this run did not bring up to the target version**
(`no-merge-base`, `utf16-32-not-merged`, `markers-not-merged`, `error`). `BASE` is derived from
the single project-wide `toolkitVersion`, so once it advances, those files' upstream changes are
treated as already applied on the next run, and a re-run does **not** retry them. They are
therefore all reported at the same visibility as an unresolved conflict, with the instruction to
reconcile them by hand now. A file with fresh conflict markers (`conflict (<n>)`) is different:
the upstream hunks are in `MINE` for the user to resolve, and the marker guard protects it from
being merged again on top of its markers.

### Step 3 — Run the three-way merge

For each file that reached "otherwise" in Step 2, using only the LF-normalized copies from Step 1
item 3 (the **normalize → compare → merge → restore** sequence; Step 4 does the restore):

1. Copy the normalized `MINE` (`<work>/mine/<project-path>`) to `<work>/merge/<project-path>`
   (create folders as needed). The merge runs on this `merge` copy so the normalized `MINE` stays
   intact for Step 4's comparison; the original `MINE` is not touched here. Do not merge the raw files.
2. Run, with your own `run_in_terminal` call, a merge **in place on the `merge` copy** (no output
   redirection and no pipe — PowerShell pipes can alter line endings and encodings):
   ```powershell
   git merge-file -L "project (current)" -L "installed toolkit <installed version>" -L "toolkit <target version>" "<work>/merge/<project-path>" "<work>/base/<manifest-path>" "<work>/theirs/<manifest-path>"
   ```
   Argument order is *current, base, other*: `MINE`'s copy, then `BASE`, then `THEIRS`. `git merge-file`
   is a plain three-file text merge; it works on loose files and does not need this project, or
   any of the three files, to be inside a git repository. Quote every path (they may contain
   spaces). Read the exit code immediately (`$LASTEXITCODE`). Because all three inputs are LF,
   the result and any conflict markers are LF too.
3. Interpret the exit code:
   - `0` — clean merge.
   - `1`–`127` — that many conflicts; the `merge` copy now contains standard conflict markers
     (`<<<<<<< project (current)` … `=======` … `>>>>>>> toolkit <target version>`).
   - anything else (e.g. `255` / negative — usually a binary or unreadable file) — error.

### Step 4 — Apply the result

**Restore `MINE`'s line endings before writing anything back.** The merged `merge` copy is LF.
If `MINE`'s recorded dominant style (Step 1 item 3) is `CRLF`, first convert the `merge` copy to
CRLF in a separate scratch file, again **byte-level only** (no text decoding, no pipe). Algorithm:
read all bytes of the `merge` copy; copy them to a new byte list, inserting a `0x0D` before every
`0x0A` that is not already preceded by `0x0D`; write the list with `WriteAllBytes`. BOM bytes and
multi-byte UTF-8 sequences pass through unchanged. Illustrative snippet (tested):
```powershell
$b=[IO.File]::ReadAllBytes("<work>/merge/<project-path>"); $o=New-Object 'System.Collections.Generic.List[byte]' ($b.Length+64); for($i=0;$i -lt $b.Length;$i++){ if($b[$i] -eq 10 -and ($i -eq 0 -or $b[$i-1] -ne 13)){$o.Add(13)}; $o.Add($b[$i]) }; [IO.File]::WriteAllBytes("<work>/out/<project-path>",$o.ToArray())
```
(create `<work>/out/...` folders first). If the style is `LF`, the merged `merge` copy is already
final and is used directly. Never write an LF-only result over a CRLF file, and never leave the
two styles mixed. "Differs from `MINE`" below is decided **before** restoring, by comparing the
`merge` copy with the untouched normalized `MINE` copy (so a difference that is only line
endings never counts as a change); "the file to write" below means the restored output.

- **Exit `0` (clean):** if the merged LF result differs from the normalized `MINE`, copy the
  restored output over `<project-path>`
  (`Copy-Item -LiteralPath <restored output> -Destination <project-path> -Force`) and record
  `clean-merged`; if it is identical, leave `MINE` untouched and record `unchanged`.
  State entry: refresh (`clean-merged` / `unchanged`).
- **Exit `1`–`127` (conflicts):** copy the restored output, **with its conflict markers**, over
  `<project-path>` and record `NEEDS MANUAL RESOLUTION (<n> conflict(s))`. **Never resolve a
  conflict by silently picking one side, and never drop the markers.** Clean hunks in the same
  file are already merged by `git merge-file`; only genuine conflicts carry markers. State entry:
  refresh, `lastMergeResult` = `conflict (<n>)` (the markers hold the upstream hunks for the user
  to resolve; the marker guard in Step 2 protects an unresolved file from being merged again on
  top of its markers).
- **Error:** leave `<project-path>` untouched and record `ERROR — not merged (<reason>)`.
  State entry: record only, `error`. Continue with the remaining files and list it in the summary
  so the user can reconcile it by hand (a re-run does not retry it — see the risk notes after
  Step 2's table).

If `MINE` had mixed line endings, add "mixed line endings normalized to <style>" next to that
file's outcome in the final summary.

### Step 5 — Post-merge placeholder check

For every file recorded `clean-merged` or conflicted, search the merged `<project-path>` for
`{{...}}` tokens that were **not** present in `MINE` before the merge (the toolkit template
introduced a new placeholder). Do not fill them; list file + token under "Placeholders still
pending" in the final summary.

### Step 6 — Write `.ai/.toolkit-sync-state.json` (the last write of the run)

Everything else this run changes in the project (Update Mode Steps 3, 4 and 6, and this section's
Steps 3–4) must already be done; this file is written **absolutely last**, so that its content
naming the target version always means the update run completed. If the run was aborted or a
failure stopped it before this point, do **not** write it — the file keeps naming the installed
version and a re-run repeats the update. The state file is tool-owned bookkeeping, so rewriting it
needs no user confirmation.

1. **Read the prior state.** Re-read `.ai/.toolkit-sync-state.json` from disk (it is unchanged
   since Update Mode Step 1 because only this step writes it). If the project came from the
   legacy layout there is no prior `files` map; treat every entry as new.
2. **Build the new content:** `toolkitVersion` = the target version (`<target>/VERSION`,
   trimmed); `stack` unchanged from the installed value; `syncedAt` = the current ISO 8601 UTC
   time (ask the user if you cannot determine it); `files` = exactly one entry per path in the
   **target Tier 2 set**, built from each file's Step 2/4 "State entry" decision:
   - **refresh** → `lastUpdatedAt` = now, `lastMergeResult` = the value from the table/Step 4
     (`unchanged`, `clean-merged`, `conflict (<n>)`);
   - **record only** → `lastMergeResult` = the value from the table/Step 4 (`not-present`,
     `utf16-32-not-merged`, `markers-not-merged`, `no-merge-base`, `error`); `lastUpdatedAt`
     keeps its prior value, or = now if the entry is new or there was no prior `files` map.
   Entries in the prior `files` map whose path is not in the target Tier 2 set (dropped or
   deprecated files) are simply not carried over; a Tier 2 path new to the target set gets a
   fresh entry. Nothing else is persisted: no template content, no per-file version.
3. **Write atomically** with the procedure in Shared Conventions: write the content to
   `.ai/.toolkit-sync-state.json.tmp`, re-read and verify it is valid JSON whose `toolkitVersion`
   is the target version and whose `files` keys equal the target Tier 2 set exactly, then
   `Move-Item -LiteralPath '.ai/.toolkit-sync-state.json.tmp' -Destination '.ai/.toolkit-sync-state.json' -Force`.
   If verification fails, delete the `.tmp` file, leave the real file untouched, and report the
   difference.
4. **Legacy folder.** If the old `.ai/.toolkit-sync-state/` folder (`version.json` + `baseline/`)
   exists, tell the user it is now obsolete and is no longer read; remove it
   (`Remove-Item -LiteralPath '.ai/.toolkit-sync-state' -Recurse -Force`) only on their explicit
   confirmation, otherwise leave it and mention it in the summary.

### Step 7 — Clean up this run's temporary files

Remove, and only these: `<work>` (Step 1), and — for each staging copy Update Mode Step 2
extracted — `<stage>` and `<stage>.tar` (the target) and `<stage-installed>` and
`<stage-installed>.tar` (the installed version)
(`Remove-Item -LiteralPath <path> -Recurse -Force`). Paths are the exact ones this run created;
never glob `toolkit-*` and never remove other leftovers (just mention them). When `<installed>` =
`<target>`, or either is `<source>`, there is no separate staging copy for it. **Never remove
`<source>`**, including when `<target>` or `<installed>` = `<source>`. A cleanup failure is not an
update failure: report the path so the user can delete it. If the run aborts after staging was
created, remove this run's `<work>`/`<stage>`/`<stage>.tar`/`<stage-installed>`/
`<stage-installed>.tar` before stopping.

### Step 8 — Final summary, then stop

Print one report that combines the Update Mode Step 7 interim summary (missing/added, deprecated,
unrecognized, Tier 1 overwritten, warnings) with:

- Target version and previous (installed) version.
- Every Tier 2 file with its outcome: `unchanged` / `clean-merged` / `NEEDS MANUAL RESOLUTION`
  (with conflict count, or the reason) / `NO MERGE BASE — NEEDS MANUAL RESOLUTION (compare manually)` (with the
  `.toolkit-new` path) / `not present in project` / `ERROR — not merged`.
- A prominent **"Needs manual resolution"** list. It must contain, at the same visibility: (a) files
  containing conflict markers (search for `<<<<<<<` to resolve), (b) files skipped by the marker
  guard (with the matched line numbers and the Recovery steps from Step 2), (c) any file not
  merged (`ERROR`, or skipped as UTF-16/32), and (d) **every `<project-path>.toolkit-new` file
  created this run**, each with this warning: *the upstream changes in this file are NOT in your
  project file, and the sync state now records the target version as installed, so the next sync
  will not offer them again; reconcile `.toolkit-new` into the project file and delete it now, or
  those changes are lost.* The same warning (without the `.toolkit-new` part) applies to every
  file in (b) and (c): it was not brought up to the target version, and a re-run will not retry
  it. Give the instruction to resolve/review each item and review the diff.
- Sync state: `.ai/.toolkit-sync-state.json` written (new `toolkitVersion`, count of `files`
  entries, and any entries whose `lastMergeResult` is not `unchanged` / `clean-merged`), plus
  whether a legacy `.ai/.toolkit-sync-state/` folder was found and what happened to it.
- Placeholders still pending (Step 5, plus Update Mode findings) and files not classified in
  `manifest.json`.
- Cleanup result (Step 7).
- A closing instruction: review the changes and commit them in this repo yourself; this command
  made no commits and pushed nothing.

Then **stop**. Do not run `git add`, `git commit` or `git push`.

<!-- ============================================================================
     SECTION: GENERATOR MODE  (`--generator <name>`, standalone re-run of one generator)
     ============================================================================ -->

## Generator Mode (`--generator <name>`)

Re-runs **one** toolkit generator on an already-installed project, without a full install or
update. Typical uses: regenerate the data dictionary after a schema change, or rebuild the
knowledge base after a large refactor. Generators are never installed into the project, so this
mode always reads the generator from `<source>/generators/`.

Use the **Path mapping** and **Sync state** definitions from Shared Conventions unchanged.

### Step 1 — Preconditions

1. `.ai/.toolkit-sync-state.json` must exist in this project (for a project installed by an older
   toolkit version, the legacy `.ai/.toolkit-sync-state/version.json` also counts; read
   `toolkitVersion` and `stack` from whichever exists). If neither does, stop and tell
   the user the project is not installed yet: run `/sync-toolkit --source <path>` (install mode)
   first. Do not run the generator.
2. Resolve `<name>`: strip a trailing `.prompt.md` if present, then require that
   `<source>/generators/<name>.prompt.md` exists. If it does not, stop and list the available
   names (the `create-*.prompt.md` files under `<source>/generators/`, without suffix) — do not
   guess a close match.
3. If `<source>/VERSION` (trimmed) differs from the installed `toolkitVersion` in the sync state,
   warn the user that the generator comes from a different toolkit version than the one installed
   (suggest running update mode first) and continue only on their confirmation. This is a warning
   only; this mode never changes the installed version.
4. Check the generator's prerequisite from the **Step 6 table in Install Mode** (for example every
   generator except `create-knowledge-base` needs `.ai/knowledge-base.md`; `create-build-settings`
   also needs the output of `create-coding-standards`; `create-domain-agent` reads
   `.ai/governance/coding-standards.md`). If a prerequisite output is missing, stop and tell the
   user which generator to run first.

### Step 2 — Run the generator

Read `<source>/generators/<name>.prompt.md` and execute its instructions directly against this
project — never copy it into this project first.

- **Reuse known project facts; do not re-ask.** Where the generator asks for `PROJECT_NAME`,
  `SYSTEM_DESCRIPTION`, `PVD_PATHS`, `CODE_ROOT` or similar, take the value from what this project
  already records: `PROJECT_NAME` from `AGENTS.md` (the filled-in project name) and the other
  values from `.ai/knowledge-base.md` where it states them. Ask the user only for a value that is
  not recorded anywhere, and for generator-specific questions the generator itself raises (for
  example the database engine for `create-data-dictionary`, or the remote URL and branch prefixes
  for `create-scm-workflow`).
- **Skip the generator's own self-delete step** ("delete this file from `.github/prompts/`"):
  there is nothing to delete in this project, and you must never delete or modify anything inside
  `<source>`.
- **Existing output.** A re-run normally regenerates files that already exist (that is the point).
  Before overwriting a generated file that the user may have hand-edited since the last run, tell
  them which files will be rewritten and get their confirmation; honour any backup/overwrite
  handling the generator already defines.
- **Placeholders.** The install-time substitutions (Install Steps 5 and 6a) are not repeated here;
  the generator fills only what it owns. Tokens already filled in the project stay filled.
- If the generator stops or fails (for example the documented known-gap message from
  `create-data-dictionary` for a non-SQL-Server database), stop and relay its message; this is not
  an error in the project.

### Step 3 — Do not touch the sync state

This mode **never writes, modifies or deletes `.ai/.toolkit-sync-state.json`** (nor its `.tmp`
scratch file, nor a legacy `.ai/.toolkit-sync-state/` folder) — `toolkitVersion` and the `files`
map stay exactly as they were. Re-running one generator is not a toolkit
version change, and the files it produces are project-owned (Tier 3) or placeholder fills inside
Tier 2 files that the next update merges normally.

### Step 4 — Report and stop

Do **not** run `git add`, `git commit` or `git push`. Report: the generator that ran, every file it
created or changed (and any it skipped or left unchanged), anything it left pending or could not
do, and a closing instruction to review the changes and commit them in this repo yourself — this
command made no commits.

<!-- ============================================================================
     END OF FILE. Install Mode + Update Mode + 3-Way Merge + Generator Mode together are the complete /sync-toolkit.
     ============================================================================ -->
