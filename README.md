# AI Automation Toolkit

Reusable, versioned GitHub Copilot automation framework — ticket-to-PR workflow, ADA/WCAG
fix workflow, and domain-knowledge generation — distributable to any jurisdiction/vertical
project regardless of language/stack.

## Installing into a new project

1. Clone this repo locally.
2. In the target project's Copilot chat, ask it to copy
   `core/.github/prompts/sync-toolkit.prompt.md` into the target project's own
   `.github/prompts/` folder (this is the only manual step, ever).
3. Reload Copilot Chat in the target project. Run:
   ```
   /sync-toolkit --source "<path-to-this-clone>" --mode install
   ```
4. Review and commit the result in the target project's own repo.

## Updating an existing installation

```
/sync-toolkit --source "<path-to-this-clone>" --version v1.x.x
```

## Repo layout

- `core/` — generic agents, prompts, governance/behavior templates. Tiered per `manifest.json`.
- `generators/` — `create-*.prompt.md` commands that tailor `core/` output to a specific project.
- `stacks/` — per-language-stack deltas layered on top of `core/` during install.
- `data-dictionary-tooling/` — DB export SQL (SQL Server only in v1) + the
  `generators/create-data-dictionary.prompt.md` command that turns exported CSVs into markdown.
- `manifest.json` — the file tier classification + deprecated-file list that drives
  `/sync-toolkit`'s install/update behavior.

Full design rationale: see the AB (Alberta) workspace's
`docs/superpowers/specs/2026-10-15-ai-automation-toolkit-distribution-design.md`.
