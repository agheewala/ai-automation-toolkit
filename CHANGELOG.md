# Changelog

All notable changes to the AI Automation Toolkit are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

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
