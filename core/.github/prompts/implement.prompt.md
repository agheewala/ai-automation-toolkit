---
applyTo: "**"
---

# {{PROJECT_NAME}} Implementation Guide

> ⚠️ **TYPE CHECK — Read before loading this prompt.**  
> If the ticket `Type` is **Analysis**, do **NOT** use this prompt.  
> Analysis tickets require a written report only — no branches, no code, no build.  
> See `.ai/behavior/setting.md` section 7 (Analysis posture) and stop immediately.

> **Reference**: `.ai/knowledge-base.md` is the canonical source of truth.  
> **Authority**: Source code behavior is authoritative over documentation.
---

## Pre-Code Questions (Answer Before Writing Any Code)

Before implementing any change, confirm:

1. **Which module owns this change?** (see `.ai/knowledge-base.md` module ownership map)
2. **Which layers are affected?** (controller/handler, service, data access, data/view models, views/templates, styles)
3. **Does this touch a business lifecycle step?** (If yes — what is the current status and what is the expected transition?)
4. **Does this involve fees, payments, or credentials?** (If yes — flag as high-risk)
5. **Is this a read or a write operation?** (Writes require the project's request-integrity/CSRF protection, input validation, and logging — see `.ai/governance/coding-standards.md`)
6. **Does this affect UI?** (If yes — identify which stylesheet/theme files need updating)

---

## Implementation Order

Always implement in this layer order — never skip layers:

```
1. Shared data structure(s) (DTO/model) — if a new data structure is needed
2. Data-access contract (interface/abstraction)
3. Data-access implementation (the only place database queries/commands live)
4. Data-access registration (factory/DI/registry entry, however the project wires it)
5. Service contract (interface/abstraction)
6. Service implementation (business logic)
7. Service registration (locator/DI/registry entry, however the project wires it)
8. View/data model — if UI change
9. Controller / handler (request entry point)
10. View / template — if UI change
11. Stylesheets / theme files — if visual change
```

The exact file locations, class names, and naming conventions for each step are project-specific —
read `.github/skills/patterns/SKILL.md` (filled with this project's real, verified patterns) before
writing code.

---

## Layer Rules

> Class names, base classes, file locations, and framework-specific conventions for every layer
> below are defined in `.github/skills/patterns/SKILL.md` and `.ai/governance/coding-standards.md`.
> The rules here are the stack-neutral intent those files implement.

### Data-Access Layer
- Define a contract (interface/abstraction) separately from its implementation, following the project's naming convention
- Implementation uses the project's standard database-access base class/helpers — never ad-hoc raw connections
- **No inline SQL in service or controller/handler code** — database queries/commands belong in the data-access layer only
- Use parameterized queries/commands only — never concatenate user input into query text
- Follow the project's parameter and schema naming conventions
- Always release/close connections and other resources (finally/using/dispose, as the language requires)
- Use a read-only connection/helper only for read-only reporting/reference queries against a secondary data source, if the project has one

### Service Layer
- Expose a contract (interface/abstraction); keep the implementation non-public where the language supports it
- Obtain data-access objects **only** through the project's factory/DI/locator mechanism
- Log method entry and errors through the project's logging abstraction
- Throw the project's business/domain exception type (not a generic exception) on service errors
- Pass user/session context when the operation requires it (inserts, updates, audit trails)

### Controller / Handler Layer
- Extend/implement the project's standard base controller/handler, if one exists
- Keep a single, consistent request entry-point convention per page/route, as the project defines it
- Distinguish initial load from submit/postback and route by the triggering action, per project convention
- Obtain services only through the project's service locator/DI mechanism
- **Never** put business logic directly in the controller/handler — delegate to the service layer

### View / Template Layer
- **No raw markup for form inputs** — use the project's own component/helper conventions exclusively
- No hardcoded user-facing strings — use the project's resource/localization mechanism
- Reuse the project's shared layout, hidden-field/anti-forgery partials, and validation-summary components as required by its conventions
- Access user/session context only through the project's sanctioned mechanism

### Stylesheet / Theme Layer
- Edit the project's shared stylesheet in every theme folder it maintains (see `.ai/governance/coding-standards.md` for the exact list for this project)
- Edit source stylesheets (SCSS/LESS/etc.) where a theme provides one; hand-edit compiled CSS only for themes that ship compiled output only
- **Never use inline styles** — only CSS classes

---

## Critical Rules (Never Violate)

- ❌ No inline SQL anywhere outside the data-access layer
- ❌ No raw form-input markup in views/templates — use the project's component/helper conventions
- ❌ No hardcoded UI strings — use the project's resource/localization mechanism
- ❌ No directly instantiating a data-access implementation — use the project's factory/DI mechanism
- ❌ No directly instantiating a service implementation in controllers/handlers — use the project's service locator/DI mechanism
- ❌ No cross-module data-access calls (one module's data layer from another, etc.) without explicit justification
- ❌ No business logic in controllers/handlers
- ❌ No DB logic in the service layer
- ✅ Every new class that logs must declare/obtain a logger the way the project's logging convention requires (see `.github/skills/patterns/SKILL.md`)
- ✅ All fee/payment/credential changes require senior review before push
