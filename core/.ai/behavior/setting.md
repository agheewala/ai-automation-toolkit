# Build Settings

> **Authority**: Verified from solution files, build scripts, and project/package manifests in the workspace.
> **Last verified**: update this date whenever this file is regenerated.

---

## 1. Build Scope

{{BUILD_SCOPE_RULES}}

> Populated per-project by `generators/create-build-settings.prompt.md` from the target repo's
> own solution/project files, build scripts, and module boundaries. Covers: project
> identification (name, framework, build tool, configuration, platform), solution file
> inventory (combined vs. module-specific), build commands (full workspace vs. single module),
> any custom build orchestration script and the order it enforces, build dependency order between
> shared libraries and modules, test project detection, a project structure map, and the list of
> key configuration files.

---

## 2. Ticket Type Risk Posture

> Controls how cautious to be when making changes of each ticket type.

| Ticket Type | Risk Level | Approach |
|-------------|-----------|---------|
| **Bug** | Medium | Fix only the reported symptom. Do not refactor surrounding code. Verify no regression in related flows. |
| **Enhancement** | Medium-High | Confirm scope with knowledge-base domain rules. Add only what is specified. Build and verify before push. |
| **Change Request (CR)** | High | Treat as requiring explicit approval of the analysis plan before coding. Check downstream impacts on related business flows. |
| **Analysis** | Low | Read-only investigation. Produce a report. No code changes. |

{{RISK_THRESHOLDS}}

---

## 3. Pre-Push Checklist

Before pushing any branch, confirm all of the following:

```
□ Build passes (per the commands in {{BUILD_SCOPE_RULES}}) — zero errors
□ Changed files are scoped to the correct module (no cross-module edits without justification)
□ CSS changes applied to {{THEME_FOLDERS}}
□ No inline SQL added to controllers or services
{{STACK_CHECKLIST}}
□ No .vscode/mcp.json in the commit (contains API tokens)
```

> `{{STACK_CHECKLIST}}` is populated per-project from `stacks/<stack>/notes.md` with the
> stack's own pre-push conventions (e.g. input-sanitization helpers, i18n/resource-string
> rules, data-access-layer patterns, logging requirements, authorization attribute
> conventions) — do not hardcode any single stack's conventions in this `core/` file.
