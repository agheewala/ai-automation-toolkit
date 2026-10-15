# Custom Fixes — Project-Specific Verified Accessibility Fixes

> **Priority 1** in the 3-tier fix system.
> These fixes have been verified to resolve violations in this codebase on a scanner re-scan.
> The AI reads this file BEFORE applying generic WCAG patterns.

---

## How This File Works

```
┌──────────────────────────────────────────────────────────────┐
│ LEARNING SYSTEM                                              │
│                                                              │
│ 1. AI applies a fix                                          │
│ 2. Developer runs an accessibility re-scan                   │
│ 3. Violation is resolved → fix is documented here            │
│ 4. Future runs automatically use this proven fix              │
│ 5. Team knowledge accumulates over time                       │
└──────────────────────────────────────────────────────────────┘
```

**To add a new custom fix:** Add an entry under the correct WCAG criterion section.
**Format:** Pattern description, before/after code, applicable context, and any conditions.

---

{{PROJECT_SPECIFIC_FIXES}}

> `{{PROJECT_SPECIFIC_FIXES}}` is **not** populated by a generator prompt — unlike the other
> tokens in this toolkit, this file is expected to be **hand-maintained per-project** over time.
> Start it empty (or with the structure below) and add an entry here every time the team verifies
> a fix on a real scan re-run, following the pattern:
>
> ```
> ## WCAG <criterion> — <short description>
>
> ### <Fix Name>
>
> **Applies to:** <where this pattern applies in this codebase>
>
> **Before (Violation):**
> ```<language>
> <offending markup/code>
> ```
>
> **After (Fix):**
> ```<language>
> <corrected markup/code>
> ```
>
> **When to use:** ...
> **When NOT to use:** ...
> ```

---

## Exclusions

The following violation types are **never fixed** by this workflow:

| Violation Type | Reason |
|:---------------|:-------|
| Color contrast (1.4.3) | Requires design decision — color palette change |
| Color contrast (1.4.11) | Requires design decision — UI component color change |

---

## Version

| Field | Value |
|:------|:------|
| **Created** | update this date when this file is first populated for a project |
| **Last Updated** | update this date whenever a new fix is added |
| **Scope** | Global — all modules in this project |

---
