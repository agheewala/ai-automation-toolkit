---
description: >
  One-time setup generator. Scans the target project's source code and documentation,
  auto-detects its technology stack, and produces .ai/knowledge-base.md — the canonical
  domain and architecture reference consumed by the rest of this automation package.
---

# Create Knowledge Base

You will be invoked once, at integration time, to generate `.ai/knowledge-base.md` for a new
project. This file becomes the canonical source of truth that the Ticket Processor and Domain
Engineer agents load on every ticket.

> **Self-deleting prompt.** This file exists only to bootstrap the knowledge base. After it
> successfully writes `.ai/knowledge-base.md`, delete this file from the project's
> `.github/prompts/` folder (see **Step 6** below). Do not keep it around — a stale generator
> invites someone to re-run it against a half-finished project and overwrite good content.

---

## CONFIGURATION

Before running this prompt, the user must edit the four placeholders below (or supply them in
chat). Do not guess values for missing placeholders — ask the user.

```
PROJECT_NAME: <short name of the project/product, e.g. "Acme Billing Platform">
SYSTEM_DESCRIPTION: <one or two sentences describing what the system does and who uses it>
PVD_PATHS: <path(s) to existing design docs, process manuals, specs, or requirements documents —
            comma-separated if multiple; "none" if no such documents exist>
CODE_ROOT: <path to the root of the source code to scan, e.g. the repository root or a specific
            module folder>
```

If any value is missing, ask the user for it before proceeding — do not fabricate a project name,
description, or paths.

---

## Your Job

1. Read every CONFIGURATION value above. If `PVD_PATHS` is not `"none"`, read those documents too
   (note: binary formats such as `.docx`/`.pdf` may not be directly readable — if so, fall back to
   the source code as the authoritative source and say so in the output's provenance line).
2. Auto-detect the technology stack from `CODE_ROOT` (see **Auto-Detection Instructions** below).
3. Scan `CODE_ROOT` for domain concepts, module boundaries, business rules, and code patterns (see
   **Content-Gathering Instructions** below).
4. Write `.ai/knowledge-base.md` using the exact section structure in **Required Output
   Structure** below, populated entirely from what you found in steps 1-3 — never invent facts,
   table names, status codes, or business rules that aren't backed by something you actually read.
5. Report to the user: which sections were fully populated, which were left thin or marked
   "not found" due to insufficient source material, and what stack was detected.
6. Delete this generator prompt file from the project's `.github/prompts/` folder.

---

## Auto-Detection Instructions

Do not assume any single language, framework, database, or build tool. Inspect `CODE_ROOT` for
marker files and infer the stack from what is actually present:

| Found in `CODE_ROOT` | Inference |
|---|---|
| `*.csproj`, `*.sln`, `*.fsproj` | .NET — check the project file(s) for target framework, and for web projects look for the web framework in use (ASP.NET Core minimal APIs, ASP.NET Core MVC, older ASP.NET MVC, server-side templated views, etc.) |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | Java/Kotlin — check for the application framework (e.g. Spring Boot starters, Jakarta EE) declared in the dependency list |
| `package.json` | Node.js/JavaScript/TypeScript — check `dependencies`/`devDependencies` for the framework (e.g. Express, NestJS, Next.js, React, Angular, Vue) |
| `requirements.txt`, `pyproject.toml`, `Pipfile`, `setup.py` | Python — check for the web/application framework in the dependency list (e.g. Django, Flask, FastAPI) |
| `go.mod` | Go — check `require` directives for the web/application framework |
| `Gemfile` | Ruby — check for Rails or other framework gems |
| `composer.json` | PHP — check `require` for the framework (e.g. Laravel, Symfony) |
| `Cargo.toml` | Rust — check `[dependencies]` for the application framework |

For each stack signal found, also look for:
- **Database technology** — connection strings, ORM/driver package references (e.g. an ORM
  package, a specific DB driver/client library), migration folders, or schema files. Identify the
  actual database engine(s) in use; do not assume one.
- **UI technology** — server-rendered templates vs. a client-side framework vs. no UI (API-only
  service). Identify what is actually present.
- **Build/test tooling** — the actual build command(s) for this stack (e.g. the project's own
  build script, task runner config, or documented build command) and test runner, taken from
  config files or existing documentation — not assumed from a different ecosystem.
- **Module/folder boundaries** — top-level folders that represent separable subsystems or
  services (mirrors "Module Ownership Map" below).

If `CODE_ROOT` mixes multiple stacks (e.g. a frontend app plus a separate backend service), record
each one distinctly rather than collapsing them into a single assumed stack.

---

## Content-Gathering Instructions

Beyond stack detection, read enough of the codebase and any `PVD_PATHS` documents to populate the
domain-specific sections below with real information:

- **Entities and vocabulary** — look for the core domain nouns (the "things" the system manages)
  and their primary data model/table/collection and key identifying fields.
- **Lifecycle/status values** — look for enums, constants files, or status columns that define the
  states an entity can be in and what transitions are allowed.
- **Architecture layering** — identify the actual call flow (e.g. UI → controller/handler →
  service/business logic → data access → storage), and any rules enforced about which layer may
  call which (e.g. "controllers must not call the data layer directly").
- **Module ownership** — map top-level modules/services to what domain data and responsibilities
  they own.
- **Key tables/collections/schemas** — identify the persistent storage structures that matter most,
  grouped by purpose (e.g. core entities, financial/billing, audit/history, lookup/reference data).
- **Business rules** — identify rules enforced in code (validation, guards, invariants) that a
  future change must not violate.
- **Code patterns** — find a representative example of the project's own conventions for a
  typical unit of work (e.g. a service method, a handler, a repository method) by reading one or
  two real files, not by inventing a generic example.
- **Naming conventions** — identify actual naming patterns for the artifact types this project
  uses (e.g. interfaces, implementations, data transfer objects, view models), from real examples
  in the codebase.
- **Transaction/workflow flows** — trace one or two representative end-to-end flows through the
  layers (e.g. how a core entity gets created, updated, and finalized).
- **Batch/background jobs** — identify any scheduled, queued, or batch processing entry points.
- **Roles and access** — identify any role- or permission-based access control definitions.
- **Anything project-specific and repeated** — if the codebase has its own equivalent of a complex
  rules table (matrices, state machines, lookup grids) that governs a non-obvious business
  process, document its structure and how to update it, the same way you would for any other
  section — grounded in what you actually read, not templated from another project's domain.

If a section has no corresponding material in this codebase (e.g. there are no batch jobs), say so
explicitly in that section rather than omitting the header or fabricating content.

---

## Required Output Structure

Produce `.ai/knowledge-base.md` with exactly these section headers, in this order (confirmed
against a real production example of this document — do not add, remove, or rename sections):

```
# <PROJECT_NAME> Knowledge Base — Canonical Source of Truth

> Sources / Authority Rule / Last verified header block

## 1. System Overview
## 2. Architecture
## 3. Domain Glossary
## 4. Supplement / Transaction Types
## 5. Status / State Codes
## 6. Module Ownership Map
## 7. Key DB Tables
## 8. Critical Business Rules
## 9. Code Patterns
## 10. Naming Conventions
## 11. Transaction Flows
## 12. Batch Jobs
## 13. Roles and Access
## 14. Supplement Backout Matrix System
## 15. Technology Stack
## 16. What Copilot Must Never Do
## 17. Data Dictionary & Stored Procedure Library (Authoritative SQL Source)
```

Notes on applying this structure to a different project's domain:

- The header text above is the structural template; replace domain-specific wording with this
  project's own vocabulary where it improves clarity (e.g. if this project's core workflow unit
  is called a "request" or "order" rather than a "supplement," you may reflect that in prose
  within the section — but keep the section numbering and the header list as given, so that other
  package files which reference these sections by number stay valid).
- **Section 4** ("Supplement / Transaction Types") should list this project's actual set of
  transaction/operation types if it has one; if the domain has no equivalent concept, state that
  plainly in the section rather than inventing one.
  **Section 5** ("Status / State Codes") should list the actual status/state enumerations found in
  the codebase for its core entities.
- **Section 7** ("Key DB Tables") should reflect whatever persistent storage technology was
  detected (tables, collections, indexes — whatever term fits the detected database technology).
- **Section 14** ("Supplement Backout Matrix System") is a placeholder for *whatever complex,
  non-obvious rules engine or matrix this project's own domain actually has* (e.g. a reversal/undo
  matrix, a permission matrix, a pricing matrix). If no such mechanism exists in this codebase,
  write this section stating that no equivalent complex rules matrix was found, rather than
  omitting the header.
- **Section 15** ("Technology Stack") must reflect only what was actually auto-detected in the
  **Auto-Detection Instructions** step — list the real framework, database, UI technology, build
  commands, and test commands for this project.
- **Section 17** ("Data Dictionary & Stored Procedure Library") should point to a data-dictionary
  location only if this project actually has (or will have) a generated schema/stored-procedure
  catalog; otherwise state that no separate data dictionary exists and that this knowledge base's
  Section 7 is the primary schema reference.

Every section must be grounded in something you actually read from `CODE_ROOT` or `PVD_PATHS` in
this run. Where you cannot find supporting material for a section, write a short explicit note
(e.g. "Not found in current codebase — revisit once implemented") instead of fabricating content.

---

## Step 6: Self-Delete

Once `.ai/knowledge-base.md` has been written and you have reported the summary to the user,
delete this file (`create-knowledge-base.prompt.md`) from the target project's
`.github/prompts/` folder. This generator is single-use; leaving it in place risks someone
re-running it later and clobbering a knowledge base that has since been hand-edited or kept
current through normal ticket work.
