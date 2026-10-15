---
description: >
  Setup generator (run after create-knowledge-base.prompt.md). Scans the target project's own
  source code for naming conventions, layering patterns, UI/markup helpers, and theme/CSS
  structure, and produces .ai/governance/coding-standards.md — the per-stack coding rules
  reference consumed by the Ticket Processor and Domain Engineer agents.
---

# Create Coding Standards

You will be invoked once, at integration time, to generate `.ai/governance/coding-standards.md`
for a new project. This file documents the project's own naming conventions, architectural
layering, markup/templating rules, and (if applicable) multi-theme CSS structure, so that future
code changes follow established patterns instead of inventing new ones.

> **Prerequisite**: `create-knowledge-base.prompt.md` (run first) must have already produced
> `.ai/knowledge-base.md`. This generator reuses the stack detection and `CODE_ROOT` established
> there — do not re-ask the user for `CODE_ROOT` if `.ai/knowledge-base.md` already records it;
> read it from there instead.

> **Self-deleting prompt.** After this file successfully writes
> `.ai/governance/coding-standards.md`, delete this file from the target project's
> `.github/prompts/` folder (see **Step 5** below). Do not keep it around — a stale generator
> invites someone to re-run it later and clobber hand-maintained standards.

---

## Your Job

1. Read `.ai/knowledge-base.md` to confirm `CODE_ROOT` and the already-detected technology stack
   (framework, UI technology, build tool). If `.ai/knowledge-base.md` does not exist yet, stop and
   tell the user to run `create-knowledge-base.prompt.md` first.
2. Scan `CODE_ROOT` for linter/formatter/style configuration (see **Auto-Detection
   Instructions**) and for representative source files that reveal the project's own naming and
   layering conventions (see **Content-Gathering Instructions**).
3. Write `.ai/governance/coding-standards.md` filling the **exact section shape** already defined
   in this project's `core/.ai/governance/coding-standards.md` scaffold — read that scaffold file
   first (it ships with this automation package) and replace its `{{CODING_STANDARDS_BODY}}`
   placeholder with real, codebase-derived content following the 8 categories listed in that
   scaffold's own guidance comment (Technology Stack, Naming Conventions & Layering, CSS/Theme
   Rules, Templating/Markup Rules, No-Hardcoded-Strings rule, Security Rules, Accessibility Rules,
   What [Agent] Must NOT Do).
4. Report to the user: which categories were fully populated from real code, which were marked
   "not applicable to this stack" (e.g. no theme system, no markup-helper layer), and what you
   scanned.
5. Delete this generator prompt file from the project's `.github/prompts/` folder.

---

## Auto-Detection Instructions

Do not assume any single language, framework, or UI technology. Inspect `CODE_ROOT` (and reuse
whatever `.ai/knowledge-base.md` already recorded) for:

- **Linter/formatter/style configuration** — e.g. `.editorconfig`, `.eslintrc*`, `.prettierrc*`,
  `stylecop.json`, `.stylelintrc*`, `pyproject.toml` (`[tool.black]`/`[tool.ruff]`), `checkstyle.xml`,
  `.rubocop.yml`, `rustfmt.toml`. If found, note the enforced rules (indentation, naming case,
  import ordering) so generated standards don't contradict the project's own tooling.
- **Architectural layering** — identify the actual call-flow convention already used in the
  codebase (e.g. controller/handler → service/business-logic → data-access → storage) by reading
  a small number of real files in each layer, not by assuming a specific pattern name.
- **Class/file naming patterns per architectural role** — find real examples of how this project
  names its own equivalents of data-access classes, business-logic classes, request handlers, and
  data-transfer/view objects. Quote the real naming pattern and a real example name — never invent
  a generic placeholder like `XxxService` unless the project's own code genuinely uses that
  convention.
- **Markup/templating helpers** — if the UI technology detected in `.ai/knowledge-base.md` is a
  server-rendered templating system (or any framework) that provides accessibility-aware
  form/markup helpers (label, input, dropdown, validation-summary equivalents), find real examples
  of their usage. If the project is API-only or uses a client-side framework with no such
  helper layer, say so explicitly instead of inventing one.
- **Localization/resource-string mechanism** — find how the project externalizes user-facing text
  (e.g. a resource file, an i18n library, a message catalog). If none exists, say so.
- **Theme/CSS folder structure** — only if a web UI framework was detected in `.ai/knowledge-base.md`
  (recorded by `create-knowledge-base.prompt.md`): scan for a multi-theme or multi-brand CSS structure (multiple named folders under a shared
  styles root, each containing a base stylesheet and jurisdiction/tenant/brand-specific override
  files). Record the actual theme folder names and file-naming convention found. If the project
  has a single, non-themed stylesheet (or no stylesheet system at all), say so explicitly — do not
  invent a multi-theme system that doesn't exist.
- **Security conventions already in code** — anti-forgery/CSRF token usage, authentication
  base-class/middleware patterns, parameterized data-access calls, output-encoding behavior. Cross
  reference rather than duplicate `governance/security-and-compliance.md` and
  `governance/wcag-fix-patterns.md` (both already shipped by this package) instead of re-deriving
  their content here.

---

## Content-Gathering Instructions

Populate each of the 8 categories named in the `core/.ai/governance/coding-standards.md` scaffold
using only what you actually found in `CODE_ROOT`:

1. **Technology Stack** — a table restating (not re-detecting) the stack already recorded in
   `.ai/knowledge-base.md` Section 15, for convenience in this file.
2. **Naming Conventions & Layering** — the project's own layering rule and a table of real
   class/file naming patterns per architectural role, each with a real example name found in the
   codebase. Include one short, real code excerpt (not fabricated) showing the layering call chain
   for a typical unit of work, trimmed to the essential pattern.
3. **CSS / Theme Rules** — populate `{{THEME_FOLDERS}}`-equivalent content: a table of actual theme
   folder names and the file-naming convention for base vs. override stylesheets, and a rule for
   how many files to touch for a single-theme vs. shared change. Write "No multi-theme CSS system
   detected in this codebase" if none exists.
4. **Templating / Markup Rules** — a raw-markup-to-helper mapping table using the project's own
   real helper names, if such a layer exists. Otherwise state plainly that no such helper layer
   exists for this stack.
5. **No-Hardcoded-Strings rule** — name the actual resource/localization mechanism found, with one
   real usage example. If none exists, state that user-facing text is not currently externalized
   in this codebase.
6. **Security Rules** — a short list of the project's own enforced security conventions (found in
   step above), with a pointer to `governance/security-and-compliance.md` for the full rules
   rather than duplicating them.
7. **Accessibility Rules** — a pointer to `governance/wcag-fix-patterns.md`, plus only the
   project's own framework-specific accessibility helpers (if any) found during scanning.
8. **What [Agent] Must NOT Do** — a concrete, stack-specific "never do this" list derived strictly
   from the patterns found above (e.g. never bypass the markup-helper layer if one exists, never
   hand-edit compiled CSS when the source is a pre-processor, never use an unescaped-output helper
   on user-supplied content) — do not copy a generic list; ground every bullet in something you
   actually detected.

If a category genuinely has no equivalent in this project's stack, write that explicitly in that
category rather than omitting it or inventing content to fill the gap.

---

## Files You Must Touch

This generator owns two tokens. `{{CODING_STANDARDS_BODY}}` is filled in exactly one file;
`{{THEME_FOLDERS}}` (the real, detected theme-folder list from the CSS/Theme Rules category — or
the literal statement that no such system exists) must be filled identically in every file that
references it, so all four locations stay consistent:

| Token | Files to update (verified against this package's `core/` scaffold) |
|---|---|
| `{{CODING_STANDARDS_BODY}}` | `.ai/governance/coding-standards.md` |
| `{{THEME_FOLDERS}}` | `.ai/governance/coding-standards.md` (Section 3 body, inside `{{CODING_STANDARDS_BODY}}` itself), `.ai/behavior/setting.md` (Pre-Push Checklist line: "CSS changes applied to `{{THEME_FOLDERS}}`"), `.ai/governance/wcag-fix-patterns.md` (Pre-Push Accessibility Checklist line: "CSS changes applied to `{{THEME_FOLDERS}}` if color/appearance related"), `AGENTS.md` (Critical Gotchas: "CSS theme files — ... touch the following theme folders: `{{THEME_FOLDERS}}`") |

**`{{THEME_FOLDERS}}` when the project has no theme-folder convention.** Do not leave an empty list
or a bare "none". Fill the token with a phrase that reads naturally in each sentence it sits in, for
example: "none — this project has no per-theme CSS structure". Use that same fact in all four
locations, and where the surrounding sentence would read awkwardly (for example a checklist line
"CSS changes applied to none"), reword that sentence minimally so it still reads correctly (for
example "CSS changes applied to the project's stylesheet(s); no per-theme folders exist").

**Inline vs. block usage.** `{{THEME_FOLDERS}}` is a full table in `coding-standards.md` but an inline
phrase in the other three files. When it appears inline in a sentence, produce a concise
inline-appropriate phrasing (for example a comma-separated list of the real folder names), not the
full table.

Do not edit any other file or token. `{{BUILD_SCOPE_RULES}}`, `{{RISK_THRESHOLDS}}`, and
`{{STACK_CHECKLIST}}` in `.ai/behavior/setting.md` are owned by `create-build-settings.prompt.md`
— leave them untouched here even though they live in the same file you are partially editing.

---

## Step 5: Self-Delete

Once `.ai/governance/coding-standards.md` has been written and you have reported the summary to
the user, delete this file (`create-coding-standards.prompt.md`) from the target project's
`.github/prompts/` folder. This generator is single-use; leaving it in place risks someone
re-running it later and clobbering coding standards that have since been hand-edited or kept
current through normal ticket work.
