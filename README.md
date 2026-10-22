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

## Re-running a single generator

Generators are never copied into a project; they are read from this clone. To re-run one later on an
already-installed project (for example after a schema change):

```
/sync-toolkit --source "<path-to-this-clone>" --generator create-data-dictionary
```

## Recording a hand-reconciled file

If an update leaves merge-conflict markers in a Tier 2 file and you resolve them by hand, record
it so the next update doesn't re-flag the same conflict:

```
/sync-toolkit --source "<path-to-this-clone>" --mark-reconciled <manifest-path>
```

`<manifest-path>` is the Tier 2 key from `.ai/.toolkit-sync-state.json` (e.g. `AGENTS.md.template`,
`.template` suffix kept). Never edit that state file by hand — this is the only sanctioned way to
change one file's recorded state outside a normal install/update run.

## Using this from GitHub Copilot CLI

`/sync-toolkit` is a `.github/prompts/*.prompt.md` slash command, which GitHub Copilot CLI does
not discover at all (VS Code-only). Every mode above (install, update, `--generator`,
`--mark-reconciled`) is also available in the CLI through the **Sync Toolkit** agent
(`core/.github/agents/sync-toolkit.agent.md`), which reads and executes the same
`sync-toolkit.prompt.md` instructions verbatim:

```
/agent
# then choose "Sync Toolkit" from the list

# or, non-interactively:
copilot --agent="Sync Toolkit" --prompt "--source <path-to-this-clone> --version v2.0.0"
```

The very first install of a brand-new project still has to happen from VS Code: nothing is
discoverable by either surface until the one manual bootstrap step above has copied
`sync-toolkit.prompt.md` in and install mode has run once. That first run copies
`sync-toolkit.agent.md` in alongside it automatically (both are plain Tier 1 `core/` files), so
every later update/generator/mark-reconciled run on that project can use either the VS Code slash
command or the CLI agent, interchangeably.

## Repo layout

- `core/` — generic agents, prompts, governance/behavior templates. Tiered per `manifest.json`.
- `generators/` — `create-*.prompt.md` commands that tailor `core/` output to a specific project
  (source-only: read from this clone during install and `--generator` re-runs, never installed).
- `stacks/` — per-language-stack hints (`notes.md`) consulted during generation
  (source-only: read from this clone, never installed).
- `data-dictionary-tooling/` — DB export SQL (SQL Server only in v1) + the
  `generators/create-data-dictionary.prompt.md` command that turns exported CSVs into markdown.
- `manifest.json` — the file tier classification + deprecated-file list that drives
  `/sync-toolkit`'s install/update behavior.
