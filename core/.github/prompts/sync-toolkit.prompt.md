---
description: Install or update the AI Automation Toolkit in this project.
---

# /sync-toolkit

Installs the AI Automation Toolkit into this project (**install mode**), brings an existing
installation up to a newer toolkit version (**update mode**), re-runs a single generator on an
already-installed project (**generator mode**, `--generator <name>`), or records that one file
was reconciled by hand (**mark-reconciled mode**, `--mark-reconciled <manifest-path>`).

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
- `--version <tag>` (optional, **update mode only**): git tag to sync to (a leading `v` is
  optional; see **Version strings** in Shared Conventions). Defaults to the source
  clone's current `VERSION` file content if omitted. In install mode this argument is ignored; if
  the user supplied it, tell them so, and remind them that install uses whatever the source clone
  currently has checked out.
- `--generator <name>` (optional, **standalone generator mode**): the name of one toolkit generator
  to re-run on this already-installed project, with or without the `.prompt.md` suffix (for example
  `create-data-dictionary`). When present, run **Generator Mode** below and nothing else: it is
  mutually exclusive with `--mode`, `--version` and `--mark-reconciled` (if the user supplies any
  of them alongside `--generator`, say so and ask which they mean). Generators are never copied
  into this project; they are always read from `<source>/generators/`.
- `--mark-reconciled <manifest-path>` (optional, **standalone mark-reconciled mode**): the
  manifest path of one Tier 2 file (the key used in `.ai/.toolkit-sync-state.json`, e.g.
  `AGENTS.md.template`, with its `.template` suffix kept) that you have finished reconciling by
  hand and want the sync state to treat as caught up. When present, run **Mark-Reconciled Mode**
  below and nothing else: it is mutually exclusive with `--mode`, `--version` and `--generator`
  (same handling as above if combined). This is the only sanctioned way to change one file's
  state entry by hand-driven reconciliation; never edit `.ai/.toolkit-sync-state.json` directly.
- `--mode install|update` (optional): if omitted, auto-detect — `install` if neither
  `.ai/.toolkit-sync-state.json` nor the legacy `.ai/.toolkit-sync-state/version.json` (see Update
  Mode Step 1) exists in this project, `update` otherwise. If the user explicitly passes
  `--mode install` but either of those already exists, stop and warn that a re-install would
  overwrite customized Tier 2 files; continue only on explicit confirmation, and in that case treat
  every existing destination file as a conflict (see Install Step 4).

After parsing, verify `<source>` contains `manifest.json`, `VERSION`, `core/`, `generators/`,
`stacks/`, and `data-dictionary-tooling/`. If any is missing, stop and report which one.

Then branch on the resolved mode: run **Generator Mode** if `--generator` was given,
**Mark-Reconciled Mode** if `--mark-reconciled` was given, otherwise **Install Mode** or
**Update Mode** below.

---

## Shared Conventions

These definitions are used by all modes. Do not redefine them in a mode section.

**Path mapping.** `manifest.json` lists files under two different roots:

| Manifest entry | Source location | Location in this project |
|---|---|---|
| Tier 2 entries (e.g. `.github/agents/ticket-processor.agent.md`, `AGENTS.md.template`, `README.md.template`) | `<source>/core/<entry>` | `<entry>`, with a trailing `.template` suffix stripped (`AGENTS.md.template` → `AGENTS.md`, `README.md.template` → `README.md`, `.github/copilot-instructions.md.template` → `.github/copilot-instructions.md`) |
| Tier 1 entries (today: `.github/prompts/sync-toolkit.prompt.md`, `.github/agents/sync-toolkit.agent.md`) | `<source>/core/<entry>` | `<entry>`, `.template` stripped |
| Tier 3 patterns (`.ai/knowledge-base.md`, `.ai/data-dictionary/**`) | never copied | produced by generators; **never touched by sync** |

**Generators are source-only.** `<source>/generators/` is never copied into this project and has no
manifest entries; there is no `generators/` folder in an installed project. Install Mode (Step 6)
and Generator Mode read a generator directly from `<source>/generators/<name>.prompt.md` and
execute it against this project.

**Stack overlays are source-only.** `<source>/stacks/<stack>/` is never copied into this project and
has no manifest entries; there is no `stacks/` folder in an installed project. The overlay's
`notes.md` is only a hint that the `create-build-settings` generator reads directly from
`<source>/stacks/<chosen-stack>/notes.md` while it runs.

**Data-dictionary tooling is source-only.** `<source>/data-dictionary-tooling/` is never copied
into this project and has no manifest entries; there is no `data-dictionary-tooling/` folder in an
installed project. The `create-data-dictionary` generator reads its two export queries directly
from `<source>/data-dictionary-tooling/*.sqlserver.sql` while it runs and prints their full content
into chat — nothing is ever copied there first.

Every Tier 1 entry is found under `core/` (`<source>/core/<entry>`, `.template` suffix stripped).

**Whole-`core/` rule.** Install copies **every** file under `<source>/core/` — not only the files
named in `manifest.json`. A `core/` file absent from the manifest is a toolkit bug: still copy it,
and list it in your final report under "Files not classified in manifest.json".

**Working directory.** Every relative path in this prompt (`.ai/...`, `.github/...`, manifest
paths) is relative to this project's root, and every terminal command assumes the current working
directory **is** the project root. Before the first command that reads or writes a project file,
confirm it (`Get-Location`) and change into the project root if it is not; never run a command
against a guessed location. PowerShell's current location is **not** the same as .NET's process
working directory, so any snippet that passes a relative path to a `[IO.File]` method must first
turn it into an absolute path (`(Resolve-Path -LiteralPath '<path>').Path`); in the snippets in
this prompt, substitute **absolute** paths for placeholders such as `<src>`, `<dest>` and `<MINE>`.

**Sync state** lives in one file in this project: `.ai/.toolkit-sync-state.json` (a file directly
under `.ai/`, not a folder). Schema:

```json
{
  "toolkitVersion": "1.4.0",
  "stack": "dotnet-mvc",
  "syncedAt": "2026-10-16T12:00:00Z",
  "files": {
    "AGENTS.md.template": { "baseVersion": "1.4.0", "lastUpdatedAt": "2026-10-16T12:00:00Z", "lastMergeResult": "clean-merged" },
    ".github/agents/ticket-processor.agent.md": { "baseVersion": "1.2.0", "lastUpdatedAt": "2026-09-01T09:30:00Z", "lastMergeResult": "no-merge-base" }
  }
}
```

- `toolkitVersion` — **informational only**: the last toolkit version this project *attempted* to
  sync to, in bare form (the trimmed content of `<source>/VERSION`, never with a leading `v`). It
  is written unconditionally at the end of every install and update run, whatever the per-file
  outcomes, and it is never used to choose a merge base. Update Mode only compares the target
  version with it for the "same version" / downgrade warnings. Generator Mode and
  Mark-Reconciled Mode never touch it.
- `stack` — the stack overlay chosen at install (`none` if none).
- `syncedAt` — ISO 8601 UTC time of the last completed install/update **run**.
- `files` — exactly one entry per Tier 2 manifest path, keyed by the manifest path itself (so
  `AGENTS.md.template` stays `AGENTS.md.template`). Each entry has:
  - `baseVersion` — the toolkit version this specific file is considered **caught up to**, in
    bare form: the version whose template is this file's `BASE` in the **next** update merge.
    This is the field that must be correct; everything else is reporting. Different files can
    legitimately sit at different `baseVersion`s (for example one file whose merge could not be
    attempted stays behind while the others advance), which is why one project-wide version
    cannot express the state. It is `null` only for an entry that has no known ancestor (a Tier 2
    path that was new to the manifest while its project file already existed); such a file has no
    `BASE` and is handled as `NO MERGE BASE` (3-Way Merge Step 2).
  - `lastUpdatedAt` — ISO 8601 UTC time at which this file's `baseVersion` last advanced. It is
    **not** bumped when a run leaves the file behind, so a stale value shows the file has not
    really synced.
  - `lastMergeResult` — the outcome of the latest run for this file; one of: `installed`
    (written by Install), `unchanged`, `clean-merged`, `conflict (<n>)` (for example
    `conflict (2)`), `no-merge-base`, `utf16-32-not-merged`, `markers-not-merged`, `error`,
    `not-present` (the project's file does not exist), `manually-reconciled` (set only by
    Mark-Reconciled Mode), or `migrated` (the in-memory prior entry for a project that came from
    the legacy layout; see Update Mode Step 1 — it is replaced by the file's real outcome in the
    same run). These are the short forms of the outcomes the 3-Way Merge section reports (Step 2's
    table and Step 4's rules map each one).

  The state stores a version **pointer** per file and never any template content: update mode
  re-derives each file's `BASE` from the toolkit's git history at that file's `baseVersion`
  (Update Mode Step 2, item 5).

**Per-file `baseVersion` advancement.** This table is the single rule for how a Tier 2 file's
state entry is written, by every mode. *Advances* = `baseVersion` becomes the target version (bare
form) and `lastUpdatedAt` becomes now. *Stays* = `baseVersion` and `lastUpdatedAt` keep their prior
values (`baseVersion` = `null` and `lastUpdatedAt` = now only if the file had no prior entry);
only `lastMergeResult` changes.

| Outcome (`lastMergeResult`) | `baseVersion` | `lastUpdatedAt` |
|---|---|---|
| `installed` (Install Mode) | the version being installed | now |
| `unchanged` | advances | now |
| `clean-merged` | advances | now |
| `not-present` (no project file; nothing can be out of date — a later generator or install-from-template run produces it from this or a newer template) | advances | now |
| `conflict (<n>)` — a **fresh** conflict: the markers were written into the file during **this** run | advances (the diff *was* delivered, as literal markers; resolving them is cleanup, not re-diffing) | now |
| `manually-reconciled` (Mark-Reconciled Mode) | the version the user confirmed | now |
| `markers-not-merged` — the file already held unresolved markers from an **earlier** run when this run started | stays (never re-derived: the file has not caught up past its last real conflict) | not bumped |
| `no-merge-base` (no usable `BASE`) | stays | not bumped |
| `utf16-32-not-merged` | stays | not bumped |
| `error` | stays | not bumped |

The rule that decides "advances vs stays" is: **was this file's diff from its old `baseVersion` to
the target delivered into the file this run?** Delivered (the file now equals, or is merged with,
or holds literal markers for the target's changes) → advances. Never delivered (no merge base,
encoding blocked, error, or the file still holds unresolved markers from before so no new merge
was attempted) → stays.

**Version strings.** Everywhere a version is compared or looked up, a leading `v` is ignored:
`1.3.0` = `v1.3.0` (the toolkit's tags look like `v1.3.0`; its `VERSION` file and this state
file hold `1.3.0`). *Lookup:* to find a version's git tag, try `<version>` as given, then
`v<version>` if it does not already start with `v`, then (only if it did start with `v`) the
content without it, and use the first candidate that resolves
(`git -C <source> rev-parse --verify --quiet "<candidate>^{commit}"`). *Comparison:* strip one
leading `v` from both sides first. *Storage:* always write the bare form (leading `v` stripped) to
`toolkitVersion` and to every `baseVersion`, whichever form the user passed to `--version` or
typed when confirming a version. This applies uniformly to the target version, each file's
`baseVersion` and `<source>/VERSION`.

This file is the single "the sync is complete" marker, so it must never be left partially written.
**Atomic write — mandatory at every place this file is written** (Install Step 7, 3-Way Merge
Step 6, and Mark-Reconciled Mode Step 4). Never overwrite `.ai/.toolkit-sync-state.json`
directly:

1. Build the full new content (valid JSON, UTF-8 **without** BOM).
2. Write it to `.ai/.toolkit-sync-state.json.tmp`. If a leftover `.tmp` from an interrupted run
   exists, it is this prompt's own scratch file: remove it first
   (`Remove-Item -LiteralPath '.ai/.toolkit-sync-state.json.tmp' -Force`), then create the file
   with your file-creation tool.
3. Verify the write: re-read the `.tmp` file's **bytes** and confirm (a) it does **not** start
   with a UTF-8 BOM (`EF BB BF`), (b) it parses as JSON, (c) `toolkitVersion` is the intended
   value, (d) the `files` keys are exactly the intended set, and (e) every entry has a
   `baseVersion` property (a string, or `null` only where this prompt allows it), e.g.:
   ```powershell
   $b=[IO.File]::ReadAllBytes((Resolve-Path -LiteralPath '.ai/.toolkit-sync-state.json.tmp').Path); "BOM=$($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)"; $j=[Text.Encoding]::UTF8.GetString($b) | ConvertFrom-Json; $j.toolkitVersion; @($j.files.PSObject.Properties.Name).Count; "missing baseVersion=$(@($j.files.PSObject.Properties | Where-Object { -not $_.Value.PSObject.Properties['baseVersion'] }).Count)"
   ```
   Expect `BOM=False`, the intended `toolkitVersion`, the intended key count and
   `missing baseVersion=0`. Where a write changes only some entries, also compare the unchanged
   entries with the prior file. If any check fails, delete the `.tmp` file, leave the real file
   untouched, stop and report.
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
2. Files are written **byte-for-byte except for** the `{{PROJECT_NAME}}`, `{{REQUIRED_MODEL_LIST}}`,
   `{{PROJECT_SPECIFIC_FIXES}}` and `{{STACK_CHECKLIST}}` (wcag-fix-patterns.md only) substitutions
   in Step 5. Those substitutions never apply to `.github/prompts/sync-toolkit.prompt.md` (see
   Step 5). Generators, stack overlays and data-dictionary tooling are not part of this plan at
   all: they stay in `<source>/generators/`, `<source>/stacks/` and
   `<source>/data-dictionary-tooling/` respectively, and are only ever read directly from
   `<source>` when the `create-data-dictionary` generator runs (Step 6, #7).

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
| 7 | `create-data-dictionary.prompt.md` | No generator dependency, but needs user-supplied CSV exports from the user's database (it will pause and ask). Runs last, and only if not already present (see the rule below). |

Rules for this order:

- #1 first, always. #2 before #3. #2 before #6.
- #4 and #5 may run at any point after #1; the table order is the recommended one.
- **#7's "already present" check.** Before running #7, check whether `.ai/data-dictionary/`
  already contains generated content (any of `db-schema-dictionary.md`, `stored-procedures.md`,
  `stored-procedure-dataflows.md`, `README.md` — the four files this generator writes). This is
  not expected on a true from-scratch install, but can happen when adopting a project that already
  had a hand-maintained data dictionary, or when re-running `--mode install` over an existing
  install (Step 4). If any of the four files already exist, **do not run the generator and do not
  ask the user anything about it** — skip it silently and record "data dictionary: already
  present, not regenerated — run `/sync-toolkit --source <path> --generator create-data-dictionary`
  to refresh it" in the Step 8 report. Only when none of the four files exist does this install run
  the generator normally (it asks the database-engine question, prints the export queries in chat,
  and waits for the CSVs, exactly as Generator Mode does for an explicit re-run).
- #7 is last because it pauses for user action (database engine question, CSV exports). If the
  generator runs and the user wants to defer it, skip it, continue to Step 7, and record "data
  dictionary: not generated" in the report with the instruction to run it later via
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
    "<manifest-path>": { "baseVersion": "<same as toolkitVersion>", "lastUpdatedAt": "<same timestamp>", "lastMergeResult": "installed" }
  }
}
```
The `files` map has one entry for **every Tier 2 file in the manifest** (Step 1), keyed by its
manifest path (`.template` suffix kept) — and no Tier 1 or Tier 3 paths. Every entry is
`"installed"` with `baseVersion` = the installed `toolkitVersion`, including files the user kept
or saved as `.toolkit-new` in Step 4 (update mode treats a kept file as customized against the
installed template, so that version is its `BASE`). Before the rename, the verification step must
confirm the `files` key set equals the manifest's Tier 2 set exactly.

### Step 8 — Stop and report

Do **not** run `git add`, `git commit` or `git push`. Print a summary containing:

- Toolkit version and stack installed.
- Every file created, grouped as: core files,
  sync state (`.ai/.toolkit-sync-state.json`, with its Tier 2 `files` entry count). Generators,
  stack overlays and data-dictionary tooling are not copied into the project, so there is no
  generators group, no stack overlay group and no data-dictionary tooling group.
- Files skipped or saved as `.toolkit-new` in Step 4.
- Each generator that ran and its outcome, plus any skipped (e.g. data dictionary deferred, or
  already present — see Step 6's "already present" check). Tell the user
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
  check only the entries the manifest actually lists. Generators, stack overlays and
  data-dictionary tooling have no manifest entries and are never expected in the project
  (regardless of which stack was chosen), so there is nothing to check for them.
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
handling is complete. Consequence: if this procedure is interrupted at any point, the file is
unchanged, so a re-run repeats update mode with the same per-file `BASE` versions. There
is no separate "corrupt baseline" case: nothing is persisted locally except that one file, and it
is only ever replaced whole.

**What a re-run does.** Each Tier 2 file carries its own `baseVersion` (Shared Conventions, **Per-file
`baseVersion` advancement**), and the next run derives that file's `BASE` from it. A file whose
diff was delivered last time (merged cleanly, left `unchanged`, or written with literal conflict
markers) advanced, so the next run starts from the new version: the changes it already received are
never re-offered, and a conflict the user has since resolved by hand — in any way, including by
keeping their own text — is not re-diffed. A file whose diff was **never** delivered (no merge
base, UTF-16/32, error, or still holding unresolved markers from an earlier run) stayed at its old
`baseVersion`, so the next run retries it against its true common ancestor; the changes it missed
are not hidden. Re-running after a **completed** run is therefore safe: each step is idempotent
(re-copying a missing file, re-overwriting a Tier 1 file and re-listing deprecated/unrecognized
files change nothing the second time), and the staging directories are uniquely named per run
(Step 2) so a leftover from an interrupted run never blocks a re-run. Never write "partial done"
state anywhere.

**Edge case: a run interrupted between writing conflict markers and writing the state file.** A
fresh conflict writes its markers into the project file during the 3-Way Merge section's Step 4,
but that file's `baseVersion` only advances when the state file is written (its final state-write
step). If the run is interrupted in between, the file holds markers while its entry in
`.ai/.toolkit-sync-state.json` still records the old `baseVersion`. If you resolve those markers
with anything other than the toolkit's side verbatim and then simply re-run, the old
`baseVersion` makes the merge re-offer the same hunks and conflict again. **Recovery:** if you
find unresolved markers in a Tier 2 file and its entry in `.ai/.toolkit-sync-state.json` shows no
corresponding change (the `baseVersion`/`lastUpdatedAt` did not advance and `lastMergeResult` is not
`conflict (<n>)`), resolve the markers and then run
`/sync-toolkit --source <path> --mark-reconciled <manifest-path>` against the target version the
markers came from, to confirm the reconciliation explicitly; do not assume a plain re-run will
treat it correctly. The top-level
`toolkitVersion` is informational only and is written at the end of every completed run; the
per-file `baseVersion` is the only thing that records how far each file has caught up.

Use the **Path mapping**, **Whole-`core/` rule** and **Sync state** definitions from Shared
Conventions unchanged. Do not invent a different mapping for update mode.

### Step 1 — Read the recorded state

Read `.ai/.toolkit-sync-state.json` in this project to get `toolkitVersion` (the last version a
run attempted to sync to; informational), `stack` and the `files` map, including each entry's
`baseVersion`. If it is missing, unparseable, or lacks `toolkitVersion` or `files`:

- **Legacy layout (migration).** If `.ai/.toolkit-sync-state/version.json` exists (an install
  made by a toolkit version that kept a `version.json` + `baseline/` folder instead of this
  file), migrate it in memory (nothing is written until the 3-Way Merge section's final state
  write):
  - Read `toolkitVersion`, `stack` and `syncedAt` from `version.json`; call that `toolkitVersion`
    `<legacy-version>`. It is also the prior top-level `toolkitVersion`.
  - Build the prior `files` map from the legacy `baseline/` folder: for every file present in
    `baseline/` whose path is a Tier 2 manifest path of the target, create a prior entry
    `{ "baseVersion": <legacy-version>, "lastUpdatedAt": <version.json syncedAt>, "lastMergeResult": "migrated" }`.
    A Tier 2 path with no `baseline/` file gets no prior entry (it is a new entry with no known
    ancestor; the project is still treated as installed, never as not-yet-installed). If
    `syncedAt` is missing, use now. From here the project is tracked per file like any other: each
    file's `BASE` comes from its own `baseVersion` (Step 2, item 5), with no project-wide
    special case.
  - Do not touch the legacy folder during this run; the 3-Way Merge section's Step 6 (item 4)
    says when it may be offered for removal.
- **Otherwise** stop: this is not a completed install (re-run in install mode). Do not
  reconstruct the file.

**Legacy baseline rule** (applies to the migration run above, and to any later run for as long as
the legacy `.ai/.toolkit-sync-state/` folder still exists next to the new state file). The legacy
`baseline/` held each file's *true* common ancestor, which for a file left unresolved by an
earlier sync is **older** than `version.json`'s version, so recording `<legacy-version>` as that
file's `baseVersion` may be too new for it. Therefore, while both
`.ai/.toolkit-sync-state/version.json` and `.ai/.toolkit-sync-state/baseline/<manifest-path>`
exist, a file's `BASE` is that legacy baseline file (instead of a version extraction) whenever its
prior entry has `baseVersion` equal to `<legacy-version>` (read from `version.json`; leading `v`
ignored) **and** `lastMergeResult` is one of `migrated`, `no-merge-base`, `utf16-32-not-merged`,
`markers-not-merged` or `error` — that is, the file has not caught up since the migration.
Otherwise the file uses its recorded `baseVersion` normally. A file using a legacy baseline needs
no version extraction (Step 2, item 5). Never write to the legacy folder.

Resolve the **target version**: `--version` if given, otherwise the content of
`<source>/VERSION` (trimmed). Compare versions ignoring a leading `v` (Shared Conventions,
**Version strings**). If the target equals the recorded `toolkitVersion`, say so and ask whether
to continue as a re-check (Tier 1 files are re-checked and re-overwritten; a Tier 2 file whose
`baseVersion` already equals the target comes out `unchanged`, while any file still at an older
`baseVersion` — one that stayed behind last time — is merged forward, i.e. retried); stop if the
user declines. If the target looks older than the recorded `toolkitVersion` **or than any Tier 2
file's `baseVersion`**, warn that this is a downgrade (for such a file `BASE` would be newer than
`THEIRS`, so the merge would revert upstream changes) and continue only on explicit
confirmation. Files that stayed behind last run keep their older `baseVersion`; if the user is
re-running the same target, tell them this is a retry of those files.

### Step 2 — Obtain the target and each tracked base version's content without touching `<source>`'s working tree

Define **`<target>`** as a directory laid out exactly like a toolkit repo root (`manifest.json`,
`VERSION`, `core/`, `generators/`, `stacks/`, `data-dictionary-tooling/`). All later steps and the
3-Way Merge section read the target version only through `<target>`, using the same
`<target>/<entry>`-then-`<target>/core/<entry>` lookup the Path mapping defines for `<source>`.
Define **`<installed-<version>>`** the same way for each distinct `baseVersion` tracked in the
state file (item 5): `<installed-<version>>` is the source of `BASE` for every Tier 2 file whose
`baseVersion` is `<version>`, read through the same lookup. Never check out, reset, stash or
otherwise modify `<source>`'s working tree or branches.

1. **Optional refresh.** If `<source>` has a remote, run `git -C <source> fetch --tags`. This
   updates only refs and tag objects, never the working tree. If the fetch fails (offline / no
   remote), continue with the tags already present locally and note it in the report.
2. **Resolve the target.** Find the tag for the target version with the **Version strings**
   lookup rule in Shared Conventions (`<version>` as given, then the `v`/non-`v` alternate; the
   toolkit's tags look like `v1.3.0` while its `VERSION` file holds `1.3.0`), using
   `git -C <source> rev-parse --verify --quiet "<candidate>^{commit}"` and the first candidate
   that resolves. Everywhere in update mode, version strings are compared ignoring a leading
   `v` (`v1.3.0` = `1.3.0`).
   - **Resolves** → extract that version to a staging directory outside both repos (use the OS
     temp folder) under a **uniquely-suffixed path**: `<stage>` =
     `<temp>/toolkit-<version>-<yyyyMMddHHmmss>/` (`<version>` here and below with any leading
     `v` stripped) using the current UTC time (if the time is not
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
   - **Does not resolve** → if `<version>` equals `<source>/VERSION` (ignoring a leading `v`; the target is simply what
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
   `<target>/core/` (destination = `core/`-stripped path with a trailing `.template` removed).
   Generators under `<target>/generators/`, stack overlays under `<target>/stacks/` and
   data-dictionary tooling under `<target>/data-dictionary-tooling/` are **not** part of the
   target file set: they are source-only and never installed into the project. Each file's
   tier comes from the
   manifest; a file in the set that the manifest does not list is **unclassified** (report it under
   "Files not classified in manifest.json", exactly as Install does, and do not modify it).
5. **Obtain `<installed-<version>>` for every distinct tracked `baseVersion` (the source of every
   `BASE`).** Different Tier 2 files can have different `baseVersion`s (Shared Conventions), so
   this step is per **distinct version**, not a single extraction. It happens now, before any
   file in this project is written.
   1. **Collect.** Read the `baseVersion` of every Tier 2 file in the target set from the state
      file (for the legacy migration run, from the in-memory prior entries built in Step 1).
      Leave out files that need no version extraction: a file with no prior entry or a `null`
      `baseVersion` (it has no `BASE`; 3-Way Merge Step 2 handles it as `NO MERGE BASE`), a file
      whose project file does not exist (`not present`; nothing is merged), and a file whose
      `BASE` is a legacy baseline file under Step 1's **Legacy baseline rule**. Strip a leading
      `v` and take the **distinct set** of what remains.
   2. **Extract each distinct version once**, and reuse that one extraction for every file that
      shares the `baseVersion` (never re-extract per file). For each `<version>` in the set:
      - **Same as the target version** (ignoring a leading `v` on either side):
        `<installed-<version>>` = `<target>`; no second extraction.
      - **Otherwise, resolve the tag** with item 2's tag-candidate rule (the same `v`/non-`v`
        lookup; the recorded value is normally the bare form `1.3.0`, so the `v1.3.0` tag is found
        by the alternate candidate). **Resolves** → extract it with the same procedure as item 2 to
        a separately named staging directory `<stage-installed-<version>>` =
        `<temp>/toolkit-installed-<version>-<yyyyMMddHHmmss>/` (leading `v` stripped from the
        version in the name; same uniqueness rules and the same "never reuse, empty or delete a
        pre-existing directory"; same tar-via-file, never-a-pipe requirement):
        `git -C <source> archive --format=tar -o <stage-installed-<version>>.tar <candidate>` then
        `tar -xf <stage-installed-<version>>.tar -C <stage-installed-<version>>`.
        `<installed-<version>>` = `<stage-installed-<version>>`.
      - **Verify** each extraction, but only for what `BASE` lookups need: it must contain
        `core/` and `VERSION` (unlike item 3's check for the target, do **not** require
        `manifest.json`, `generators/`, `stacks/` or `data-dictionary-tooling/` here: an older tag
        legitimately lacks directories that did not exist yet at that version, and such a tag is
        still usable). A `VERSION` mismatch
        (ignoring a leading `v`) is a warning plus item 3's "continue?" question; declining, or an
        extraction that fails or is not usable, is treated exactly like a tag that does not
        resolve.
      - **Does not resolve** → `<installed-<version>>` = *none*. **Do NOT fall back to
        `<source>`'s working tree** as a stand-in, even if it happens to look close: the
        `<source>` shortcut in item 2 is valid for `<target>` only because the requested target
        *is* what `<source>` has checked out, whereas for an **older, historical** version the
        working tree may have moved on and would silently yield a wrong `BASE`. Instead, every
        Tier 2 file whose `baseVersion` is this version is treated individually as
        `NO MERGE BASE — NEEDS MANUAL RESOLUTION` for this run (3-Way Merge Step 2, "`BASE` does
        not exist" row: reached here because that file's tracked `baseVersion`'s tag no longer
        exists in `<source>`, rather than because the file is absent from an existing version).
        Record the missing version in the warnings with the output of
        `git -C <source> tag --list`, and tell the user the fix (fetch tags, unshallow, or point
        `--source` at the right clone) and that re-running then retries those files. This
        **must not block the run**: only the files affected by that specific missing version are
        affected; every other file merges normally.
   3. `<installed-<version>>/manifest.json` is not otherwise used: `BASE` is found by the
      `<installed-<version>>/<entry>`-then-`<installed-<version>>/core/<entry>` lookup, and the set
      of files to process comes from the **target** manifest.

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
- **Legacy `data-dictionary-tooling/` copies.** Toolkit versions before data-dictionary tooling
  became source-only copied `data-dictionary-tooling/export-*.sqlserver.sql` into the project; the
  target manifest lists those paths in `deprecated`, so they are handled by the rules above
  (explicit per-file confirmation). If the project's `data-dictionary-tooling/` folder is left
  empty after confirmed deletions, tell the user it can be removed; remove it only on their
  explicit confirmation.
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

Also state the target version, the recorded `toolkitVersion`, the resolved `<target>` path and,
for every distinct tracked `baseVersion`, its `<installed-<version>>` path (each: a staging
extraction, or `<target>` itself, or *none* where the tag did not resolve, naming the Tier 2
files that therefore have no merge base), and any warnings raised so far (fetch skipped,
downgrade/same-version confirmations, missing base-version tags, unclassified files, pending
placeholders).

**Hand-off values for the 3-Way Merge section** — keep these in working memory for it; they are
inputs it consumes, not state to persist:

- the resolved target version and `<target>` path; the per-file `baseVersion` read from the state
  file (or built by the legacy migration); the map from each distinct `baseVersion` to its
  `<installed-<version>>` path (or *none*); and for the target and each of those extractions,
  whether it is a staging directory (`<stage>` / `<stage-installed-<version>>`) that the merge
  section must remove at the very end — staging directories only; never `<source>`;
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

- `BASE` = `<installed-<baseVersion>>/core/<manifest-path>` — the template as it was at **this
  file's own** tracked `baseVersion` (the version the file is considered caught up to; placeholders
  unfilled, `.template` suffix kept), found with the usual
  `<installed-<baseVersion>>/<manifest-path>`-then-`<installed-<baseVersion>>/core/<manifest-path>`
  lookup. `<installed-<baseVersion>>` is the extraction Update Mode Step 2, item 5 built for that
  distinct version (or `<target>` when `baseVersion` equals the target version); `baseVersion` is
  the value in `.ai/.toolkit-sync-state.json` as it was **before** this run updates it. `BASE`
  does not exist when the file has no prior entry or a `null` `baseVersion`, when its
  `<installed-<baseVersion>>` is *none* (that version's tag no longer resolves in `<source>`), or
  when the file is absent from `<installed-<baseVersion>>`. **Exception — Legacy baseline rule**
  (Update Mode Step 1): when it applies to a file, `.ai/.toolkit-sync-state/baseline/<manifest-path>`
  is `BASE` instead (it is the file's true common ancestor); wherever this section says
  "`<installed-<baseVersion>>/core/<manifest-path>`" for `BASE`, use that file for such entries.
- `THEIRS` = `<target>/core/<manifest-path>` — the new template.
- `MINE` = this project's current, possibly customized `<project-path>`, where `<project-path>` is
  `<manifest-path>` with a trailing `.template` stripped (Shared Conventions, Path mapping).

Note that `MINE` has its placeholders filled in while `BASE`/`THEIRS` do not. The merge handles
this naturally: a filled-in line counts as a change on the `MINE` side, and only conflicts if
`THEIRS` also changed that same region.

### Step 1 — Build the work list and a scratch folder

1. Take the Tier 2 file list from `<target>/manifest.json` (read it again; do not rely on the
   in-memory hand-off list). This is the **target Tier 2 set**. A Tier 2 file that is only a
   `deprecated` match is not in the set and is not merged. Confirm each `<installed-<version>>`
   (resolved in Update Mode Step 2, item 5, before anything was written) is available as handed
   off; do not resolve tags again here. For a file whose `<installed-<baseVersion>>` is *none* (or
   that has no `baseVersion`), no `BASE` copy is made and it classifies as `NO MERGE BASE` in
   Step 2.
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

   - `<work>/base/<manifest-path>` — LF copy of this file's `BASE`, i.e. the file taken from the
     `<installed-<baseVersion>>` of **that file's own** `baseVersion`, or the legacy baseline file
     where the Legacy baseline rule applies, exactly as the `BASE` definition says (each file has
     exactly one `BASE`; files that share a `baseVersion` share one extraction but each gets its
     own scratch copy). Skipped when `BASE` does not exist.
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
   `<target>`/`<installed-<version>>` files are never modified. If making any scratch copy or
   normalizing any file fails (unreadable file, I/O error, bad path), that file is classified
   `error` in Step 2 (catch-all rule below the table); it does not stop the run for other files.

### Step 2 — Classify each file before merging

For every entry in the target Tier 2 set, decide its case, first match wins. Record the outcome
and how its sync-state entry is written (see Step 6). The "State entry" column applies the
**Per-file `baseVersion` advancement** table from Shared Conventions: **advances** = `baseVersion`
becomes the target version and `lastUpdatedAt` becomes the time of this run; **stays** =
`baseVersion` and `lastUpdatedAt` keep the values from the prior state (the state file read at
the start of this run, or the `migrated` entries built from the legacy layout; for a file with no
prior entry, `baseVersion` = `null` and `lastUpdatedAt` = now). `lastMergeResult` is always set to
the value shown. A "stays" outcome means the file's diff from its `baseVersion` to the target was
**never delivered** into the file, so its `lastUpdatedAt` stays stale and visibly shows the file
has not synced.

| Case | Action | Outcome | State entry |
|---|---|---|---|
| `MINE` does not exist (already flagged as a new/missing Tier 2 file in Update Mode Step 3, or deleted by the user) | Nothing to merge. | `not present in project` | advances: `not-present` |
| `MINE`, `BASE` or `THEIRS` is UTF-16/UTF-32 (starts with a `FF FE` / `FE FF` / `00 00 FE FF` BOM; see Step 1 item 3) | Byte-level newline handling is not valid for these encodings. Leave `MINE` untouched. | `NEEDS MANUAL RESOLUTION (UTF-16/32 file, not merged)` | stays: `utf16-32-not-merged` |
| `BASE` does not exist: the file has no prior state entry or a `null` `baseVersion`; **or** its tracked `baseVersion`'s tag does not resolve in `<source>` (`<installed-<baseVersion>>` is *none*, Update Mode Step 2 item 5 — this affects only the files at that version, never the whole run); **or** the file does not exist in `<installed-<baseVersion>>` at all (for example a Tier 2 file added to the toolkit after that version) | No common ancestor, so no 3-way merge is possible. If the normalized `MINE` is identical to the normalized `THEIRS` after the install placeholder substitutions, outcome `unchanged`. Otherwise copy `THEIRS` next to the project file as `<project-path>.toolkit-new` (overwriting an earlier `.toolkit-new`) and do not touch `MINE`. **Upstream changes in `.toolkit-new` are NOT in `MINE`** — see the risk note below the table. | `unchanged`, or `NO MERGE BASE — NEEDS MANUAL RESOLUTION (compare manually)` | `unchanged`: advances. Otherwise stays: `no-merge-base` |
| `MINE` still contains an unresolved conflict-marker block from an **earlier** sync (the full triple, in order — see **Marker guard** below), **unless** the prior state entry's `lastMergeResult` is `manually-reconciled` (the user declared the file reconciled via `--mark-reconciled`, so the guard is skipped for this run and the file falls through to the rows below) | Do not merge on top of markers. Leave `MINE` untouched. | `NEEDS MANUAL RESOLUTION (markers from a previous sync, not merged)` | stays: `markers-not-merged` |
| Normalized `BASE` and normalized `THEIRS` are identical | The toolkit did not change this file (any raw difference was line endings only). Leave `MINE` untouched. | `unchanged` | advances: `unchanged` |
| otherwise | Merge (Step 3). | decided in Step 4 | per Step 4: `unchanged` / `clean-merged` advance; a **fresh** `conflict (<n>)` advances (the markers are the delivered diff); `error` stays |

**Catch-all: any failure is `error`.** If, for a file, *any* step fails — making a scratch copy,
LF normalization, the marker-guard scan, running `git merge-file` (an exit outside `0`–`127`, or
the command not running at all), restoring line endings, or writing the result back to
`<project-path>` — not only a `git merge-file` exit outside `0`–`127`, classify that file as
`error` (**stays**), whatever row above it would otherwise have matched, report the failing step
and message, and continue with the remaining files. If the failure happened while writing back to
`<project-path>`, tell the user to verify `<project-path>` (for example with `git diff`) before
relying on it, since a partial write cannot be ruled out.

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

**Recovery from a marker-guard flag** (the guard only inspects `MINE`; it never edits files). The
file was **not** merged this run, so its `baseVersion` **stayed** where it was — it is not a
conflict you have lost, and nothing is re-diffed until you act:

1. *Real, leftover markers (the usual case):* resolve them in the file (keep the right side,
   delete the marker lines). The upstream hunks that were in the markers are then part of your
   file, so nothing is lost. No further command is required: the next `/sync-toolkit` merges the
   file normally against the `baseVersion` recorded for it in `.ai/.toolkit-sync-state.json`
   (which stays at its recorded value), so it also picks up everything released since.
2. *False positive (example text that happens to hold the full triple):* the same guard will fire
   again on every run unless you act. Reconcile the file by hand: compare `<project-path>` with the
   toolkit's new template (`core/<manifest-path>` in `<source>` at the target version's tag;
   placeholders unfilled, `.template` suffix kept) and apply the toolkit's changes yourself, then
   record it with `/sync-toolkit --source <path> --mark-reconciled <manifest-path>`
   (**Mark-Reconciled Mode**), which sets its `baseVersion` to the version you reconciled
   against and makes the next run skip the guard for it. **Limitation:** this skip lasts only
   **one** run (the `manually-reconciled` entry is replaced by that run's outcome). If the
   example text still holds the full triple, the guard fires again on the run after that, and you
   must repeat `--mark-reconciled` (or reword the example so it no longer contains the full
   triple).

To record any file as reconciled by hand, use only that command; never edit
`.ai/.toolkit-sync-state.json` directly.

**Risk of the `NO MERGE BASE` row (do not understate it).** This file **stays** behind: its
`baseVersion` is not advanced, so the next run will again find no `BASE` for it (until the missing
tag is restored, or you reconcile it) and rewrite `<project-path>.toolkit-new`. The upstream
changes saved there are **NOT** in `MINE`, and nothing merges them automatically. The file is
reported as **needs manual resolution**, not as a passive note: the user must manually reconcile
`<project-path>.toolkit-new` into `<project-path>`, delete the `.toolkit-new` file, and then run
`/sync-toolkit --source <path> --mark-reconciled <manifest-path>` — otherwise it keeps coming
back at every update.

**The same holds for every other file that stays behind** (`utf16-32-not-merged`,
`markers-not-merged`, `error`). Because each file's `BASE` is derived from its **own**
`baseVersion`, which this run did not advance, a re-run **does** retry them against their true
common ancestor — none of their upstream changes are lost, and the files that did advance are not
re-diffed. They are reported at the same visibility as a conflict. A file with **fresh** conflict
markers (`conflict (<n>)`) is different: its `baseVersion` *did* advance, because the upstream
hunks are in `MINE` as literal markers for the user to resolve; resolving them is cleanup, and the
marker guard protects the file from being merged again on top of its markers until the user has
done so.

### Step 3 — Run the three-way merge

For each file that reached "otherwise" in Step 2, using only the LF-normalized copies from Step 1
item 3 (the **normalize → compare → merge → restore** sequence; Step 4 does the restore):

1. Copy the normalized `MINE` (`<work>/mine/<project-path>`) to `<work>/merge/<project-path>`
   (create folders as needed). The merge runs on this `merge` copy so the normalized `MINE` stays
   intact for Step 4's comparison; the original `MINE` is not touched here. Do not merge the raw files.
2. Run, with your own `run_in_terminal` call, a merge **in place on the `merge` copy** (no output
   redirection and no pipe — PowerShell pipes can alter line endings and encodings):
   ```powershell
   git merge-file -L "project (current)" -L "installed toolkit <file's baseVersion>" -L "toolkit <target version>" "<work>/merge/<project-path>" "<work>/base/<manifest-path>" "<work>/theirs/<manifest-path>"
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
  State entry: **advances** (`clean-merged` / `unchanged`).
- **Exit `1`–`127` (conflicts):** copy the restored output, **with its conflict markers**, over
  `<project-path>` and record `NEEDS MANUAL RESOLUTION (<n> conflict(s))`. **Never resolve a
  conflict by silently picking one side, and never drop the markers.** Clean hunks in the same
  file are already merged by `git merge-file`; only genuine conflicts carry markers. State entry:
  **advances**, `lastMergeResult` = `conflict (<n>)`: this is a **fresh** conflict, and the diff
  from the file's old `baseVersion` to the target *was* delivered into the file as literal
  markers, so the file's `baseVersion` becomes the target version and `lastUpdatedAt` is now.
  Resolving the markers is cleanup, not re-diffing: however the user resolves them (taking the
  toolkit's side, keeping their own, or anything in between), the next run merges forward from the
  target and does not re-offer these hunks. The marker guard in Step 2 protects the file from being
  merged again on top of its markers until the user has resolved them (in that interim the file
  reports `markers-not-merged` and its `baseVersion` stays at its recorded value, which is the
  target).
  **Discard / revert caveat:** if the user instead discards or reverts a Tier 2 file to an
  **older** state outside this tool (for example `git checkout` of an earlier commit), its tracked
  `baseVersion` still names the newer version, so the next merge treats the file as already caught
  up and silently skips hunks the reverted content never received. Fix: run
  `/sync-toolkit --source <path> --mark-reconciled <manifest-path>` giving the **older** version
  the file's content actually matches, to rewind its tracked `baseVersion` (Mark-Reconciled Mode
  warns about moving a base backwards; confirm it).
- **Error** (per the catch-all rule under Step 2's table: a `git merge-file` exit outside
  `0`–`127`, or a failure in any scratch-copy, normalization, restore or write-back step): leave
  `<project-path>` untouched where it is still untouched, and record `ERROR — not merged (<reason>)`.
  State entry: **stays**, `lastMergeResult` = `error`. Continue with the remaining files and list
  it in the summary so the user can reconcile it by hand (a re-run retries it from the same
  `baseVersion` — see Step 6).

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
always means the update run completed. If the run was aborted or a failure stopped it before this
point, do **not** write it — the file is unchanged and a re-run repeats the update. The state file
is tool-owned bookkeeping, so rewriting it needs no user confirmation.

1. **Read the prior state.** Re-read `.ai/.toolkit-sync-state.json` from disk (it is unchanged
   since Update Mode Step 1 because only this step writes it). If the project came from the
   legacy layout, the prior state is the in-memory migration from Update Mode Step 1 (`stack`
   from `version.json`; a `migrated` entry, with `baseVersion` = `<legacy-version>`, for each file
   that had a legacy baseline).
2. **Build the new content.** Every file's own entry records exactly where that file stands, and
   the top-level fields are always written, whatever the per-file outcomes.
   - `toolkitVersion` = the target version in bare form (`<target>/VERSION`, trimmed, or the
     `--version` value with a leading `v` stripped), written **unconditionally** — it only
     records the last version this project attempted to sync to.
   - `stack` unchanged from the prior state.
   - `syncedAt` = the current ISO 8601 UTC time (ask the user if you cannot determine it).
   - `files` = exactly one entry per path in the **target Tier 2 set**, each built from that
     file's Step 2 / Step 4 outcome by the **Per-file `baseVersion` advancement** table in Shared
     Conventions (the "State entry" column):
     - **advances** (`unchanged`, `clean-merged`, `not-present`, and a fresh `conflict (<n>)`) →
       `baseVersion` = the target version (bare), `lastUpdatedAt` = now, `lastMergeResult` = the
       outcome's value;
     - **stays** (`markers-not-merged`, `no-merge-base`, `utf16-32-not-merged`, `error`) →
       `baseVersion` and `lastUpdatedAt` keep their prior values (including a `migrated` entry's
       values); for a file with no prior entry, `baseVersion` = `null` and `lastUpdatedAt` = now;
       `lastMergeResult` = the outcome's value. A "stays" file's `lastUpdatedAt` is **never**
       bumped.
     Entries in the prior `files` map whose path is not in the target Tier 2 set (dropped or
     deprecated files) are simply not carried over; a Tier 2 path new to the target set gets a
     fresh entry by the same rules. Nothing else is persisted: no template content. (A prior
     `manually-reconciled` entry is simply replaced by this run's outcome for that file.)
3. **Write atomically** with the procedure in Shared Conventions: write the content to
   `.ai/.toolkit-sync-state.json.tmp`, re-read and verify it (no BOM, valid JSON, `toolkitVersion`
   = the target version, `files` keys equal the target Tier 2 set exactly, every entry has a
   `baseVersion`), then
   `Move-Item -LiteralPath '.ai/.toolkit-sync-state.json.tmp' -Destination '.ai/.toolkit-sync-state.json' -Force`.
   If verification fails, delete the `.tmp` file, leave the real file untouched, and report the
   difference.
4. **Legacy folder.** If the old `.ai/.toolkit-sync-state/` folder (`version.json` + `baseline/`)
   exists, it is no longer the primary state, but its `baseline/` files still serve as `BASE` for
   any file that has not caught up since the migration (Update Mode Step 1, **Legacy baseline
   rule**). So **do not offer to delete it until every migrated file's `baseVersion` has advanced
   past `<legacy-version>` at least once** — that is, until, in the state just written, no file
   that had a legacy baseline file still has `baseVersion` equal to `<legacy-version>` with a
   `lastMergeResult` of `migrated`, `no-merge-base`, `utf16-32-not-merged`, `markers-not-merged`
   or `error`. While any such file remains, leave the folder alone and list those files as the
   reason in the summary. Once none remain, tell the user the folder is obsolete and may be
   removed (`Remove-Item -LiteralPath '.ai/.toolkit-sync-state' -Recurse -Force`) **only on their
   explicit confirmation**; otherwise leave it and mention it in the summary.

### Step 7 — Clean up this run's temporary files

Remove, and only these: `<work>` (Step 1), and — for each staging copy Update Mode Step 2
extracted — `<stage>` and `<stage>.tar` (the target) and, **for every distinct
`<stage-installed-<version>>` this run extracted**, that directory and its
`<stage-installed-<version>>.tar`
(`Remove-Item -LiteralPath <path> -Recurse -Force`). Paths are the exact ones this run created;
never glob `toolkit-*` and never remove other leftovers (just mention them). When a
`<installed-<version>>` = `<target>`, or either is `<source>`, there is no separate staging copy
for it. **Never remove `<source>`**, including when `<target>` = `<source>`. A cleanup failure is
not an update failure: report the path so the user can delete it. If the run aborts after staging
was created, remove this run's `<work>`/`<stage>`/`<stage>.tar` and every
`<stage-installed-<version>>`/`.tar` before stopping.

### Step 8 — Final summary, then stop

Print one report that combines the Update Mode Step 7 interim summary (missing/added, deprecated,
unrecognized, Tier 1 overwritten, warnings) with:

- Target version and the previously recorded `toolkitVersion`.
- **Per-file sync status** — state this explicitly, as the first item after the versions:
  - Files whose `baseVersion` **advanced** to the target (`unchanged`, `clean-merged`, fresh
    conflicts, not present): list them with their outcomes (a count is enough for `unchanged`).
  - Files whose diff was **not delivered this run** (they keep their recorded `baseVersion`,
    which may be older than <target> or, for a file still holding markers from an earlier run,
    may already equal it): a prominent banner naming **every** such file, its outcome, and the
    `baseVersion` it stays at, e.g. "**These files were NOT merged this run; each keeps its
    recorded `baseVersion` and will be retried on the next run:** `<path>` — `no-merge-base`
    (stays at <baseVersion>), …". The list must name every such file; do not summarize it as a
    count. (`toolkitVersion` itself is informational and was
    set to <target> regardless.)
- Every Tier 2 file with its outcome: `unchanged` / `clean-merged` / `NEEDS MANUAL RESOLUTION`
  (with conflict count, or the reason) / `NO MERGE BASE — NEEDS MANUAL RESOLUTION (compare manually)` (with the
  `.toolkit-new` path, or the missing `baseVersion` tag) / `not present in project` / `ERROR — not merged`.
- A prominent **"Needs manual resolution"** list. It must contain, at the same visibility: (a) files
  with **fresh** conflict markers written this run (search for `<<<<<<<` to resolve; their
  `baseVersion` advanced, so resolving the markers by hand is all that is needed — no extra
  command), (b) files skipped by the marker guard because of markers from an **earlier** run
  (with the matched line numbers and the Recovery steps from Step 2; their diff was not delivered), (c) any
  file not merged (`ERROR`, or skipped as UTF-16/32; their diff was not delivered), and (d) **every
  `<project-path>.toolkit-new` file created this run** (and every file left as `NO MERGE BASE`
  because a `baseVersion` tag was missing), each with this warning: *the upstream changes in this
  file are NOT in your project file; reconcile `.toolkit-new` into the project file, delete it,
  then run `/sync-toolkit --source <path> --mark-reconciled <manifest-path>` — until then the file
  stays behind and comes back at every update.* Say which items were not delivered (b–d) and that a
  re-run retries them (it does not lose their upstream changes). Give the instruction to
  resolve/review each item and review the diff.
- Sync state: `.ai/.toolkit-sync-state.json` written (its `toolkitVersion`, count of `files`
  entries, and any entries whose `lastMergeResult` is not `unchanged` / `clean-merged`, each with
  its `baseVersion`), plus whether a legacy `.ai/.toolkit-sync-state/` folder was found and what
  happened to it (kept because files still depend on its baselines, offered for removal, or
  removed). Remind the user: if they ever discard or revert a Tier 2 file to an **older** state
  outside this tool (for example `git checkout` of an earlier commit), the file's tracked
  `baseVersion` still names the newer version and a later update would silently skip the hunks
  the reverted content never received; run
  `/sync-toolkit --source <path> --mark-reconciled <manifest-path>` with the **older** version to
  rewind it.
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
3. If `<source>/VERSION` (trimmed) differs from the recorded `toolkitVersion` in the sync state
   (compared ignoring a leading `v`; the recorded value is only the last version a run attempted
   to sync to),
   warn the user that the generator comes from a different toolkit version than the one last
   synced (suggest running update mode first) and continue only on their confirmation. This is a
   warning only; this mode never changes the recorded versions.
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
map (every `baseVersion` included) stay exactly as they were. Re-running one generator is not a toolkit
version change, and the files it produces are project-owned (Tier 3) or placeholder fills inside
Tier 2 files that the next update merges normally.

### Step 4 — Report and stop

Do **not** run `git add`, `git commit` or `git push`. Report: the generator that ran, every file it
created or changed (and any it skipped or left unchanged), anything it left pending or could not
do, and a closing instruction to review the changes and commit them in this repo yourself — this
command made no commits.

<!-- ============================================================================
     SECTION: MARK-RECONCILED MODE  (`--mark-reconciled <manifest-path>`)
     ============================================================================ -->

## Mark-Reconciled Mode (`--mark-reconciled <manifest-path>`)

Records that **one** Tier 2 file has been reconciled by hand against a chosen toolkit version, so
the next update merges it forward from that version instead of re-flagging it. This is the only
sanctioned way to change a single file's state entry outside an update run; the sync-state file
must never be edited directly. Typical uses: after reconciling a `<project-path>.toolkit-new`
copy into the project file (`NO MERGE BASE`), after hand-merging a UTF-16/32 file, or after
deciding that example text in a file that trips the marker guard is not a real conflict.

Use the **Sync state** definition, the **Per-file `baseVersion` advancement** table and the
**Atomic write** procedure from Shared Conventions unchanged. `<manifest-path>` is the manifest
key (for example `AGENTS.md.template`), and `<project-path>` is that path with a trailing
`.template` stripped.

### Step 1 — Preconditions

1. `.ai/.toolkit-sync-state.json` must exist and parse (same precondition as Generator Mode,
   except that the legacy `.ai/.toolkit-sync-state/version.json` layout does **not** count here:
   its files are not tracked entries yet). If it is missing, stop: if only the legacy folder
   exists, tell the user to run an update (`/sync-toolkit --source <path>`), which migrates it;
   if neither exists, the project is not installed, so run install mode first. Change nothing.
2. `<manifest-path>` must be an **existing key** in the state file's `files` map (a tracked Tier 2
   entry). If it is not, stop and report that, listing the tracked keys; do not guess a close
   match, do not create an entry, and remind the user that keys keep their `.template` suffix.
   Also require that `<project-path>` exists in this project; if it does not, stop and report
   (there is nothing to have reconciled).

### Step 2 — Confirm the version

Ask the user: "Confirm you have manually reconciled `<project-path>` — against which target
version? (Defaults to `<source>/VERSION`, currently `<value>`, if not given.)" Wait for the
answer; do not guess silently, and use the default only if the user accepts it. Strip a leading
`v` and store the bare form. Then check the answer:

- It should be a version the toolkit clone knows: it resolves by the **Version strings** lookup in
  `<source>`, or equals `<source>/VERSION`. If not, warn that the next update will find no merge
  base for this file (its tag is missing from `<source>`) and ask whether to proceed anyway.
- If it is **older** than the entry's current `baseVersion`, warn that this moves the file's base
  backwards, so already-delivered upstream hunks will be offered again, and ask whether to
  proceed anyway.

### Step 3 — Check the file no longer holds unresolved markers

Confirm, with the exact detection logic of the Tier 2 Three-Way Merge's **Marker guard** (the full
triple, in order, matched on bytes), that `<project-path>` no longer contains an unresolved
conflict-marker block. The guard runs on an LF-normalized copy, so first make one in a uniquely
named scratch folder `<temp>/toolkit-reconcile-<yyyyMMddHHmmss>/` with the CRLF → LF byte snippet
from the Three-Way Merge's Step 1 item 3 (never scan the raw file, whose CRLF line ends would defeat
the exact-`=======` test), run the guard's snippet on that copy, and remove the scratch folder
afterwards (exact path only, never a glob). If the file is UTF-16/32 (starts with a `FF FE` /
`FE FF` / `00 00 FE FF` BOM) the guard cannot be applied: say so and ask the user to confirm it has
really been reconciled. If the guard **fires**, warn the user with the three matched line numbers —
they have likely not finished resolving the file (or it contains example text) — and ask for
**explicit confirmation** to proceed anyway; if they decline, stop with nothing changed. Any
failure while checking (scratch copy, scan) is reported and also requires explicit confirmation to
continue.

### Step 4 — Update that one entry (atomic)

Re-read `.ai/.toolkit-sync-state.json` from disk, then change **only** the entry for
`<manifest-path>`: `baseVersion` = the confirmed version (bare form), `lastMergeResult` =
`"manually-reconciled"`, `lastUpdatedAt` = now (ISO 8601 UTC; ask the user if you cannot
determine it). Do not touch any other file's entry, nor `toolkitVersion`, `stack` or `syncedAt`.
Write it with the **exact same atomic write** as every other state write (build the full content,
write `.ai/.toolkit-sync-state.json.tmp`, verify: no BOM, valid JSON, unchanged `toolkitVersion`,
the `files` key set unchanged, every entry has a `baseVersion`, and every entry other than
`<manifest-path>` equal to the prior one, then `Move-Item … -Force`). If verification fails, delete
the `.tmp` file, leave the real file untouched, stop and report.

### Step 5 — Report and stop

Do **not** run `git add`, `git commit` or `git push`. Report: the file, its previous and new
`baseVersion`, its new `lastMergeResult`, and that no other entry or top-level field changed. If a
`<project-path>.toolkit-new` file still exists, remind the user to delete it (this mode never
deletes it). Remind them that the next `/sync-toolkit` update merges the file forward from the
confirmed version, and to review and commit the state file in this repo themselves — this command
made no commits.

<!-- ============================================================================
     END OF FILE. Install Mode + Update Mode + 3-Way Merge + Generator Mode + Mark-Reconciled Mode together are the complete /sync-toolkit.
     ============================================================================ -->
