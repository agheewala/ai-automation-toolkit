# Changelog

All notable changes to the AI Automation Toolkit are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]
### Changed
- Sync state is now a single file, `.ai/.toolkit-sync-state.json` (`toolkitVersion`, `stack`,
  `syncedAt`, and a per-Tier-2-file `files` map with `lastUpdatedAt` / `lastMergeResult`),
  replacing `.ai/.toolkit-sync-state/version.json` + the `baseline/` copy of every Tier 2 file.
  It is always written atomically (temp file, verify, rename).
- Update Mode no longer reads a persisted baseline: the merge base is fetched on demand from the
  toolkit's git history for the single recorded `toolkitVersion` (`<installed>`, extracted exactly
  like `<target>`). If that version's tag is missing from the toolkit clone the run stops and the
  user chooses between aborting and treating every Tier 2 file as having no merge base.
- The "Baseline reconciliation contract" is removed. Update Mode step numbers are unchanged; in the
  3-Way Merge section old Step 6 (reconcile `baseline/`) and old Step 7 (write `version.json`) are
  replaced by one Step 6 (write the state file), and old Steps 8 and 9 are now Steps 7 and 8.
- Tag lookup tolerates a leading `v` (`VERSION` holds `1.3.0`, tags are `v1.3.0`).
- Projects installed by an older toolkit (legacy `version.json` + `baseline/` folder) are
  recognised on update; the legacy folder is ignored and offered for removal at the end.
- `core/.ai/behavior/decision-rules.md` gains a rule that the ticket workflow and ad-hoc search
  must never read, reference or edit `.ai/.toolkit-sync-state.json`.

## [1.3.0] - 2026-10-16
### Changed
- `stacks/<stack>/` overlay is no longer installed into projects (same treatment as `generators/`);
  `create-build-settings` reads `<source>/stacks/<chosen-stack>/notes.md` from the toolkit clone.
  `stacks/dotnet-mvc/notes.md` leaves manifest Tier 1 and is listed under `deprecated` so older
  installs can clean up their copy on update (with confirmation). Update Mode no longer tracks
  anything under `<target>/stacks/`. No step numbers changed.
- `REQUIRED_MODEL_LIST` question now defaults to the verified `Claude Sonnet 5 (copilot)` /
  `Claude Sonnet 5.5 (copilot)` fallback array, only asking further if the user wants something
  different (first-jurisdiction-pilot feedback: free-text answers were missing the fallback-array
  format and vendor suffix).
### Fixed
- `create-data-dictionary` now reads and displays the full SQL export query content directly in
  chat (not just file paths), so the user never has to go find the files themselves.
- `custom-fixes.md`'s Version table no longer has instructional prose sitting as if it were a
  literal field value ("Created: update this date...") — now a clear, unambiguous placeholder.
- `wcag-fix-patterns.md` restores a pointer to the toolkit source's `stacks/<stack>/notes.md` as a
  manual-reference starting point, lost when the stacks/ install-copy was removed.

## [1.2.0] - 2026-10-16
### Changed
- `generators/` is no longer installed into projects (it confused teams as an unexplained top-level
  folder). Install Mode drops the old Step 7 (copy generators; steps renumbered 7–8), the seven
  `generators/create-*.prompt.md` entries leave manifest Tier 1 and are listed under `deprecated`
  so older installs can clean up their copies on update (with per-file confirmation).
### Added
- `/sync-toolkit --source <path> --generator <name>` standalone mode: re-run one generator, read
  directly from the toolkit clone, on an already-installed project. Does not touch
  `.ai/.toolkit-sync-state/`.

## [1.1.1] - 2026-10-16
### Fixed
- Second-pilot validation pass (fresh Node.js throwaway project) found 4 residual issues missed
  by the v1.1.0 fix batches: a leftover `Html.cLabelFor` reference in `wcag-fix-patterns.md`;
  `{{DB_NAME}}` staying unfilled for Oracle/other-engine and no-database projects; a missing
  "if present" conditional on the data-dictionary consultation mandate in
  `copilot-instructions.md.template`; and a hardcoded `BUG/`/`ER/`/`CR/` branch-prefix scheme in
  `ticket-processor.agent.md` and `copilot-instruction.md` (both Sections 5.2 and 5.3) that
  contradicted each project's own generated `{{BRANCH_PREFIX_TABLE}}`. All fixed and re-verified.

## [1.1.0] - 2026-10-16
### Added
- `core/README.md.template` — every installed project now gets a root `README.md` (previously
  missing entirely; only `AGENTS.md` was installed). Covers quick start, chat-mode guidance,
  folder structure reference, MCP setup, and how to update the toolkit later via `/sync-toolkit`.

### Fixed
- Pilot-driven hardening pass (24 findings from an end-to-end install dry run against a non-.NET
  project), across 4 fix batches:
  - Removed remaining hardcoded .NET/MVC/Oracle-specific content from the master authority files
    (`copilot-instructions.md.template`, `AGENTS.md.template`), `implement.prompt.md`,
    `pr-review.prompt.md`, and both agent files' `applyTo` patterns.
  - Removed AB-domain-specific example data/wording ("supplement", fleet/escrow examples) and
    SQL-Server-specific hardcoding from governance/template docs.
  - **Safety fix:** `SQL_Guidelines.md`'s reversal-script policy no longer fails open (silently
    skipping a required reversal script when project policy is undocumented) — now stops and asks.
  - `create-knowledge-base.prompt.md` now optionally collects SQL audit-stamp/reversal-policy
    fields during generation.
  - Resolved an orphaned token, hardcoded model names bypassing `{{REQUIRED_MODEL_LIST}}`,
    hardcoded branch/SCM-platform assumptions (new `{{BASE_BRANCHES}}`/`{{SCM_PLATFORM}}` tokens),
    inconsistent push-keyword wording, and dangling section references.
  - `{{REPO_REMOTE_NAME}}` renamed to `{{REPO_REMOTE_URL}}` for clarity (it always holds a full URL).
  - Removed internal project-planning references that had leaked into shipped generator/prompt
    text; added self-exclusion rules so `/sync-toolkit` never rewrites its own documentation or
    the generators' own text; scoped the pending-token scan to this toolkit's own token convention.
  - Added `.gitignore` entry for `.superpowers/` (local SDD ledger, never a package deliverable).

## [1.0.0] - 2026-10-15
### Added
- Full toolkit v1: `core/` templates (`AGENTS.md`, `copilot-instructions.md`, ticket-processor and
  domain-engineer agents, auto-fix/fix-ticket/implement/pr-review prompts, `patterns/SKILL.md`,
  behavior/governance/templates docs).
- 7 generators: create-knowledge-base, create-coding-standards, create-build-settings,
  create-scm-workflow, create-implementation-patterns, create-domain-agent, and
  create-data-dictionary.
- `sync-toolkit.prompt.md` with install mode, update mode (missing/deprecated/unrecognized file
  detection, Tier 1 blind overwrite), and Tier 2 three-way merge with conflict markers.
- SQL Server data-dictionary export queries (schema catalog + stored procedures) and the
  create-data-dictionary generator. Oracle export support is explicitly deferred to a future
  release — not included in this toolkit version.
- `stacks/dotnet-mvc` overlay (notes.md).
