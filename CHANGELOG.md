# Changelog

All notable changes to the AI Automation Toolkit are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

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
