---
description: >
  Setup generator (run after create-knowledge-base.prompt.md). Reads the target project's own
  .ai/knowledge-base.md and extracts its business domain vocabulary and architectural boundaries
  into .github/agents/domain-engineer.agent.md — the domain-aware implementation/review agent
  consumed by the rest of this automation package.
---

# Create Domain Agent

You will be invoked once, at integration time, to populate `.github/agents/domain-engineer.agent.md`
for a new project, turning the generic scaffold into a project-specific domain-aware agent.

> **Prerequisite**: `create-knowledge-base.prompt.md` (run first) must have already produced
> `.ai/knowledge-base.md`, and ideally `create-coding-standards.prompt.md` has already produced
> `.ai/governance/coding-standards.md`. This generator does not re-scan the codebase itself — it
> reads what those two files already recorded. If `.ai/knowledge-base.md` does not exist yet, stop
> and tell the user to run `create-knowledge-base.prompt.md` first.

> **Self-deleting prompt.** After this file successfully writes
> `.github/agents/domain-engineer.agent.md`, delete this file from the target project's
> `.github/prompts/` folder (see **Step 5** below). Do not keep it around — a stale generator
> invites someone to re-run it later and clobber a domain agent that has since been hand-edited or
> kept current through normal ticket work.

---

## Your Job

1. Read `.ai/knowledge-base.md` in full, and `.ai/governance/coding-standards.md` if it exists.
2. Extract the business-domain content (see **Domain Vocabulary Extraction** below) and the
   architecture content (see **Architectural Boundaries Extraction** below) from what those files
   already contain — do not re-derive either from the source codebase yourself; if a fact is
   missing from both files, leave the corresponding part of the output stating that it was not
   found in the knowledge base, rather than scanning the codebase independently to fill the gap.
3. Read the current `.github/agents/domain-engineer.agent.md` scaffold in this package to see the
   exact shape of the `{{DOMAIN_VOCABULARY}}` and `{{ARCHITECTURAL_BOUNDARIES}}` placeholders
   (and the `{{PROJECT_NAME}}` placeholder already handled by an earlier setup step — leave it
   alone if already filled), then write the replacement content directly into that file.
4. Report to the user: a short summary of what domain vocabulary and architectural facts were
   found and written, and whether either section had to be marked thin/incomplete because the
   knowledge base did not cover it.
5. Delete this generator prompt file from the project's `.github/prompts/` folder.

---

## Domain Vocabulary Extraction

Read this project's own knowledge-base sections covering domain glossary, core business entity/
transaction types, status/state codes, critical business rules, and any complex business-rule
matrix or state engine (these correspond to Sections 3-5, 8, and 14 in the structure
`create-knowledge-base.prompt.md` produces, but locate them by content/heading, not by assuming a
fixed section number — a hand-edited knowledge base may have renumbered or merged them).

From that material, write a `{{DOMAIN_VOCABULARY}}` replacement containing, in this project's own
real terminology:

1. A glossary table of the project's core domain terms/entities, each with its primary data
   storage structure (table, collection, or equivalent) if the knowledge base names one.
2. The lifecycle(s) that govern the project's core business entities, if the knowledge base
   documents one — shown as whatever sequence/diagram format best matches what was documented
   (a linear status progression, a state diagram, or a described set of valid transitions).
3. The enumerated transaction/operation types the system supports, if the knowledge base lists
   them, with a one-line description of what each does.
4. The non-negotiable business rules a senior engineer must always enforce, translated directly
   from the knowledge base's own business-rules section — including, where the knowledge base
   actually documents them: lifecycle-gated prohibitions (rules that forbid an action once a
   governing entity has passed a particular status), concurrency/locking constraints (rules that
   limit how many active instances of something may exist at once), and locale/currency/region
   assumptions the system must not hardcode (only if the project's own knowledge base documents
   supporting more than one locale/currency/region — do not invent multi-region concerns for a
   single-region project).

Do not generalize, categorize, or editorialize the business rules beyond what the knowledge base
already states — this section should read as a faithful, organized restatement of real project
facts, not a reinterpretation. Do not assume what kind of domain this is (do not default to any
particular industry's typical vocabulary) — use only the terms, entities, and rules the knowledge
base actually names for this project.

---

## Architectural Boundaries Extraction

Read this project's own knowledge-base sections covering architecture, module ownership, naming
conventions, and technology stack (again, locate by content/heading rather than assuming fixed
numbering), plus `.ai/governance/coding-standards.md` if it exists (its naming-conventions and
layering sections overlap and may have more detail than the knowledge base alone).

From that material, write an `{{ARCHITECTURAL_BOUNDARIES}}` replacement containing, in this
project's own real terminology:

1. **Layering rules** — the actual call-flow convention this project enforces (which layer may
   call which), stated as this project documented it, not a generic layered-architecture
   description.
2. **Module/boundary rules** — the module or service boundaries the knowledge base's module
   ownership map defines, and any explicit rule found about not crossing them without
   justification.
3. **Naming conventions** — a table of this project's own real naming patterns per architectural
   role (data-access, business-logic, request-handling, data-transfer/view objects, or whatever
   roles this project's own naming-conventions material actually names), each with a real example
   name found in that material — never invent a generic placeholder example if a real one is
   available.
4. **Code pattern checklist** — a checklist a reviewer could run down to verify generated or
   reviewed code against this project's own conventions, built from the same naming/layering/
   security facts gathered above (e.g. confirm a request-handler never calls a data-access method
   directly, confirm the project's own logging mechanism is used, confirm the project's own
   authentication/authorization convention is applied) — ground every checklist line in a fact you
   actually read, not a generic best practice unrelated to this project's documented conventions.

Do not assume a specific language, framework, or layer-naming scheme — use whatever this project's
own knowledge base and coding standards actually document, including if that project has a
flatter, simpler, or differently-shaped architecture than a classic multi-tier layering (e.g. a
single-service API, an event-driven pipeline, or a monolith with no formal layer separation) —
reflect that shape faithfully rather than forcing it into a controller/service/data-access
template that doesn't match.

---

## Files You Must Touch

This generator owns two tokens, both filled in exactly one file:

| Token | File to update |
|---|---|
| `{{DOMAIN_VOCABULARY}}` | `.github/agents/domain-engineer.agent.md` |
| `{{ARCHITECTURAL_BOUNDARIES}}` | `.github/agents/domain-engineer.agent.md` |

Do not edit any other file or token. `{{CODE_PATTERN_EXAMPLES}}` in
`.github/skills/patterns/SKILL.md` is owned by `create-implementation-patterns.prompt.md` — leave
it untouched here even if you read that file for cross-reference while gathering naming-convention
examples.

---

## Step 5: Self-Delete

Once `.github/agents/domain-engineer.agent.md` has been written and you have reported the summary
to the user, delete this file (`create-domain-agent.prompt.md`) from the target project's
`.github/prompts/` folder. This generator is single-use; leaving it in place risks someone
re-running it later and clobbering a domain agent that has since been hand-edited or kept current
through normal ticket work.
