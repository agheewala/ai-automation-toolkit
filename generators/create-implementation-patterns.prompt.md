---
description: >
  Setup generator (run after create-knowledge-base.prompt.md). Samples a handful of real files
  per architectural layer in the target codebase and extracts verified, copy-paste-ready code
  templates into .github/skills/patterns/SKILL.md, so future implementation work copies the
  project's own conventions instead of inventing new ones.
---

# Create Implementation Patterns

You will be invoked once, at integration time, to populate `.github/skills/patterns/SKILL.md`
for a new project with real, verified code examples drawn from that project's own codebase.

> **Prerequisite**: `create-knowledge-base.prompt.md` (run first) must have already produced
> `.ai/knowledge-base.md`. This generator reuses the stack detection, `CODE_ROOT`, and layering
> model already recorded there (knowledge-base Sections 2, 6, 9, and 10) — do not re-detect the
> stack or re-ask the user for `CODE_ROOT`; read it from there instead. If `.ai/knowledge-base.md`
> does not exist yet, stop and tell the user to run `create-knowledge-base.prompt.md` first.

> **Self-deleting prompt.** After this file successfully writes
> `.github/skills/patterns/SKILL.md`, delete this file from the target project's
> `.github/prompts/` folder (see **Step 6** below). Do not keep it around — a stale generator
> invites someone to re-run it later and clobber pattern examples that have since been
> hand-edited or kept current through normal implementation work.

---

## Your Job

1. Read `.ai/knowledge-base.md` to confirm `CODE_ROOT`, the detected technology stack, and the
   architectural layers already identified there (e.g. request-handling layer, business-logic
   layer, data-access layer, UI/presentation layer — whatever layers that project's own
   Architecture section actually names; do not assume a fixed universal set).
2. For each layer named in the knowledge base, sample 3-5 representative existing files from
   `CODE_ROOT` (see **Sampling Instructions** below) and extract the real, verified pattern each
   one demonstrates (see **Extraction Instructions** below).
3. Read the current `.github/skills/patterns/SKILL.md` scaffold in this package (it ships with
   this automation package) to see the exact shape of the `{{CODE_PATTERN_EXAMPLES}}` placeholder
   you are filling, then write the replacement content directly into that file.
4. Since this project's `.github/skills/patterns/SKILL.md` scaffold does not ship with any
   pre-existing "how to find/add a pattern" structure, author one yourself as part of the content
   you write (see **Lookup and Addition Workflow** below) — do not assume that structure already
   exists elsewhere and skip it.
5. Check `.github/prompts/implement.prompt.md` (already copied into the project generically by an
   earlier setup step) for any remaining unfilled project-specific tokens or placeholder text that
   references concepts you now have concrete answers for (e.g. a reference to "the skill file"
   that should instead name the real layers you just documented). Fill only what is clearly a
   leftover placeholder — do not rewrite content that is already generic and correct.
6. Report to the user: which layers were fully populated with real examples, which were sampled
   from fewer than 3 files because the codebase doesn't have that many instances of a layer, and
   which layers (if any) named in the knowledge base had no code to sample and were therefore
   marked "not found."
7. Delete this generator prompt file from the project's `.github/prompts/` folder.

---

## Sampling Instructions

Do not assume any single language, framework, or layer name. For each layer identified in
`.ai/knowledge-base.md`:

- Pick 3-5 files that are representative of ordinary, everyday work in that layer — prefer files
  that look like typical, unremarkable examples of the convention over files that look like
  one-off exceptions, deeply nested edge cases, or heavily refactored outliers.
- Prefer smaller, focused files over the largest file you can find in a layer — a sprawling file
  with dozens of responsibilities is harder to extract a clean, minimal template from than a
  modest one that does one thing clearly.
- If a layer has fewer than 3 files in the entire codebase, sample all of them and say so in your
  report rather than padding the count with unrelated files.
- If the knowledge base names a layer but you cannot find any matching files in `CODE_ROOT`, do
  not fabricate an example — mark that layer as "not found in current codebase" in the output.

---

## Extraction Instructions

For each sampled file, extract only what is actually present and repeated across the samples —
never invent a convention from a single occurrence, and never carry over something you saw in a
different project or framework's typical usage. For each layer, produce:

1. **A minimal, copy-paste-ready template** — a trimmed-down version of the real pattern (class/
   function shape, method signatures, control flow for a typical read and a typical write
   operation) with placeholder names substituted for the sampled files' actual domain-specific
   names (e.g. replace a real entity name like the one you found with a generic placeholder such
   as `Xxx`, consistent with how placeholders are already used elsewhere in this layer's real
   code, if the project already uses such a placeholder convention anywhere — otherwise choose a
   clearly-generic stand-in). Keep real, verified syntax, real import/using statements, real
   base-class/interface names, and the real call-chain into adjacent layers (e.g. how this layer
   invokes the next layer down, by whatever lookup/factory/injection mechanism the project
   actually uses) — do not invent syntax that isn't backed by what you read.
2. **A real file path and naming pattern** — state the actual folder convention and file-naming
   pattern you observed (e.g. where these files live, what suffix or prefix they use) so a future
   contributor knows where to put a new file of this kind.
3. **A short "key rules" bullet list** — the non-negotiable conventions you observed repeated
   across all sampled files for this layer (e.g. error-handling convention, logging convention,
   access-modifier convention, how instances of the next layer down are obtained) — ground every
   bullet in something you actually saw repeated, not a single occurrence or a guess.

If the project has a factory/registry/locator/dependency-injection mechanism for wiring one layer
to the next, show the real, minimal addition a new feature would need to make to register itself
(e.g. one new method or one new registration entry) — found by reading the actual factory/registry
file, not assumed from a generic DI pattern.

---

## Lookup and Addition Workflow

Author this structure fresh as part of the content you write into
`.github/skills/patterns/SKILL.md` — it does not exist yet in this package's scaffold. Keep it
stack-agnostic in wording (the workflow description itself should not hardcode a language or
framework name — only the worked example beneath it should use this project's real stack):

- **How a future contributor finds an existing pattern**: a short "Index" or "Table of Contents"
  near the top of the file listing every layer documented below, in the same order the knowledge
  base lists them, each with a one-line description of when to use it (e.g. "need to add a new
  read/write operation against storage? see the data-access layer section").
- **How a future contributor adds a new pattern**: a short numbered procedure at the end of the
  file — read the existing patterns for the layer most similar to the new need, copy the closest
  template, rename placeholders to the new feature's real domain names, verify the new file
  follows the "key rules" bullets for that layer, and (if this project tracks pattern freshness)
  update the "Last verified" date at the top of the file. Keep this procedure generic enough to
  apply to any of the layers documented below — do not hardcode a specific layer name into the
  procedure steps themselves.

---

## Files You Must Touch

This generator owns one token, filled in exactly one file, plus incidental cleanup of leftover
placeholders in a second file that another setup step already created generically:

| Token / File | Action |
|---|---|
| `{{CODE_PATTERN_EXAMPLES}}` in `.github/skills/patterns/SKILL.md` | Replace with the full Lookup-and-Addition-Workflow structure plus one subsection per architectural layer, each containing the minimal template, file path/naming convention, and key-rules bullets described above |
| `.github/prompts/implement.prompt.md` | Fill only genuinely-remaining project-specific placeholder tokens, if any exist; otherwise leave untouched |

Do not edit any other file or token in this project. `{{DOMAIN_VOCABULARY}}` and
`{{ARCHITECTURAL_BOUNDARIES}}` in `.github/agents/domain-engineer.agent.md` are owned by
`create-domain-agent.prompt.md` — leave them untouched here.

---

## Step 6: Self-Delete

Once `.github/skills/patterns/SKILL.md` has been written and you have reported the summary to the
user, delete this file (`create-implementation-patterns.prompt.md`) from the target project's
`.github/prompts/` folder. This generator is single-use; leaving it in place risks someone
re-running it later and clobbering pattern examples that have since been hand-edited or kept
current through normal implementation work.
