# {{PROJECT_NAME}} Coding Standards

> **Authority**: Current source code is the standard. This document describes patterns that MUST be followed when generating or modifying code.
> **Last verified**: update this date whenever this file is regenerated.

---

{{CODING_STANDARDS_BODY}}

> `{{CODING_STANDARDS_BODY}}` is populated per-project by `generators/create-coding-standards.prompt.md`
> from the target repo's own source code (actual class names, file patterns, framework helpers,
> and theme/CSS system in use). The generated content is stack-specific (e.g. .NET/Razor, Java/JSP,
> Node/React, etc.) and MUST NOT be hardcoded in this `core/` file. However, every generated
> `coding-standards.md` MUST follow this same section shape, because these categories are generic
> regardless of stack:
>
> 1. **Technology Stack** — a table of the project's framework, database(s), ORM/data-access
>    approach, UI framework, CSS framework, logging library, and any other foundational tech choices.
> 2. **Naming Conventions & Layering** — the project's layering rules (e.g. Controller → Service →
>    Data Access → DB), class/file naming patterns per architectural role (DAO, Service, Controller,
>    ViewModel/DTO equivalents), and any established factory/dependency patterns.
> 3. **CSS / Theme Rules** — if the stack has a multi-theme or multi-brand CSS system, document the
>    theme folders (see `{{THEME_FOLDERS}}`), file naming convention, and which files to edit for a
>    shared vs. single-theme change. If the stack has no theme system, state that explicitly instead
>    of inventing one.
> 4. **Templating / Markup Rules (No-Raw-HTML rule)** — if the framework provides accessibility-aware
>    form/markup helpers (label, input, dropdown, validation-summary equivalents), require their use
>    over raw markup elements, and show the raw-vs-helper mapping table.
> 5. **No-Hardcoded-Strings rule** — require all user-facing text to come from the project's
>    localization/resource-string mechanism rather than literal strings in markup or code.
> 6. **Security Rules** — anti-forgery tokens, authentication base/middleware, parameterized data
>    access, output encoding, and any other security conventions enforced by this project's stack.
>    Cross-reference `governance/security-and-compliance.md` rather than duplicating it.
> 7. **Accessibility Rules** — cross-reference `governance/wcag-fix-patterns.md` rather than
>    duplicating it; list only the project's framework-specific accessibility helpers here.
> 8. **What Copilot Must NOT Do** — a concrete, stack-specific "never do this" list derived from the
>    rules above (e.g. never bypass the templating helpers, never hand-edit compiled CSS when the
>    source is a pre-processor, never use an unescaped-output helper on user-supplied content).

---

## Cross-References

- Accessibility code patterns: [wcag-fix-patterns.md](wcag-fix-patterns.md)
- Security rules: [security-and-compliance.md](security-and-compliance.md)
- SCM/branching conventions: [scm-workflow.md](scm-workflow.md)
