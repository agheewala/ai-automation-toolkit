---
description: >
  Setup generator (run after create-knowledge-base.prompt.md and create-coding-standards.prompt.md).
  Detects the target project's build tool, solution/project file inventory, and module build
  order, and produces .ai/behavior/setting.md plus the matching build-command references in every
  other file that documents how to build this project.
---

# Create Build Settings

You will be invoked once, at integration time, to generate `.ai/behavior/setting.md` for a new
project and to propagate the same build-command facts into every other file in this automation
package that references them. Build settings are consumed on every ticket, so an incorrect or
stale build command here breaks the whole automated workflow.

> **Prerequisite**: `create-knowledge-base.prompt.md` and `create-coding-standards.prompt.md` must
> already have run. Reuse the stack and `CODE_ROOT` recorded in `.ai/knowledge-base.md` — do not
> re-ask the user for `CODE_ROOT`.

> **Self-deleting prompt.** After this file successfully writes `.ai/behavior/setting.md` and
> propagates the build commands to every file listed below, delete this file from the target
> project's `.github/prompts/` folder (see **Step 7** below). Do not keep it around — a stale
> generator invites someone to re-run it later and overwrite settings that have since drifted from
> (and now correctly reflect) real build changes made through normal ticket work.

---

## Your Job

1. Read `.ai/knowledge-base.md` to confirm `CODE_ROOT` and the already-detected build/test tooling
   (Section 15, Technology Stack). If `.ai/knowledge-base.md` does not exist yet, stop and tell the
   user to run `create-knowledge-base.prompt.md` first.
2. Detect the build tool, solution/project file inventory, and module boundaries from `CODE_ROOT`
   (see **Auto-Detection Instructions**).
3. Write `.ai/behavior/setting.md`, filling `{{BUILD_SCOPE_RULES}}`, `{{RISK_THRESHOLDS}}`, and
   `{{STACK_CHECKLIST}}` per the guidance already present in that file's own scaffold comments
   (read the existing `.ai/behavior/setting.md` scaffold shipped by this package before writing —
   it documents exactly what each placeholder must contain).
4. Propagate the resulting build commands (`{{BUILD_COMMAND_FULL}}`, `{{BUILD_COMMAND_MODULE}}`)
   and the solution/project file list (`{{SOLUTION_FILES}}`) into every other file that references
   them (see **Files You Must Touch** — this is the authoritative, verified list; do not rely on
   assumption or touch only `setting.md`).
5. Also fill `{{RISK_THRESHOLDS}}` in `.ai/behavior/decision-rules.md` (STOP Condition #8) with the
   same scope threshold used in `setting.md`, so the two files stay consistent.
6. Report to the user: detected build tool, solution/project file list, build dependency order (if
   any), and which files were updated.
7. Delete this generator prompt file from the project's `.github/prompts/` folder.

---

## Auto-Detection Instructions

Do not assume any single build tool. Inspect `CODE_ROOT` for:

| Found in `CODE_ROOT` | Build tool / commands to detect |
|---|---|
| `*.sln` + `*.csproj`/`*.fsproj` (legacy, pre-SDK-style project files) | MSBuild — invoked as `msbuild <solution>.sln /p:Configuration=<config> /p:Platform=<platform>`. Check the `.csproj` for `<TargetFrameworkVersion>`; old-style ASP.NET/WebForms projects targeting .NET Framework typically require MSBuild, not the `dotnet` CLI. |
| `*.sln` + SDK-style `*.csproj` (`<Project Sdk="Microsoft.NET.Sdk">`) | `dotnet build <solution>.sln` (modern .NET, cross-platform CLI works) |
| `pom.xml` | Maven — `mvn clean install` (or module-specific `mvn -pl <module> install`) |
| `build.gradle` / `build.gradle.kts` | Gradle — `./gradlew build` (or `./gradlew :<module>:build`) |
| `package.json` with workspaces/monorepo config | npm/yarn/pnpm — check `scripts.build`, and check for a monorepo tool (Nx, Turborepo, Lerna) that defines per-package build scoping |
| `package.json` (single package) | npm/yarn/pnpm — check `scripts.build` |
| `pyproject.toml` / `setup.py` | Python — check for a build/test task runner (e.g. `tox`, `nox`, or a documented `make` target); Python projects often have no compiled "build" step — if so, say so and treat linting/type-checking/test commands as the equivalent gate |
| `go.mod` | Go — `go build ./...` (or `go build ./<module>/...` for a single module) |
| `Gemfile` | Ruby — check `Rakefile` for a build/compile task |
| `Makefile` at `CODE_ROOT` | A custom build orchestration script may already exist — prefer it over inventing a raw tool invocation if it exists and is documented |

For each stack signal found, also detect:
- **Solution/project/module file inventory** — the actual list of solution files, top-level
  package manifests, or module directories that represent independently buildable units. Record
  real paths, not placeholders.
- **A custom build orchestration script**, if one exists (e.g. a top-level build script that
  builds dependencies in the correct order) — prefer referencing it as the authoritative full-build
  command over a hand-assembled one, if it exists and is documented or discoverable.
- **Build dependency order** between shared libraries/packages and the modules that depend on
  them, if the project has more than one independently buildable unit.
- **Test runner commands**, if any test projects/suites exist. If none exist, say so explicitly —
  do not invent a test command.
- **Module boundaries for "module-specific" vs. "full" builds** — i.e. what it means to build only
  the module(s) touched by a Bug-type ticket vs. the full workspace build required for
  Enhancement/CR-type tickets, per this project's own module layout.

If `CODE_ROOT` mixes multiple build tools (e.g. a .NET backend and a separate Node.js frontend),
record each distinctly and ask the user which one(s) the ticket workflow's build gate should cover
(it may need to cover more than one).

---

## Content to Populate in `.ai/behavior/setting.md`

- **`{{BUILD_SCOPE_RULES}}`** — Project identification (name/framework/build tool/configuration/
  platform if applicable), solution/project file inventory (combined vs. module-specific), the
  full-workspace and single-module build commands, any custom build orchestration script and the
  order it enforces, build dependency order between shared libraries and modules, test project
  detection, and the key configuration files relevant to building (e.g. the files that define
  connection strings, environment config, or build targets) — all grounded in what was actually
  detected, not templated from another stack.
- **`{{RISK_THRESHOLDS}}`** — the concrete scope threshold(s) that should trigger a STOP-and-
  confirm-scope-with-user behavior for this project (e.g. "more than N files need to change" or
  "a change spans more than one top-level module/service") — pick a sensible default if the user
  has not specified one, and say so explicitly so it can be tuned later.
- **`{{STACK_CHECKLIST}}`** (as used in `.ai/behavior/setting.md`'s own Pre-Push Checklist) — a
  short list of this stack's own pre-push gates beyond the generic ones already listed in that
  checklist (e.g. a specific data-access-layer pattern to verify, a required attribute/decorator on
  certain classes, a logging-declaration convention) grounded in what `create-coding-standards.prompt.md`
  already found. Do not duplicate the WCAG-specific `{{STACK_CHECKLIST}}` instance that lives in
  `.ai/governance/wcag-fix-patterns.md` — that is a separate token occurrence that **no generator
  owns**; it is intentionally hand-maintained per-project (like `{{PROJECT_SPECIFIC_FIXES}}` in
  `custom-fixes.md`), so leave it untouched.
  Live detection against the actual repo is the primary and authoritative source for this
  checklist. As a supplementary hint only, also check whether `stacks/<detected-stack>/notes.md`
  exists in this package (e.g. `stacks/dotnet-mvc/notes.md`) for the stack identified in
  `CODE_ROOT`'s `.ai/knowledge-base.md`; if present, read it for example pre-push gate ideas worth
  confirming against the real codebase. If no matching `stacks/<stack>/notes.md` file exists, skip
  this step entirely and rely solely on live detection — a missing overlay file must never block
  or weaken the checklist.

---

## Files You Must Touch

Verified directly against this package's `core/` content — every file in the shipped package that
references these tokens:

| Token | Files to update |
|---|---|
| `{{BUILD_SCOPE_RULES}}` | `.ai/behavior/setting.md` (Section 1, "Build Scope") |
| `{{RISK_THRESHOLDS}}` | `.ai/behavior/setting.md` (Section 2, "Ticket Type Risk Posture"), `.ai/behavior/decision-rules.md` (STOP Condition #8) |
| `{{STACK_CHECKLIST}}` | `.ai/behavior/setting.md` (Section 3, "Pre-Push Checklist") — **only** this occurrence; do not touch the separate `{{STACK_CHECKLIST}}` in `.ai/governance/wcag-fix-patterns.md` (no generator owns it — it is intentionally hand-maintained per-project) |
| `{{BUILD_COMMAND_FULL}}` | `AGENTS.md` (Build section), `.ai/governance/copilot-instruction.md`, `.ai/governance/scm-workflow.md`, `.ai/governance/security-and-compliance.md`, `.ai/templates/pr-template.md`, `.github/agents/ticket-processor.agent.md`, `.github/prompts/pr-review.prompt.md` |
| `{{BUILD_COMMAND_MODULE}}` | Same 7 files as `{{BUILD_COMMAND_FULL}}` above |
| `{{SOLUTION_FILES}}` | `AGENTS.md`, `.github/agents/ticket-processor.agent.md`, `.github/prompts/pr-review.prompt.md` |

Use the exact same build-command strings everywhere a given token appears — these files must never
disagree with each other about how to build the project.

**Inline vs. block usage.** `{{BUILD_SCOPE_RULES}}` is a full block in `.ai/behavior/setting.md`, and
`{{SOLUTION_FILES}}`, `{{BUILD_COMMAND_FULL}}` and `{{BUILD_COMMAND_MODULE}}` often sit inside a
sentence (for example in `.github/prompts/pr-review.prompt.md`). When a token appears inline in a
sentence rather than as its own block, produce a concise inline-appropriate phrasing of the same
fact, not the full block verbatim. The commands themselves stay byte-identical in every file; only
the surrounding wording adapts.

**Single-command and no-solution-file projects.**
- If the module-level and full-project build commands are identical (single-package project, or no
  meaningful module split), state the single command once. Do not write "X or the full X", and
  do not duplicate it as separate "module" and "full" entries; say once that one command covers both.
- If the target stack has no solution-file concept (for example Node.js, Python, Go, Maven/Gradle
  single-module projects), describe `{{SOLUTION_FILES}}` as the equivalent root project-manifest
  file(s) (for example `package.json`, `pom.xml`, `requirements.txt`, `pyproject.toml`, `go.mod`)
  rather than forcing "solution file" terminology.

**Ownership boundary.** `{{CODING_STANDARDS_BODY}}` and `{{THEME_FOLDERS}}` are owned by
`create-coding-standards.prompt.md`; `{{BRANCH_PREFIX_TABLE}}` and `{{REPO_REMOTE_URL}}` are owned
by `create-scm-workflow.prompt.md` — do not edit those tokens even if they appear in a file you are
otherwise updating (e.g. `AGENTS.md`, `.github/agents/ticket-processor.agent.md`).

---

## Step 7: Self-Delete

Once `.ai/behavior/setting.md` and every file in the table above has been updated and you have
reported the summary to the user, delete this file (`create-build-settings.prompt.md`) from the
target project's `.github/prompts/` folder. This generator is single-use; leaving it in place
risks someone re-running it later and clobbering build settings that have since been hand-edited
or kept current through normal ticket work.
