# WCAG Fix Patterns Reference

> **READ THIS FILE BEFORE WRITING ANY UI CODE CHANGE.**  
> This is the primary accessibility authority for all code fixes in the {{PROJECT_NAME}} workspace.  
> Defers to `governance/copilot-instruction.md` for overall governance rules.

Comprehensive accessibility violation fixes aligned with **WCAG 2.1 AA** (minimum enforced standard), **WCAG 2.2**, **Section 508**, **AODA**, and **EN 301 549**. Organized by category with axe-core / BrowserStack rule ID mappings and project-specific code patterns.

---

## How This File Is Used

When any ticket touches markup, CSS, or JavaScript:

```
1. Read this file BEFORE writing any code
2. Match your scenario to the relevant section below
3. Apply the fix pattern exactly as shown
4. Run the Pre-Push Checklist (Section — Project Accessibility Checklist) before marking done
5. If your scenario has no matching pattern → FLAG to user; do not guess
```

---

## Project — Mandatory Accessibility Rules

These rules are **non-negotiable** for every UI change in this project.

{{STACK_CHECKLIST}}

> `{{STACK_CHECKLIST}}` is populated per-project from `stacks/<stack>/notes.md` with the stack's
> own markup/templating-helper patterns (e.g. framework label/form helper equivalents of
> `Html.cLabelFor`, validation-summary and hidden-field conventions, screen-reader-announcement
> functions, modal/dialog patterns, skip-link markup), JavaScript accessibility conventions, and
> CSS/theme rules (inline-style policy, custom CSS file location, theme-folder propagation rules,
> high-contrast/greyscale theme handling, focus-outline conventions) — do not hardcode any single
> stack's helpers or theme system in this `core/` file.

### Pre-Push Accessibility Checklist

```
[ ] All decorative icons hidden from assistive tech (e.g. aria-hidden="true")
[ ] All icon-only buttons have an accessible name (aria-label or sr-only text)
[ ] All form fields have an associated, visible label
[ ] Required fields have a sr-only "(required)" indicator
[ ] Validation summary / error region present on all forms
[ ] Keyboard navigation tested (Tab / Shift+Tab / Enter / Escape)
[ ] Focus not lost after any dynamic interaction
[ ] Modal: focus moves in on open, returns to trigger on close
[ ] AJAX/dynamic results announced via aria-live or role="alert"
[ ] NO inline styles used (all styling via CSS classes per project convention)
[ ] CSS changes applied to {{THEME_FOLDERS}} if color/appearance related
[ ] Layout-only CSS (margin/padding/width) added to the base/shared theme only
[ ] Focus outline not removed in new CSS
[ ] No color used as the only way to convey information
[ ] Tested with a screen reader (e.g. NVDA) + a current browser (if UI changed)
```

---

## Criterion Sprint Execution

Use this header as the operating contract for criterion-by-criterion remediation.

### Sprint Start

1. Select one active WCAG criterion (`active_criterion`), for example `1.1.1`.
2. Use full-application scope by default unless the user explicitly narrows it.
3. Build findings from imported results (if provided) and autonomous discovery.

### Sprint Order (Must Follow)

1. Detect findings mapped to `active_criterion`.
2. Apply fixes using priority order: `custom-fixes.md` -> scanner suggestion -> this file's fix pattern.
3. Verify and summarize fixed/skipped/deferred/manual-review counts for `active_criterion`.
4. Present review summary and pause for explicit approval.
5. Only after approval: commit/push/PR for that criterion cycle.

### Stop Gate

Do not start the next criterion automatically. Always ask:

`[Review] Continue with next WCAG criterion: <next-sc>? (yes/no)`

### Criterion Completion Rule

Mark criterion complete only when all are true:

1. Detection for the active criterion has run.
2. Fixes are applied or clearly marked manual-review.
3. Verification summary is produced.
4. Review decision is captured.

---

### Criterion Queue — Dependency-Safe Execution Order

> **MUST use this order when building `criterion_queue`.** Do NOT use simple numeric order.
> Each tier depends on all previous tiers being stable before changes are applied.
> Skip any criterion for which no violations were found — do not pad the queue.

| Position | Criterion | Reason fixing earlier prevents conflicts later |
|----------|-----------|------------------------------------------------|
| **Tier 1 — Foundation (IDs & Language)** | | |
| 1 | **4.1.1** | Duplicate IDs break every `aria-describedby`, `for=`, `aria-labelledby`, `aria-controls` reference added in later criteria |
| 2 | **3.1.1** | `lang` must be stable before screen-reader behaviour is verified for any subsequent fix |
| 3 | **3.1.2** | Per-element `lang` overrides — stabilise before touching multilingual content |
| **Tier 2 — Structure & Sequence** | | |
| 4 | **1.3.1** | Landmark regions and heading structure — the skeletal DOM all later fixes hang off |
| 5 | **1.3.2** | DOM reading order — reordering HTML now prevents CSS reflow fixes (1.4.10) needing to be redone |
| 6 | **1.3.3** | Remove sensory-only instructions — no code dependencies, belongs with structural clarifications |
| 7 | **1.3.4** | Orientation lock — CSS-only, isolated, safe here |
| 8 | **1.3.5** | Autocomplete attributes — form field additions that must precede label and ARIA name fixes |
| **Tier 3 — Non-Text Content** | | |
| 9 | **1.4.5** | Decide which images to delete (images of text) BEFORE adding alt text in 1.1.1 — avoids double work |
| 10 | **1.1.1** | Alt text, role=img, SVG titles — safe now that images-of-text decisions are made |
| **Tier 4 — Names, Roles & ARIA** | | |
| 11 | **4.1.2** | Accessible names, ARIA roles, valid attributes — depends on stable IDs (4.1.1) and structure (1.3.1) |
| 12 | **2.4.2** | Page titles — isolated, safe after structure is stable |
| 13 | **2.4.4** | Link purpose — depends on stable surrounding context and ARIA names |
| 14 | **2.5.3** | Label in name — depends on accessible names being set in 4.1.2 |
| **Tier 5 — Keyboard & Focus** | | |
| 15 | **2.1.1** | All functionality keyboard-operable — must precede focus-order checks |
| 16 | **2.1.2** | No keyboard trap — `role="dialog"` must already exist from 4.1.2 before adding focus trap logic |
| 17 | **2.1.4** | Character key shortcuts — depends on keyboard interactions being stable |
| 18 | **2.4.3** | Focus order — tabindex corrections after keyboard operability is confirmed |
| 19 | **2.4.7** | Focus visible — add indicator before checking it is not obscured |
| 20 | **2.4.11** | Focus not obscured — can only verify after 2.4.7 indicator exists |
| **Tier 6 — Forms & Error Handling** | | |
| 21 | **3.3.2** | Labels and instructions — must be stable before error messages reference field IDs |
| 22 | **3.3.1** | Error identification — uses `aria-describedby` pointing to field IDs set in 3.3.2 |
| 23 | **3.3.3** | Error suggestion — builds on error identification text from 3.3.1 |
| 24 | **3.3.4** | Error prevention — confirmation/review steps depend on stable form labels and errors |
| 25 | **3.2.1** | On focus — no context change; safe after form interactions are stable |
| 26 | **3.2.2** | On input — no context change on select/checkbox; safe after form labels are stable |
| **Tier 7 — Visual & CSS** | | |
| 27 | **1.4.4** | Resize text — `meta viewport` fix; isolated |
| 28 | **1.4.10** | Reflow at 320px — fluid CSS; apply after DOM order (1.3.2) is finalised |
| 29 | **1.4.11** | Non-text contrast — UI component borders/icons; isolated CSS |
| 30 | **1.4.12** | Text spacing — inline style overrides; isolated |
| 31 | **1.4.13** | Content on hover/focus — tooltip/overlay CSS; safe after ARIA names are stable |
| **Tier 8 — Navigation & Cross-Page Consistency** | | |
| 32 | **2.4.1** | Skip links and bypass blocks — depends on stable landmark structure from 1.3.1 |
| 33 | **2.4.5** | Multiple ways — site-level navigation check; safe after individual pages are stable |
| 34 | **2.4.6** | Headings and labels descriptive — rename headings after order (1.3.1) is fixed |
| 35 | **2.5.1** | Pointer gestures — add button alternatives; isolated |
| 36 | **2.5.2** | Pointer cancellation — replace mousedown with click; isolated |
| 37 | **2.5.4** | Motion actuation — add UI alternatives; isolated |
| 38 | **2.5.7** | Dragging movements — add single-pointer alternative; isolated |
| 39 | **2.5.8** | Target size — CSS padding increases; safe after layout is stable |
| 40 | **3.2.3** | Consistent navigation — verify shared layout partial after individual pages stabilise |
| 41 | **3.2.4** | Consistent identification — cross-page label audit after each page is fixed |
| 42 | **3.2.6** | Consistent help — help mechanism placement; depends on stable navigation (3.2.3) |
| **Tier 9 — Media** | | |
| 43 | **1.2.1** | Audio/video text alternatives — isolated asset additions |
| 44 | **1.2.2** | Captions pre-recorded — isolated track additions |
| 45 | **1.2.3** | Audio description pre-recorded — isolated track/description additions |
| 46 | **1.2.4** | Captions live — isolated live track setup |
| 47 | **1.2.5** | Audio description pre-recorded (extended) — isolated |
| **Tier 10 — Timing & Motion** | | |
| 48 | **2.2.1** | Timing adjustable — session timeout controls; isolated |
| 49 | **2.2.2** | Pause/stop/hide — blink/marquee removal; isolated |
| 50 | **2.3.1** | Three flashes — animation/strobe CSS; isolated |
| **Tier 11 — WCAG 2.2 Additions & Status** | | |
| 51 | **3.3.7** | Redundant entry — auto-fill across multi-step forms; depends on stable form fields from Tier 6 |
| 52 | **3.3.8** | Accessible authentication — cognitive test alternatives; depends on stable form labels |
| 53 | **3.3.9** | Accessible authentication (no exception) — stricter variant; same dependencies as 3.3.8 |
| 54 | **4.1.3** | Status messages — `role="status"` / `role="alert"` on dynamic messages; depends on stable ARIA layer |

> **Rule:** If only a subset of criteria has violations, keep the relative order above — skip criteria with zero findings.

---

## Quick Reference: Rule ID to Fix Pattern

Use this table to jump from a BrowserStack / axe-core rule ID to the correct fix pattern.

| Rule ID | WCAG SC | Section | Impact |
|---------|---------|---------|--------|
| `image-alt` | 1.1.1 | [Images](#images-wcag-111) | Critical |
| `input-image-alt` | 1.1.1 | [Images](#images-wcag-111) | Critical |
| `role-img-alt` | 1.1.1 | [Images](#images-wcag-111) | Serious |
| `svg-img-alt` | 1.1.1 | [Images](#images-wcag-111) | Serious |
| `object-alt` | 1.1.1 | [Images](#images-wcag-111) | Serious |
| `area-alt` | 1.1.1 | [Images](#images-wcag-111) | Critical |
| `aria-meter-name` | 1.1.1 | [Images](#images-wcag-111) | Serious |
| `aria-progressbar-name` | 1.1.1 | [Images](#images-wcag-111) | Serious |
| `color-contrast` | 1.4.3 | [Color Contrast](#color-contrast-wcag-143--146--1411) | Serious |
| `color-contrast-enhanced` | 1.4.6 | [Color Contrast](#color-contrast-wcag-143--146--1411) | Serious |
| `link-in-text-block` | 1.4.1 | [Color Contrast](#color-contrast-wcag-143--146--1411) | Serious |
| `meta-viewport` | 1.4.4 | [Text & Typography](#text--typography-wcag-144-1410-1412) | Critical |
| `avoid-inline-spacing` | 1.4.12 | [Text & Typography](#text--typography-wcag-144-1410-1412) | Serious |
| `css-orientation-lock` | 1.3.4 | [Orientation & Input Purpose](#orientation--input-purpose-wcag-134-135) | Serious |
| `autocomplete-valid` | 1.3.5 | [Orientation & Input Purpose](#orientation--input-purpose-wcag-134-135) | Serious |
| `label` | 4.1.2 | [Forms](#forms-wcag-131-332-412) | Critical |
| `select-name` | 4.1.2 | [Forms](#forms-wcag-131-332-412) | Critical |
| `form-field-multiple-labels` | 3.3.2 | [Forms](#forms-wcag-131-332-412) | Moderate |
| `label-title-only` | 4.1.2 | [Forms](#forms-wcag-131-332-412) | Serious |
| `input-button-name` | 4.1.2 | [Forms](#forms-wcag-131-332-412) | Critical |
| `scrollable-region-focusable` | 2.1.1 | [Keyboard Accessibility](#keyboard-accessibility-wcag-211-212-247) | Moderate |
| `frame-focusable-content` | 2.1.1 | [Keyboard Accessibility](#keyboard-accessibility-wcag-211-212-247) | Serious |
| `nested-interactive` | 4.1.2 | [Keyboard Accessibility](#keyboard-accessibility-wcag-211-212-247) | Serious |
| `tabindex` | 2.4.3 | [Keyboard Accessibility](#keyboard-accessibility-wcag-211-212-247) | Serious |
| `bypass` | 2.4.1 | [Keyboard Accessibility](#keyboard-accessibility-wcag-211-212-247) | Serious |
| `skip-link` | 2.4.1 | [Keyboard Accessibility](#keyboard-accessibility-wcag-211-212-247) | Moderate |
| `heading-order` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `empty-heading` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Minor |
| `p-as-heading` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Serious |
| `page-has-heading-one` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `region` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `landmark-one-main` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `landmark-banner-is-top-level` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `landmark-contentinfo-is-top-level` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `landmark-main-is-top-level` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `landmark-no-duplicate-banner` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `landmark-no-duplicate-contentinfo` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `landmark-no-duplicate-main` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `landmark-unique` | 1.3.1 | [Headings & Structure](#headings--structure-wcag-131-246) | Moderate |
| `link-name` | 2.4.4 | [Links & Buttons](#links--buttons-wcag-244-412) | Serious |
| `button-name` | 4.1.2 | [Links & Buttons](#links--buttons-wcag-244-412) | Critical |
| `aria-command-name` | 4.1.2 | [Links & Buttons](#links--buttons-wcag-244-412) | Serious |
| `document-title` | 2.4.2 | [Links & Buttons](#links--buttons-wcag-244-412) | Serious |
| `duplicate-id` | 4.1.1 | [ARIA](#aria-wcag-412) | Minor |
| `duplicate-id-active` | 4.1.1 | [ARIA](#aria-wcag-412) | Serious |
| `duplicate-id-aria` | 4.1.1 | [ARIA](#aria-wcag-412) | Critical |
| `aria-allowed-attr` | 4.1.2 | [ARIA](#aria-wcag-412) | Critical |
| `aria-required-attr` | 4.1.2 | [ARIA](#aria-wcag-412) | Critical |
| `aria-required-children` | 1.3.1 | [ARIA](#aria-wcag-412) | Critical |
| `aria-required-parent` | 1.3.1 | [ARIA](#aria-wcag-412) | Critical |
| `aria-roles` | 4.1.2 | [ARIA](#aria-wcag-412) | Critical |
| `aria-valid-attr` | 4.1.2 | [ARIA](#aria-wcag-412) | Critical |
| `aria-valid-attr-value` | 4.1.2 | [ARIA](#aria-wcag-412) | Critical |
| `aria-hidden-body` | 4.1.2 | [ARIA](#aria-wcag-412) | Critical |
| `aria-hidden-focus` | 4.1.2 | [ARIA](#aria-wcag-412) | Serious |
| `aria-input-field-name` | 4.1.2 | [ARIA](#aria-wcag-412) | Serious |
| `aria-toggle-field-name` | 4.1.2 | [ARIA](#aria-wcag-412) | Serious |
| `aria-tooltip-name` | 4.1.2 | [ARIA](#aria-wcag-412) | Serious |
| `aria-dialog-name` | 4.1.2 | [ARIA](#aria-wcag-412) | Serious |
| `aria-treeitem-name` | 4.1.2 | [ARIA](#aria-wcag-412) | Serious |
| `aria-roledescription` | 4.1.2 | [ARIA](#aria-wcag-412) | Serious |
| `aria-allowed-role` | 4.1.2 | [ARIA](#aria-wcag-412) | Minor |
| `aria-text` | 4.1.2 | [ARIA](#aria-wcag-412) | Serious |
| `presentation-role-conflict` | 4.1.2 | [ARIA](#aria-wcag-412) | Minor |
| `definition-list` | 1.3.1 | [Tables & Lists](#tables--lists-wcag-131) | Serious |
| `dlitem` | 1.3.1 | [Tables & Lists](#tables--lists-wcag-131) | Serious |
| `list` | 1.3.1 | [Tables & Lists](#tables--lists-wcag-131) | Serious |
| `listitem` | 1.3.1 | [Tables & Lists](#tables--lists-wcag-131) | Serious |
| `td-headers-attr` | 1.3.1 | [Tables & Lists](#tables--lists-wcag-131) | Serious |
| `th-has-data-cells` | 1.3.1 | [Tables & Lists](#tables--lists-wcag-131) | Serious |
| `scope-attr-valid` | 1.3.1 | [Tables & Lists](#tables--lists-wcag-131) | Critical |
| `table-duplicate-name` | 1.3.1 | [Tables & Lists](#tables--lists-wcag-131) | Minor |
| `table-fake-caption` | 1.3.1 | [Tables & Lists](#tables--lists-wcag-131) | Serious |
| `empty-table-header` | 1.3.1 | [Tables & Lists](#tables--lists-wcag-131) | Minor |
| `html-has-lang` | 3.1.1 | [Language](#language-wcag-311-312) | Serious |
| `html-lang-valid` | 3.1.1 | [Language](#language-wcag-311-312) | Serious |
| `html-xml-lang-mismatch` | 3.1.1 | [Language](#language-wcag-311-312) | Moderate |
| `valid-lang` | 3.1.2 | [Language](#language-wcag-311-312) | Serious |
| `video-caption` | 1.2.2 | [Media](#media-wcag-121---125) | Critical |
| `audio-caption` | 1.2.1 | [Media](#media-wcag-121---125) | Critical |
| `no-autoplay-audio` | 1.4.2 | [Media](#media-wcag-121---125) | Moderate |
| `frame-title` | 4.1.2 | [Frames & Embeds](#frames--embeds-wcag-412) | Serious |
| `frame-title-unique` | 4.1.2 | [Frames & Embeds](#frames--embeds-wcag-412) | Serious |
| `blink` | 2.2.2 | [Timing & Motion](#timing--motion-wcag-221-231) | Serious |
| `marquee` | 2.2.2 | [Timing & Motion](#timing--motion-wcag-221-231) | Serious |
| `meta-refresh` | 2.2.1 | [Timing & Motion](#timing--motion-wcag-221-231) | Critical |
| `target-size` | 2.5.8 | [Target Size & Pointer](#target-size--pointer-wcag-258-257) | Serious |
| `label-content-name-mismatch` | 2.5.3 | [Label in Name](#label-in-name-wcag-253) | Serious |
| `focus-order-semantics` | 2.4.3 | [Focus Management (WCAG 2.2)](#focus-management-wcag-22---2411-2412-2413) | Minor |
| `audio-description` | 1.2.3 | [Media Alternatives](#media-alternatives-wcag-123-125) | Serious |
| `video-description` | 1.2.5 | [Media Alternatives](#media-alternatives-wcag-123-125) | Serious |
| `meaningful-sequence` | 1.3.2 | [Meaningful Sequence & Reflow](#meaningful-sequence--reflow-wcag-132-1410) | Serious |
| `css-reflow` | 1.4.10 | [Meaningful Sequence & Reflow](#meaningful-sequence--reflow-wcag-132-1410) | Serious |
| `images-of-text` | 1.4.5 | [Images of Text](#images-of-text-wcag-145) | Moderate |
| `non-text-contrast` | 1.4.11 | [Non-Text Contrast](#non-text-contrast-wcag-1411) | Serious |
| `focus-visible` | 2.4.7 | [Focus Visible](#focus-visible-wcag-247) | Serious |
| `heading-label-descriptive` | 2.4.6 | [Headings & Labels Descriptive](#headings--labels-descriptive-wcag-246) | Moderate |
| `pointer-gestures` | 2.5.1 | [Pointer Gestures](#pointer-gestures-wcag-251) | Serious |
| `consistent-navigation` | 3.2.3 | [Consistent Navigation & Identification](#consistent-navigation--identification-wcag-323-324) | Moderate |
| `consistent-identification` | 3.2.4 | [Consistent Navigation & Identification](#consistent-navigation--identification-wcag-323-324) | Moderate |
| `error-identification` | 3.3.1 | [Error Identification & Suggestion](#error-identification--suggestion-wcag-331-333) | Serious |
| `error-suggestion` | 3.3.3 | [Error Identification & Suggestion](#error-identification--suggestion-wcag-331-333) | Moderate |
| `content-on-hover-or-focus` | 1.4.13 | [Content on Hover or Focus](#content-on-hover-or-focus-wcag-1413) | Serious |
| `live-caption` | 1.2.4 | [Media](#media-wcag-121---125) | Serious |
| `sensory-characteristics` | 1.3.3 | [Sensory Characteristics](#sensory-characteristics-wcag-133) | Moderate |
| `no-keyboard-trap` | 2.1.2 | [Keyboard Accessibility](#keyboard-accessibility-wcag-211-212-247) | Critical |
| `character-key-shortcuts` | 2.1.4 | [Character Key Shortcuts](#character-key-shortcuts-wcag-214) | Serious |
| `three-flashes` | 2.3.1 | [Timing & Motion](#timing--motion-wcag-221-231) | Critical |
| `multiple-ways` | 2.4.5 | [Multiple Ways](#multiple-ways-wcag-245) | Moderate |
| `focus-not-obscured` | 2.4.11 | [Focus Management (WCAG 2.2)](#focus-management-wcag-22---2411-2412-2413) | Moderate |
| `pointer-cancellation` | 2.5.2 | [Pointer Cancellation](#pointer-cancellation-wcag-252) | Serious |
| `motion-actuation` | 2.5.4 | [Motion Actuation](#motion-actuation-wcag-254) | Serious |
| `dragging-movements` | 2.5.7 | [Target Size & Pointer](#target-size--pointer-wcag-258-257) | Serious |
| `on-focus` | 3.2.1 | [On Focus & On Input](#on-focus--on-input-wcag-321-322) | Critical |
| `on-input` | 3.2.2 | [On Focus & On Input](#on-focus--on-input-wcag-321-322) | Serious |
| `error-prevention` | 3.3.4 | [Forms](#forms-wcag-131-332-412) | Moderate |
| `redundant-entry` | 3.3.7 | [Redundant Entry](#redundant-entry-wcag-337--level-a-wcag-22) | Moderate |
| `consistent-help` | 3.2.6 | [Consistent Help](#consistent-help-wcag-326--level-a-wcag-22) | Moderate |
| `status-messages` | 4.1.3 | [Status Messages](#status-messages-wcag-413) | Moderate |

---

## Autonomous Detection Checklist (Per Rule ID)

Use this section when no external report is provided, or when validating imported findings.
The goal is deterministic, repeatable discovery before applying fixes.

### Global Discovery Rules

1. Scan in stable path order (alphabetical, recursive).
2. Include UI files: `.html` `.htm` `.jsx` `.tsx` `.vue` `.svelte` `.astro` `.cshtml` `.php` `.erb` `.ejs` `.hbs` `.pug`.
3. Run checks in rule-id order (lexicographic), then sort findings by file path and line.
4. De-duplicate findings by key: `rule_id + file_path + normalized_selector`.
5. Exclude contrast rules from enforcement in this workflow:
   `color-contrast`, `color-contrast-enhanced`, `non-text-contrast`, `link-in-text-block`.
6. For each finding, record evidence in the schema below.

### Evidence Schema (Required)

Each detected issue must include:

```json
{
  "rule_id": "image-alt",
  "wcag_sc": "1.1.1",
  "file_path": "src/views/home.cshtml",
  "line": 42,
  "selector_or_snippet": "<img src=\"hero.png\">",
  "severity": "Critical",
  "detection_reason": "img element missing alt attribute",
  "excluded": false
}
```

### Checklist Template (Apply Per Rule ID)

For each rule, execute in this order:

1. Match condition: exact structural condition below.
2. Exclusions: skip if any exclusion condition matches.
3. Record evidence using required schema.
4. Map to WCAG SC using the quick reference table above.
5. Route to corresponding fix section in this document.

### Rule-Level Detection Checklist

#### 1) `image-alt` (WCAG 1.1.1)

- Match:
  - `<img>` without `alt` attribute.
  - `<img alt>` present but empty where image is not decorative.
- Exclude:
  - Explicit decorative intent: `alt=""` with `role="presentation"` or `aria-hidden="true"`.
- Evidence reason examples:
  - `img element missing alt attribute`
  - `informative img has empty alt`

#### 2) `input-image-alt` (WCAG 1.1.1)

- Match:
  - `<input type="image">` missing `alt`.
  - `<input type="image" alt="">` where control is actionable.
- Exclude:
  - None by default (image inputs are interactive; require a name).

#### 3) `svg-img-alt` and `role-img-alt` (WCAG 1.1.1)

- Match:
  - `<svg>` used as meaningful image without `aria-label`, `aria-labelledby`, or `<title>`.
  - Elements with `role="img"` missing accessible name.
- Exclude:
  - Decorative SVG explicitly hidden from assistive tech (`aria-hidden="true"`).

#### 4) `button-name` (WCAG 4.1.2)

- Match:
  - `<button>` with no discernible text and no `aria-label`/`aria-labelledby`.
  - Icon-only button where icon has no accessible button name source.
- Exclude:
  - Disabled buttons are not excluded; still require an accessible name.

#### 5) `link-name` (WCAG 2.4.4)

- Match:
  - `<a>` with empty/whitespace text and no accessible name.
  - Repeated generic text like `click here` without context (flag as candidate).
- Exclude:
  - Anchors used only as named targets without interactive navigation intent.

#### 6) `label`, `select-name`, `input-button-name` (WCAG 4.1.2)

- Match:
  - Form controls (`input`, `select`, `textarea`) without associated `<label>` and no `aria-label`/`aria-labelledby`.
  - `<input type="button|submit|reset">` without `value`, `aria-label`, or `aria-labelledby`.
- Exclude:
  - Hidden controls (`type="hidden"`) from label checks.

#### 7) `heading-order`, `page-has-heading-one`, `empty-heading` (WCAG 1.3.1)

- Match:
  - Heading levels skipped (e.g., `h2` followed by `h4` without structural reason).
  - No `h1` in primary page template/view.
  - Empty heading text after trimming whitespace.
- Exclude:
  - Component partials that intentionally omit `h1`; mark as `needs-layout-context` instead of auto-fail.

#### 8) Landmark rules (`region`, `landmark-one-main`, `landmark-unique`, related)

- Match:
  - Missing `<main>` or multiple non-unique landmark roles.
  - Duplicate `banner`, `contentinfo`, or `main` landmarks at top level.
- Exclude:
  - Nested landmark duplicates within embedded/isolated application shells where context is explicit.

#### 9) ARIA validity rules (`aria-valid-attr`, `aria-required-attr`, `aria-roles`, etc.)

- Match:
  - Unsupported `aria-*` attribute for role.
  - Missing required ARIA attributes for role.
  - Invalid role names or invalid ARIA values.
- Exclude:
  - None unless role/attribute is dynamically injected at runtime and cannot be resolved statically.
  - Mark unresolved dynamic cases as `manual-review`.

#### 10) `html-has-lang`, `html-lang-valid`, `valid-lang` (WCAG 3.1.1/3.1.2)

- Match:
  - Missing `lang` on root `<html>`.
  - Invalid BCP-47 language tags.
  - Inline language switches without valid `lang` marker.
- Exclude:
  - Server-side templates that inherit root `lang` from master layout; mark partial as `inherited-lang`.

#### 11) Table/list semantics (`list`, `listitem`, `scope-attr-valid`, `td-headers-attr`, etc.)

- Match:
  - `li` outside `ul/ol`.
  - Data tables with missing or invalid `scope`/header associations.
  - Fake captions or duplicate table naming.
- Exclude:
  - Layout tables intentionally non-semantic only when no tabular relationship exists; mark as `layout-table-review`.

#### 12) `document-title` (WCAG 2.4.2)

- Match:
  - Missing `<title>` in page/document head.
  - Placeholder titles (e.g., `Untitled`, `Page`) in routed pages.
- Exclude:
  - Component fragments without document ownership.

#### 13) `audio-description`, `video-description` (WCAG 1.2.3, 1.2.5)

- Match:
  - `<video>` with an audio track and no `<track kind="descriptions">`.
  - `<video>` with no `aria-describedby` pointing to a meaningful text description.
- Exclude:
  - Videos that are purely decorative and have `aria-hidden="true"`.
  - Audio-only content (covered by `audio-caption`, not this rule).
- Evidence reason: `video element has no audio description track or text alternative`

#### 14) `meaningful-sequence` (WCAG 1.3.2)

- Match:
  - DOM order differs from visual reading order due to CSS `float`, `position: absolute`, or negative `order` values in flex/grid.
  - Content only reads correctly when CSS is applied (e.g., sidebar floated before main content in DOM).
- Exclude:
  - CSS `order` changes that are purely decorative (e.g., reversing icon position within a button) and do not affect reading comprehension.
- Evidence reason: `DOM order does not match visual reading sequence`

#### 15) `css-reflow` (WCAG 1.4.10)

- Match:
  - Fixed-width containers (`width: Xpx`) wider than 320px on body, main, or primary content wrappers.
  - `overflow: hidden` or `overflow: scroll` on body or main layout at narrow widths.
  - `white-space: nowrap` on block-level content containers.
- Exclude:
  - Data tables (horizontal scroll is allowed for complex data tables).
  - Map embeds and fixed-dimension media where two-dimensional layout is essential.
- Evidence reason: `fixed-width container prevents reflow at 320px`

#### 16) `images-of-text` (WCAG 1.4.5)

- Match:
  - `<img>` where `alt` text is a full sentence or heading that could be rendered as styled real text.
  - Background images used to display heading or label text.
- Exclude:
  - Logos and brand marks.
  - Charts, graphs, and diagrams where the image conveys data.
- Evidence reason: `text content presented as image instead of styled real text`

#### 17) `non-text-contrast` (WCAG 1.4.11)

- Match:
  - Form input borders with contrast ratio below 3:1 against background.
  - Checkbox, radio, and toggle outlines with contrast below 3:1.
  - Icon colours below 3:1 against their adjacent background.
- Exclude:
  - Disabled controls (explicitly excluded by WCAG).
  - Decorative icons with `aria-hidden="true"`.
- Evidence reason: `UI component boundary or icon has insufficient contrast (< 3:1)`

#### 18) `focus-visible` (WCAG 2.4.7)

- Match:
  - Global `outline: none` or `outline: 0` on `*`, `:focus`, or `:focus-visible` without a replacement focus style.
  - Interactive elements (`a`, `button`, `input`, `select`, `textarea`) with no visible focus indicator.
- Exclude:
  - Elements where a custom focus style is explicitly provided that meets 3:1 contrast.
- Evidence reason: `focus indicator removed or not visible on interactive element`

#### 19) `heading-label-descriptive` (WCAG 2.4.6)

- Match:
  - Heading text is one of: `Section`, `Details`, `Information`, `Item`, `Field`, `Part`, a lone number.
  - Label text is one of: `Field`, `Input`, `Value`, `Text`, or is empty after trimming.
- Exclude:
  - Headings confirmed to be intentionally abstract for design reasons — mark as `manual-review`.
- Evidence reason: `heading or label text is not descriptive`

#### 20) `pointer-gestures` (WCAG 2.5.1)

- Match:
  - Elements with only `touchstart`/`touchmove`/`touchend` event listeners and no click or keyboard alternative.
  - Carousel/slider/map components with touch-swipe only and no button controls.
- Exclude:
  - Native `<input type="range">` (browser handles alternative input).
- Evidence reason: `functionality only accessible via multi-point or path gesture`

#### 21) `consistent-navigation`, `consistent-identification` (WCAG 3.2.3, 3.2.4)

- Match:
  - Navigation partial used on some pages but not others.
  - Same functional element (e.g., search field, logout button) labelled differently across pages.
- Exclude:
  - Intentional per-page navigation variations (e.g., wizard step navigation vs. global nav).
- Evidence reason: `navigation order or component identification inconsistent across pages`

#### 22) `error-identification`, `error-suggestion` (WCAG 3.3.1, 3.3.3)

- Match:
  - Form fields with visual error state (red border, error class) but no associated text description.
  - Inline error messages not linked to the field via `aria-describedby` or `aria-errormessage`.
  - Error text that only says "invalid" or "required" without a correction suggestion.
- Exclude:
  - Password fields — do not require suggestion to avoid security risk.
  - CAPTCHA errors — no suggestion required.
- Evidence reason: `error state has no text identification` / `error message lacks correction suggestion`

#### 23) `live-caption` (WCAG 1.2.4)

- Match:
  - `<video>` or `<audio>` elements used for live streaming (src contains `live`, `.m3u8`, `stream`) without a live `<track kind="captions">`.
  - Live stream embeds with no caption toggle control or external captioning service link.
- Exclude:
  - Pre-recorded video/audio (covered by 1.2.2, not 1.2.4).
  - Video/audio that is purely decorative with `aria-hidden="true"`.
- Evidence reason: `live media has no real-time captions`

#### 24) `sensory-characteristics` (WCAG 1.3.3)

- Match:
  - Instructional text containing `round`, `square`, `triangle`, `red`, `green`, `blue`, `left side`, `right side`, `above`, `below`, `larger`, `smaller`, `bright` without a co-located non-sensory label or name.
  - Error or validation messages that reference colour only (`highlighted in red`, `marked in green`).
- Exclude:
  - Decorative or marketing copy that does not instruct the user how to complete a task.
- Evidence reason: `instruction relies solely on sensory characteristic`

#### 25) `no-keyboard-trap` (WCAG 2.1.2)

- Match:
  - Modal dialogs or overlays without a focus-trap loop and Escape key handler.
  - Custom widgets that move focus in but provide no keyboard route out.
- Exclude:
  - Modals with correct ARIA `role="dialog"` + focus trap + Escape dismissal.
- Evidence reason: `keyboard focus cannot escape the component`

#### 26) `character-key-shortcuts` (WCAG 2.1.4)

- Match:
  - `keydown`/`keyup`/`keypress` handlers bound to single printable characters (letters a-z, numbers 0-9, punctuation) on the `document` or `window` without a modifier key check (`ctrlKey`, `altKey`, `metaKey`, `shiftKey`).
- Exclude:
  - Shortcuts scoped to a component's `focusin` context (only active when element has focus).
  - Shortcuts that have a UI toggle to disable them.
- Evidence reason: `single-character global shortcut with no modifier or disable option`

#### 27) `three-flashes` (WCAG 2.3.1)

- Match:
  - CSS animations or JS intervals that flash, strobe, or rapidly change contrast 3 or more times per second.
  - `@keyframes` with alternating high/low contrast states with animation-duration below 333ms per cycle.
- Exclude:
  - Animations with `prefers-reduced-motion` that disable or reduce the flash below the threshold.
  - Flashing that is confined to a region smaller than 341 × 256 px.
- Evidence reason: `content flashes more than 3 times per second`

#### 28) `multiple-ways` (WCAG 2.4.5)

- Match:
  - Pages that are only reachable via a single navigation path and have no search or sitemap.
  - Application sections with no navigation links and no breadcrumb to reach them from elsewhere.
- Exclude:
  - Wizard or process steps (form step 2 of 3) — exempt by WCAG definition.
- Evidence reason: `page reachable by only one navigation method`

#### 29) `pointer-cancellation` (WCAG 2.5.2)

- Match:
  - `mousedown` or `pointerdown` handlers on buttons, links, or interactive elements that trigger irreversible actions without a corresponding `mouseup`/`click` override or undo mechanism.
  - `touchstart` handlers on interactive elements performing navigation or data changes immediately.
- Exclude:
  - Down-event triggering that is essential (e.g., piano-key UI where sound plays on keydown intentionally).
- Evidence reason: `destructive action triggered on down-event with no cancel or undo`

#### 30) `motion-actuation` (WCAG 2.5.4)

- Match:
  - `devicemotion`, `deviceorientation`, or `gyroscope` API calls tied to application features without a corresponding button/control alternative.
  - No option in the UI to disable motion-triggered actions.
- Exclude:
  - Pure browser-level motion handling (e.g., scroll via trackpad) not authored by the app.
- Evidence reason: `feature requires device motion with no UI alternative or disable option`

#### 31) `on-focus`, `on-input` (WCAG 3.2.1, 3.2.2)

- Match:
  - `onfocus` or `focus` event handlers that trigger `window.location` change, form submission, or modal open.
  - `onchange` handlers on `<select>` or `<input>` that navigate to a new page or submit a form without prior user warning.
- Exclude:
  - Inline form validation (showing/hiding error text) — does not change context.
  - Filter lists that update results in the same page when the user has been warned in adjacent text.
- Evidence reason: `context changes automatically on focus or input without user action`

#### 32) `status-messages` (WCAG 4.1.3)

- Match:
  - Dynamic status messages injected into the DOM via JS (success banners, toast notifications, form save confirmations, search result counts) without `role="status"`, `role="alert"`, or an `aria-live` region.
  - Loading indicators that appear/disappear without any live region announcement.
- Exclude:
  - Messages that receive programmatic focus (they are announced via focus, not live region).
  - Static server-rendered messages present on initial page load.
- Evidence reason: `status message injected without aria-live or role=status/alert`

### Deterministic Discovery Output

After scanning, generate:

1. `rule_id` grouped counts.
2. `wcag_sc` grouped counts.
3. `manual-review` list (dynamic/unresolved cases).
4. `excluded` list (with explicit exclusion reason).

This output becomes the source for criterion queue creation in pattern-sprint mode.

---

## Images (WCAG 1.1.1)

### Missing alt text

**Rule IDs:** `image-alt`, `input-image-alt`

```html
<!-- Before -->
<img src="logo.png">

<!-- Fix: Add descriptive alt -->
<img src="logo.png" alt="Company logo">

<!-- Decorative image: use empty alt -->
<img src="divider.png" alt="" role="presentation">
```

### Informative SVG missing accessible name

**Rule IDs:** `svg-img-alt`

```html
<!-- Before -->
<svg>...</svg>

<!-- Fix -->
<svg role="img" aria-label="Sales trend chart">...</svg>

<!-- Or with title element -->
<svg role="img" aria-labelledby="svg-title">
  <title id="svg-title">Sales trend chart</title>
  ...
</svg>
```

### Icon buttons without labels

**Rule IDs:** `button-name`

```html
<!-- Before -->
<button><img src="search.svg"></button>

<!-- Fix -->
<button aria-label="Search"><img src="search.svg" alt=""></button>
```

### Object elements missing alt

**Rule IDs:** `object-alt`

```html
<!-- Before -->
<object data="chart.swf" type="application/x-shockwave-flash"></object>

<!-- Fix -->
<object data="chart.swf" type="application/x-shockwave-flash">
  <p>Quarterly sales chart showing 15% growth</p>
</object>
```

### Image map areas

**Rule IDs:** `area-alt`

```html
<map name="infographic">
  <area shape="rect" coords="0,0,100,100" href="/sales" alt="Sales data">
  <area shape="rect" coords="100,0,200,100" href="/revenue" alt="Revenue data">
</map>
```

### Elements with role="img"

**Rule IDs:** `role-img-alt`

```html
<!-- Before -->
<div role="img" style="background-image: url(chart.png)"></div>

<!-- Fix -->
<div role="img" aria-label="Bar chart showing monthly revenue" style="background-image: url(chart.png)"></div>
```

### Meter and progressbar names

**Rule IDs:** `aria-meter-name`, `aria-progressbar-name`

```html
<div role="meter" aria-label="Storage used" aria-valuenow="75" aria-valuemin="0" aria-valuemax="100">75%</div>
<div role="progressbar" aria-label="Upload progress" aria-valuenow="40" aria-valuemin="0" aria-valuemax="100">40%</div>
```

---

## Color Contrast (WCAG 1.4.3 / 1.4.6 / 1.4.11)

**Required ratios:**
- Normal text (< 18pt / < 14pt bold): **4.5:1** (AA) / **7:1** (AAA)
- Large text (>= 18pt / >= 14pt bold): **3:1** (AA) / **4.5:1** (AAA)
- UI components & graphical objects (1.4.11): **3:1**

### Fixing low contrast text

**Rule IDs:** `color-contrast`, `color-contrast-enhanced`

```css
/* Before - fails (e.g., #999 on #fff = 2.85:1) */
.label { color: #999; }

/* Fix - meets 4.5:1 (e.g., #595959 on #fff = 7.08:1) */
.label { color: #595959; }
```

### Contrast-safe color pairs

| Background | Text Color | Ratio | Use For |
|-----------|------------|-------|---------|
| `#ffffff` | `#595959`  | 7.0:1 | Body text |
| `#ffffff` | `#0056b3`  | 7.5:1 | Links |
| `#ffffff` | `#d32f2f`  | 5.6:1 | Error text |
| `#ffffff` | `#2e7d32`  | 5.1:1 | Success text |
| `#ffffff` | `#6d4c00`  | 7.1:1 | Warning text |
| `#1a1a1a` | `#ffffff`  | 16.0:1| Dark mode body |
| `#1a1a1a` | `#6db3f2`  | 6.5:1 | Dark mode links |
| `#1a1a1a` | `#ff8a80`  | 5.0:1 | Dark mode error |
| `#1a1a1a` | `#69f0ae`  | 8.4:1 | Dark mode success |

### Non-text contrast (WCAG 1.4.11)

UI components and meaningful graphics must have at least **3:1** contrast against adjacent colors.

```css
/* Before - border too faint */
.input-field { border: 1px solid #ddd; }

/* Fix - meets 3:1 against white background */
.input-field { border: 1px solid #767676; }

/* Before - icon too low contrast */
.icon { color: #ccc; }

/* Fix */
.icon { color: #767676; }
```

### Links distinguished from surrounding text

**Rule IDs:** `link-in-text-block`

```css
/* Links must be distinguishable by more than color alone */
a {
  color: #0056b3;
  text-decoration: underline;
}

/* If underline removed, use another non-color cue plus 3:1 contrast with surrounding text */
a {
  color: #0056b3;
  text-decoration: none;
  border-bottom: 1px solid currentColor;
}
```

---

## Text & Typography (WCAG 1.4.4, 1.4.10, 1.4.12)

### Resize text (1.4.4) — do not disable zoom

**Rule IDs:** `meta-viewport`

```html
<!-- BAD — disables zoom -->
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">

<!-- Fix — allow zoom -->
<meta name="viewport" content="width=device-width, initial-scale=1">
```

### Reflow (1.4.10) — no horizontal scrolling at 320 CSS px

Content must reflow to 320 CSS px width (equivalent to 400% zoom at 1280 px) without requiring horizontal scrolling.

```css
/* Use fluid layout */
.container {
  max-width: 100%;
  padding: 0 1rem;
}

/* Avoid fixed widths */
.card {
  width: 100%;
  max-width: 40rem;
}

/* Use responsive images */
img {
  max-width: 100%;
  height: auto;
}
```

### Text spacing (1.4.12) — do not break when overridden

**Rule IDs:** `avoid-inline-spacing`

Content must remain readable when users override text spacing to:
- Line height >= 1.5x font size
- Letter spacing >= 0.12x font size
- Word spacing >= 0.16x font size
- Paragraph spacing >= 2x font size

```css
/* BAD — inline styles that override user preferences */
/* style="line-height: 1.1 !important" */

/* Fix — use relative units and avoid !important on spacing */
.content {
  line-height: 1.5;
  letter-spacing: normal;
  word-spacing: normal;
}

/* Never set fixed height on text containers */
/* BAD */
.text-box { height: 80px; overflow: hidden; }

/* Fix */
.text-box { min-height: 80px; }
```

---

## Content on Hover or Focus (WCAG 1.4.13)

Popup content triggered by hover or focus must be **dismissible**, **hoverable**, and **persistent**.

```css
/* Tooltip pattern that meets 1.4.13 */
[data-tooltip] {
  position: relative;
}

[data-tooltip]::after {
  content: attr(data-tooltip);
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  padding: 0.5rem 0.75rem;
  background: #1a1a1a;
  color: #fff;
  border-radius: 4px;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.15s;
}

/* Show on hover AND focus */
[data-tooltip]:hover::after,
[data-tooltip]:focus::after {
  opacity: 1;
  pointer-events: auto; /* Allow hovering over the tooltip itself */
}
```

```javascript
// Dismiss on Escape
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    document.querySelectorAll('[data-tooltip-visible]').forEach(el => {
      el.removeAttribute('data-tooltip-visible');
    });
  }
});
```

---

## Orientation & Input Purpose (WCAG 1.3.4, 1.3.5)

### Orientation (1.3.4) — do not lock orientation

**Rule IDs:** `css-orientation-lock`

```css
/* BAD — locks to portrait */
@media (orientation: portrait) {
  .app { display: block; }
}
@media (orientation: landscape) {
  .app { display: none; }
}

/* Fix — adapt layout, never hide */
@media (orientation: portrait) {
  .grid { grid-template-columns: 1fr; }
}
@media (orientation: landscape) {
  .grid { grid-template-columns: 1fr 1fr; }
}
```

### Input purpose / autocomplete (1.3.5)

**Rule IDs:** `autocomplete-valid`

Use standard `autocomplete` values for identity-related fields so browsers and assistive tech can auto-fill.

```html
<label for="fname">First Name</label>
<input type="text" id="fname" autocomplete="given-name">

<label for="lname">Last Name</label>
<input type="text" id="lname" autocomplete="family-name">

<label for="email">Email</label>
<input type="email" id="email" autocomplete="email">

<label for="tel">Phone</label>
<input type="tel" id="tel" autocomplete="tel">

<label for="address">Street Address</label>
<input type="text" id="address" autocomplete="street-address">

<label for="cc">Credit Card Number</label>
<input type="text" id="cc" autocomplete="cc-number">

<label for="bday">Birthday</label>
<input type="date" id="bday" autocomplete="bday">

<label for="newpw">New Password</label>
<input type="password" id="newpw" autocomplete="new-password">
```

**Common autocomplete tokens:** `name`, `given-name`, `family-name`, `email`, `tel`, `street-address`,
`address-line1`, `address-line2`, `address-level2` (city), `address-level1` (state), `postal-code`,
`country`, `cc-name`, `cc-number`, `cc-exp`, `cc-csc`, `bday`, `sex`, `username`, `new-password`,
`current-password`, `organization`, `url`.

---

## Forms (WCAG 1.3.1, 3.3.2, 4.1.2)

### Input without label

**Rule IDs:** `label`, `label-title-only`

```html
<!-- Before -->
<input type="email" placeholder="Email">

<!-- Fix option 1: Visible label (preferred) -->
<label for="email">Email</label>
<input type="email" id="email" placeholder="e.g. user@example.com">

<!-- Fix option 2: aria-label (when visible label not feasible) -->
<input type="email" aria-label="Email address" placeholder="Email">

<!-- Fix option 3: aria-labelledby (reference existing text) -->
<span id="email-label">Email</span>
<input type="email" aria-labelledby="email-label">
```

### Select without label

**Rule IDs:** `select-name`

```html
<!-- Before -->
<select>
  <option>Choose country</option>
</select>

<!-- Fix -->
<label for="country">Country</label>
<select id="country">
  <option value="">Choose country</option>
</select>
```

### Input button without name

**Rule IDs:** `input-button-name`

```html
<!-- Before -->
<input type="submit">

<!-- Fix -->
<input type="submit" value="Submit Application">
```

### Multiple labels on a field

**Rule IDs:** `form-field-multiple-labels`

```html
<!-- Before — two <label> elements for one input -->
<label for="pw">Password</label>
<label for="pw">Must be 8+ characters</label>
<input type="password" id="pw">

<!-- Fix — single label, use aria-describedby for help text -->
<label for="pw">Password</label>
<input type="password" id="pw" aria-describedby="pw-hint">
<span id="pw-hint">Must be 8+ characters</span>
```

### Missing error identification (WCAG 3.3.1)

```html
<label for="email">Email</label>
<input type="email" id="email" aria-describedby="email-error" aria-invalid="true">
<span id="email-error" role="alert">Please enter a valid email address.</span>
```

### Required fields (WCAG 3.3.2)

```html
<label for="name">Name <span aria-hidden="true">*</span></label>
<input type="text" id="name" required aria-required="true">
```

### Grouped controls (WCAG 1.3.1)

```html
<fieldset>
  <legend>Shipping Method</legend>
  <input type="radio" id="standard" name="shipping" value="standard">
  <label for="standard">Standard (5-7 days)</label>
  <input type="radio" id="express" name="shipping" value="express">
  <label for="express">Express (2-3 days)</label>
</fieldset>
```

### Error suggestions (WCAG 3.3.3)

```html
<label for="date">Date of Birth</label>
<input type="text" id="date" aria-describedby="date-error" aria-invalid="true" value="13/32/1990">
<span id="date-error" role="alert">
  Invalid date. Please use MM/DD/YYYY format (e.g., 01/15/1990).
</span>
```

### Error prevention on legal/financial submissions (WCAG 3.3.4)

```html
<!-- Provide a review step before final submit -->
<section aria-label="Review your order">
  <h2>Review Your Order</h2>
  <dl>
    <dt>Item</dt><dd>Widget Pro</dd>
    <dt>Total</dt><dd>$49.99</dd>
  </dl>
  <button type="button" onclick="goBack()">Edit Order</button>
  <button type="submit">Confirm Purchase</button>
</section>
```

---

## Keyboard Accessibility (WCAG 2.1.1, 2.1.2, 2.4.7)

### Non-interactive element used as button

```html
<!-- Before -->
<div onclick="doAction()">Click me</div>

<!-- Fix -->
<button type="button" onclick="doAction()">Click me</button>

<!-- Or if div must stay -->
<div role="button" tabindex="0"
     onclick="doAction()"
     onkeydown="if(event.key==='Enter'||event.key===' ')doAction()">
  Click me
</div>
```

### Missing focus indicator (WCAG 2.4.7)

```css
/* Never do this without a replacement */
/* BAD: *:focus { outline: none; } */

/* Fix: visible focus style */
:focus-visible {
  outline: 2px solid #0056b3;
  outline-offset: 2px;
}
```

### Focus trap in modal (WCAG 2.1.2)

```javascript
function trapFocus(modal) {
  const focusable = modal.querySelectorAll(
    'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
  );
  const first = focusable[0];
  const last = focusable[focusable.length - 1];

  modal.addEventListener('keydown', (e) => {
    if (e.key !== 'Tab') return;
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault();
      first.focus();
    }
  });
  first.focus();
}
```

### Skip navigation link (WCAG 2.4.1)

**Rule IDs:** `bypass`, `skip-link`

```html
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <nav>...</nav>
  <main id="main-content">...</main>
</body>
```

```css
.skip-link {
  position: absolute;
  left: -9999px;
  top: auto;
  width: 1px;
  height: 1px;
  overflow: hidden;
}
.skip-link:focus {
  position: static;
  width: auto;
  height: auto;
  overflow: visible;
  padding: 8px 16px;
  background: #0056b3;
  color: #fff;
  z-index: 9999;
}
```

### Scrollable region keyboard accessible

**Rule IDs:** `scrollable-region-focusable`

```html
<!-- Before — scrollable but not keyboard accessible -->
<div style="overflow: auto; height: 200px;">
  <p>Long content...</p>
</div>

<!-- Fix — add tabindex and accessible label -->
<div tabindex="0" role="region" aria-label="Scrollable content" style="overflow: auto; height: 200px;">
  <p>Long content...</p>
</div>
```

### No nested interactive elements

**Rule IDs:** `nested-interactive`

```html
<!-- BAD — button inside a link -->
<a href="/page"><button>Click</button></a>

<!-- Fix — choose one interactive element -->
<a href="/page" class="btn-styled">Click</a>
```

### Positive tabindex

**Rule IDs:** `tabindex`

```html
<!-- BAD — manually ordering focus -->
<input tabindex="3"> <input tabindex="1"> <input tabindex="2">

<!-- Fix — use tabindex="0" and rely on DOM order -->
<input tabindex="0"> <input tabindex="0"> <input tabindex="0">
```

---

## Focus Management (WCAG 2.2 — 2.4.11, 2.4.12, 2.4.13)

### Focus Not Obscured — Minimum (2.4.11 — Level AA)

The focused element must not be fully hidden by author-created content such as sticky headers,
footers, banners, or overlapping panels.

```css
/* Ensure focused elements aren't hidden behind sticky headers */
:focus-visible {
  scroll-margin-top: 80px; /* Height of sticky header */
  scroll-margin-bottom: 60px; /* Height of sticky footer */
}

.sticky-header {
  position: sticky;
  top: 0;
  z-index: 100;
}

/* Account for sticky regions when focus moves */
html {
  scroll-padding-top: 80px;
  scroll-padding-bottom: 60px;
}
```

```javascript
// When opening a panel that might overlap content, manage focus
function openSidePanel() {
  const panel = document.getElementById('side-panel');
  panel.hidden = false;
  const mainContent = document.getElementById('main');
  mainContent.style.marginRight = `${panel.offsetWidth}px`;
}
```

### Focus Not Obscured — Enhanced (2.4.12 — Level AAA)

No part of the focused element can be hidden. Same techniques as above, applied more strictly.

### Focus Appearance (2.4.13 — Level AAA)

Focus indicators must have:
- At least **2 CSS px** thick outline or equivalent area
- At least **3:1** contrast between focused and unfocused states

```css
/* Compliant focus indicator */
:focus-visible {
  outline: 3px solid #0056b3;
  outline-offset: 2px;
}

/* High-contrast focus for dark backgrounds */
.dark-theme :focus-visible {
  outline: 3px solid #ffdd57;
  outline-offset: 2px;
}

/* Alternative: box-shadow (counts toward the area requirement) */
:focus-visible {
  outline: none;
  box-shadow: 0 0 0 3px #0056b3;
}
```

---

## Target Size & Pointer (WCAG 2.5.8, 2.5.7)

### Target size minimum (2.5.8 — Level AA)

**Rule IDs:** `target-size`

All interactive targets must be at least **24 x 24 CSS px**, or have sufficient spacing so that
a 24 px circle centered on each target does not overlap another target.

**Exceptions:** inline links in text, user-agent-controlled elements, essential presentations.

```css
/* Ensure buttons meet minimum target size */
button, a.btn, [role="button"] {
  min-width: 24px;
  min-height: 24px;
  padding: 6px 12px;
}

/* Icon-only buttons need explicit sizing */
.icon-btn {
  min-width: 44px;  /* 44px recommended for touch */
  min-height: 44px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

/* Ensure spacing between small targets */
.button-group button {
  margin: 4px; /* Ensures 24px non-overlap when buttons are small */
}

/* Touch-friendly form controls */
input[type="checkbox"],
input[type="radio"] {
  min-width: 24px;
  min-height: 24px;
}
```

### Dragging movements (2.5.7 — Level AA)

Any operation that uses dragging must also have a single-pointer alternative (no path-based gestures required).

```html
<!-- Sortable list: provide up/down buttons alongside drag handles -->
<ul role="list">
  <li>
    <span class="drag-handle" aria-hidden="true">&#x2630;</span>
    <span>Item 1</span>
    <button aria-label="Move Item 1 up" onclick="moveUp(0)">&#x25B2;</button>
    <button aria-label="Move Item 1 down" onclick="moveDown(0)">&#x25BC;</button>
  </li>
</ul>
```

```html
<!-- Slider: draggable thumb must also respond to click-to-set and arrow keys -->
<input type="range" min="0" max="100" value="50" aria-label="Volume">
```

```html
<!-- Map pan: provide arrow buttons alongside drag -->
<div class="map-controls">
  <button aria-label="Pan left" onclick="panMap('left')">&#x2190;</button>
  <button aria-label="Pan right" onclick="panMap('right')">&#x2192;</button>
  <button aria-label="Pan up" onclick="panMap('up')">&#x2191;</button>
  <button aria-label="Pan down" onclick="panMap('down')">&#x2193;</button>
</div>
```

---

## Label in Name (WCAG 2.5.3)

**Rule IDs:** `label-content-name-mismatch`

The accessible name must contain the visible label text.

```html
<!-- BAD — visible text says "Search" but aria-label says something different -->
<button aria-label="Find products">Search</button>

<!-- Fix — accessible name includes the visible label -->
<button aria-label="Search products">Search</button>

<!-- Or just use the visible text -->
<button>Search</button>
```

---

## Consistent Help (WCAG 3.2.6 — Level A, WCAG 2.2)

Help mechanisms must appear in the same relative order across pages within a set.

```html
<!-- Place help in a consistent location on every page (e.g. footer or header) -->
<footer>
  <nav aria-label="Help">
    <ul>
      <li><a href="/contact">Contact Us</a></li>
      <li><a href="/faq">FAQ</a></li>
      <li><a href="/chat">Live Chat</a></li>
    </ul>
  </nav>
</footer>
```

---

## Redundant Entry (WCAG 3.3.7 — Level A, WCAG 2.2)

Do not require users to re-enter information already provided in the same session,
unless re-entry is essential (e.g. for security confirmation).

```html
<!-- Auto-populate shipping from billing -->
<fieldset>
  <legend>Shipping Address</legend>
  <label>
    <input type="checkbox" id="same-as-billing" onchange="copyBilling()">
    Same as billing address
  </label>
  <label for="ship-street">Street</label>
  <input type="text" id="ship-street" autocomplete="shipping street-address">
</fieldset>
```

```javascript
function copyBilling() {
  if (document.getElementById('same-as-billing').checked) {
    document.getElementById('ship-street').value =
      document.getElementById('bill-street').value;
    // Copy other fields...
  }
}
```

---

## Accessible Authentication (WCAG 3.3.8 / 3.3.9 — WCAG 2.2)

### Minimum (3.3.8 — Level AA)

Do not require cognitive function tests (memorizing passwords, solving puzzles, transcribing text)
unless an alternative is provided.

```html
<!-- Compliant approaches: -->

<!-- 1. Allow password managers (don't block paste) -->
<input type="password" id="password" autocomplete="current-password">

<!-- 2. Allow copy-paste on verification codes -->
<label for="otp">Enter the code sent to your email</label>
<input type="text" id="otp" autocomplete="one-time-code" inputmode="numeric">

<!-- 3. Provide a passwordless alternative -->
<button type="button" onclick="sendMagicLink()">Sign in with email link</button>

<!-- 4. If CAPTCHA is used, provide an audio or other alternative -->
<div class="captcha">
  <img src="captcha.png" alt="Type the characters you see">
  <button type="button" onclick="playAudioCaptcha()">Listen to audio version</button>
</div>
```

### Enhanced (3.3.9 — Level AAA)

No cognitive test at all — only object recognition or personal content identification are allowed.

---

## Headings & Structure (WCAG 1.3.1, 2.4.6)

### Skipped heading levels

**Rule IDs:** `heading-order`

```html
<!-- Before (skips h2) -->
<h1>Page Title</h1>
<h3>Section Title</h3>

<!-- Fix -->
<h1>Page Title</h1>
<h2>Section Title</h2>
```

### Empty heading

**Rule IDs:** `empty-heading`

```html
<!-- Before -->
<h2></h2>

<!-- Fix: add text or remove the empty heading -->
<h2>Section Title</h2>
```

### Styled paragraphs used as headings

**Rule IDs:** `p-as-heading`

```html
<!-- Before -->
<p style="font-size: 24px; font-weight: bold;">Important Section</p>

<!-- Fix -->
<h2>Important Section</h2>
```

### Missing page landmarks

**Rule IDs:** `region`, `landmark-one-main`, `landmark-banner-is-top-level`,
`landmark-contentinfo-is-top-level`, `landmark-main-is-top-level`,
`landmark-no-duplicate-banner`, `landmark-no-duplicate-contentinfo`, `landmark-no-duplicate-main`,
`landmark-unique`

```html
<body>
  <header role="banner">...</header>
  <nav role="navigation" aria-label="Main">...</nav>
  <main role="main">...</main>
  <aside role="complementary" aria-label="Related">...</aside>
  <footer role="contentinfo">...</footer>
</body>
```

### Missing page title (WCAG 2.4.2)

**Rule IDs:** `document-title`

```html
<head>
  <title>Page Name - Site Name</title>
</head>
```

### Multiple navigations need distinct labels

```html
<nav aria-label="Main">...</nav>
<nav aria-label="Footer">...</nav>
```

---

## Links & Buttons (WCAG 2.4.4, 4.1.2)

### Non-descriptive link text

**Rule IDs:** `link-name`

```html
<!-- Before -->
<a href="/report">Click here</a>

<!-- Fix -->
<a href="/report">View quarterly report</a>

<!-- Or with context via aria-label -->
<a href="/report" aria-label="View quarterly report">View report</a>
```

### Empty link

```html
<!-- Before -->
<a href="/home"><img src="logo.png"></a>

<!-- Fix -->
<a href="/home"><img src="logo.png" alt="Home"></a>
```

### Link opens in new window without warning

```html
<a href="/terms" target="_blank" rel="noopener">
  Terms of Service <span class="sr-only">(opens in new tab)</span>
</a>
```

### Button without accessible name

**Rule IDs:** `button-name`, `aria-command-name`

```html
<!-- Before -->
<button><i class="icon-close"></i></button>

<!-- Fix -->
<button aria-label="Close dialog"><i class="icon-close"></i></button>
```

---

## ARIA (WCAG 4.1.2)

### Valid ARIA usage rules

**Rule IDs:** `aria-allowed-attr`, `aria-required-attr`, `aria-valid-attr`, `aria-valid-attr-value`,
`aria-roles`, `aria-roledescription`, `aria-allowed-role`

```html
<!-- Every ARIA role must be valid -->
<div role="tabpanel">...</div> <!-- OK -->
<div role="foobar">...</div>  <!-- INVALID — "foobar" is not a real role -->

<!-- Required attributes must be present -->
<div role="slider" aria-valuenow="5" aria-valuemin="0" aria-valuemax="10">...</div>

<!-- Attribute values must be valid -->
<div aria-hidden="true">...</div>  <!-- OK -->
<div aria-hidden="yes">...</div>   <!-- INVALID — must be "true" or "false" -->
```

### aria-hidden must not be on body

**Rule IDs:** `aria-hidden-body`

```html
<!-- NEVER do this -->
<body aria-hidden="true">

<!-- Only use aria-hidden on specific elements -->
<div aria-hidden="true">Decorative content</div>
```

### aria-hidden elements must not be focusable

**Rule IDs:** `aria-hidden-focus`

```html
<!-- BAD -->
<div aria-hidden="true">
  <button>Hidden but focusable</button>
</div>

<!-- Fix — add tabindex="-1" or remove from aria-hidden container -->
<div aria-hidden="true">
  <button tabindex="-1">Hidden and not focusable</button>
</div>
```

### ARIA input and toggle fields need accessible names

**Rule IDs:** `aria-input-field-name`, `aria-toggle-field-name`

```html
<div role="textbox" aria-label="Search query" contenteditable="true"></div>
<div role="switch" aria-label="Dark mode" aria-checked="false"></div>
<div role="slider" aria-label="Volume" aria-valuenow="50" aria-valuemin="0" aria-valuemax="100"></div>
```

### Duplicate IDs

**Rule IDs:** `duplicate-id`, `duplicate-id-active`, `duplicate-id-aria`

```html
<!-- BAD — same ID used twice -->
<label for="name">Name</label>
<input id="name">
<input id="name"> <!-- Duplicate! -->

<!-- Fix — unique IDs -->
<label for="first-name">First Name</label>
<input id="first-name">
<label for="last-name">Last Name</label>
<input id="last-name">
```

### Presentation role conflicts

**Rule IDs:** `presentation-role-conflict`

```html
<!-- BAD — element with role="presentation" has tabindex -->
<img role="presentation" tabindex="0" src="decorative.png">

<!-- Fix — remove tabindex from presentational elements -->
<img role="presentation" alt="" src="decorative.png">
```

### Custom dropdown/select

```html
<div role="combobox" aria-expanded="false" aria-haspopup="listbox"
     aria-label="Choose a fruit">
  <input type="text" aria-autocomplete="list" aria-controls="fruit-list">
  <ul id="fruit-list" role="listbox" hidden>
    <li role="option" id="opt-apple">Apple</li>
    <li role="option" id="opt-banana">Banana</li>
  </ul>
</div>
```

### Tab interface

```html
<div role="tablist" aria-label="Account settings">
  <button role="tab" aria-selected="true" aria-controls="panel-1" id="tab-1">Profile</button>
  <button role="tab" aria-selected="false" aria-controls="panel-2" id="tab-2" tabindex="-1">Security</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1">...</div>
<div role="tabpanel" id="panel-2" aria-labelledby="tab-2" hidden>...</div>
```

### Modal dialog

**Rule IDs:** `aria-dialog-name`

```html
<div role="dialog" aria-modal="true" aria-labelledby="dialog-title">
  <h2 id="dialog-title">Confirm deletion</h2>
  <p>Are you sure you want to delete this item?</p>
  <button type="button">Cancel</button>
  <button type="button">Delete</button>
</div>
```

### Live regions for dynamic content (WCAG 4.1.3)

```html
<!-- Status messages -->
<div role="status" aria-live="polite">3 results found</div>

<!-- Error alerts -->
<div role="alert" aria-live="assertive">Session expired. Please log in again.</div>

<!-- Log region -->
<div role="log" aria-live="polite" aria-label="Chat messages">...</div>

<!-- Timer -->
<div role="timer" aria-live="off" aria-label="Countdown">5:00</div>
```

---

## ARIA APG Widget Patterns

Patterns from the [WAI-ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/patterns/).

### Accordion

```html
<div class="accordion">
  <h3>
    <button aria-expanded="false" aria-controls="sect1" id="accordion1">
      Section 1
    </button>
  </h3>
  <div id="sect1" role="region" aria-labelledby="accordion1" hidden>
    <p>Section 1 content...</p>
  </div>
  <h3>
    <button aria-expanded="false" aria-controls="sect2" id="accordion2">
      Section 2
    </button>
  </h3>
  <div id="sect2" role="region" aria-labelledby="accordion2" hidden>
    <p>Section 2 content...</p>
  </div>
</div>
```

### Disclosure (show/hide)

```html
<button aria-expanded="false" aria-controls="details-panel">
  Show Details
</button>
<div id="details-panel" hidden>
  <p>Additional details here...</p>
</div>
```

### Menubar

```html
<nav aria-label="Main menu">
  <ul role="menubar">
    <li role="none">
      <button role="menuitem" aria-haspopup="true" aria-expanded="false">File</button>
      <ul role="menu" hidden>
        <li role="none"><button role="menuitem">New</button></li>
        <li role="none"><button role="menuitem">Open</button></li>
        <li role="separator"></li>
        <li role="none"><button role="menuitem">Save</button></li>
      </ul>
    </li>
    <li role="none">
      <button role="menuitem">Edit</button>
    </li>
  </ul>
</nav>
```

### Breadcrumb

```html
<nav aria-label="Breadcrumb">
  <ol>
    <li><a href="/">Home</a></li>
    <li><a href="/products">Products</a></li>
    <li><a href="/products/widgets" aria-current="page">Widgets</a></li>
  </ol>
</nav>
```

### Alert dialog

```html
<div role="alertdialog" aria-modal="true" aria-labelledby="alert-title" aria-describedby="alert-desc">
  <h2 id="alert-title">Unsaved Changes</h2>
  <p id="alert-desc">You have unsaved changes. Do you want to discard them?</p>
  <button type="button">Discard</button>
  <button type="button" autofocus>Keep Editing</button>
</div>
```

### Tree view

**Rule IDs:** `aria-treeitem-name`

```html
<ul role="tree" aria-label="File browser">
  <li role="treeitem" aria-expanded="true">
    <span>Documents</span>
    <ul role="group">
      <li role="treeitem" class="doc">Report.pdf</li>
      <li role="treeitem" class="doc">Notes.txt</li>
    </ul>
  </li>
  <li role="treeitem" aria-expanded="false">
    <span>Images</span>
    <ul role="group" hidden>
      <li role="treeitem">Photo.jpg</li>
    </ul>
  </li>
</ul>
```

### Carousel / Slide show

```html
<section aria-roledescription="carousel" aria-label="Product highlights">
  <div aria-live="off">
    <div role="group" aria-roledescription="slide" aria-label="1 of 3">
      <img src="slide1.jpg" alt="New widget model with ergonomic grip">
      <p>Introducing the Widget Pro</p>
    </div>
  </div>
  <button aria-label="Previous slide">&#x2190;</button>
  <button aria-label="Next slide">&#x2192;</button>
  <button aria-label="Pause auto-rotation">&#x23F8;</button>
</section>
```

### Switch (toggle)

```html
<button role="switch" aria-checked="false" onclick="toggleSwitch(this)">
  <span aria-hidden="true">Off</span>
  Dark Mode
</button>
```

```javascript
function toggleSwitch(btn) {
  const checked = btn.getAttribute('aria-checked') === 'true';
  btn.setAttribute('aria-checked', String(!checked));
  btn.querySelector('span').textContent = checked ? 'Off' : 'On';
}
```

### Toolbar

```html
<div role="toolbar" aria-label="Text formatting" aria-controls="editor">
  <button aria-pressed="false" onclick="toggleBold(this)">Bold</button>
  <button aria-pressed="false" onclick="toggleItalic(this)">Italic</button>
  <button aria-pressed="false" onclick="toggleUnderline(this)">Underline</button>
</div>
```

---

## Tables & Lists (WCAG 1.3.1)

### Data table without proper headers

**Rule IDs:** `td-headers-attr`, `th-has-data-cells`, `scope-attr-valid`, `empty-table-header`

```html
<!-- Before -->
<table>
  <tr><td>Name</td><td>Email</td></tr>
  <tr><td>Alice</td><td>alice@example.com</td></tr>
</table>

<!-- Fix -->
<table>
  <caption>User Directory</caption>
  <thead>
    <tr>
      <th scope="col">Name</th>
      <th scope="col">Email</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Alice</td>
      <td>alice@example.com</td>
    </tr>
  </tbody>
</table>
```

### Complex table with row and column headers

```html
<table>
  <caption>Quarterly Sales by Region</caption>
  <thead>
    <tr>
      <th scope="col">Region</th>
      <th scope="col">Q1</th>
      <th scope="col">Q2</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">North</th>
      <td>$150k</td>
      <td>$175k</td>
    </tr>
    <tr>
      <th scope="row">South</th>
      <td>$120k</td>
      <td>$135k</td>
    </tr>
  </tbody>
</table>
```

### Fake caption using first row

**Rule IDs:** `table-fake-caption`

```html
<!-- BAD — first row pretending to be a caption -->
<table>
  <tr><td colspan="3"><strong>Sales Data</strong></td></tr>
  <tr><td>Name</td><td>Q1</td><td>Q2</td></tr>
</table>

<!-- Fix — use <caption> -->
<table>
  <caption>Sales Data</caption>
  <thead><tr><th>Name</th><th>Q1</th><th>Q2</th></tr></thead>
</table>
```

### List structure

**Rule IDs:** `list`, `listitem`, `definition-list`, `dlitem`

```html
<!-- Lists must contain correct children -->
<ul>
  <li>Item 1</li>
  <li>Item 2</li>
</ul>

<!-- Definition lists -->
<dl>
  <dt>Term</dt>
  <dd>Definition</dd>
</dl>
```

---

## Language (WCAG 3.1.1, 3.1.2)

### Missing document language

**Rule IDs:** `html-has-lang`, `html-lang-valid`

```html
<html lang="en">
```

### lang and xml:lang mismatch

**Rule IDs:** `html-xml-lang-mismatch`

```html
<!-- Both must agree on base language -->
<html lang="en" xml:lang="en">
```

### Inline language changes

**Rule IDs:** `valid-lang`

```html
<p>The French word <span lang="fr">bonjour</span> means hello.</p>
```

---

## Media (WCAG 1.2.1 - 1.2.5)

### Video without captions

**Rule IDs:** `video-caption`

```html
<video controls>
  <source src="demo.mp4" type="video/mp4">
  <track kind="captions" src="demo-captions.vtt" srclang="en" label="English" default>
</video>
```

### Audio without captions/transcript

**Rule IDs:** `audio-caption`

```html
<audio controls>
  <source src="podcast.mp3" type="audio/mpeg">
</audio>
<a href="podcast-transcript.html">Read transcript</a>
```

### Video with audio description (1.2.5)

```html
<video controls>
  <source src="demo.mp4" type="video/mp4">
  <track kind="captions" src="demo-captions.vtt" srclang="en" label="English" default>
  <track kind="descriptions" src="demo-descriptions.vtt" srclang="en" label="Audio descriptions">
</video>
```

### Autoplay audio

**Rule IDs:** `no-autoplay-audio`

```html
<!-- BAD — auto-plays audio with no way to stop -->
<audio autoplay src="background.mp3"></audio>

<!-- Fix — add controls, or limit to < 3 seconds, or don't autoplay -->
<audio controls src="background.mp3"></audio>
```

---

## Frames & Embeds (WCAG 4.1.2)

### Iframe missing title

**Rule IDs:** `frame-title`, `frame-title-unique`

```html
<!-- Before -->
<iframe src="https://maps.example.com/embed"></iframe>

<!-- Fix -->
<iframe src="https://maps.example.com/embed" title="Office location map"></iframe>
```

### Multiple iframes need unique titles

```html
<iframe src="/header" title="Site header"></iframe>
<iframe src="/content" title="Main content"></iframe>
<iframe src="/footer" title="Site footer"></iframe>
```

### Iframe with focusable content

**Rule IDs:** `frame-focusable-content`

```html
<!-- BAD — iframe with focusable content has tabindex="-1" -->
<iframe src="/form" tabindex="-1"></iframe>

<!-- Fix — remove negative tabindex -->
<iframe src="/form" title="Contact form"></iframe>
```

---

## Timing & Motion (WCAG 2.2.1, 2.3.1)

### Blink and marquee

**Rule IDs:** `blink`, `marquee`

```html
<!-- NEVER use these elements -->
<!-- <blink>Bad</blink> -->
<!-- <marquee>Bad</marquee> -->

<!-- Use CSS animation with reduced-motion support instead -->
<div class="announcement" role="alert">Important update available</div>
```

### Meta refresh

**Rule IDs:** `meta-refresh`

```html
<!-- BAD — auto-redirects -->
<meta http-equiv="refresh" content="5;url=/new-page">

<!-- Fix — use server-side redirect (301/302) or provide a link -->
<p>This page has moved. <a href="/new-page">Go to the new page</a>.</p>
```

### Auto-refreshing content

```html
<button aria-pressed="true" onclick="toggleAutoRefresh()">Auto-refresh</button>
```

### Animation with no reduced-motion support

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

### Flashing content (2.3.1)

Content must not flash more than 3 times per second. If flashing is essential, keep it below the
general flash threshold: the area is small enough (< 21,824 sq px) or the luminance change is below
the threshold.

---

## Screen-Reader-Only Utility

Reusable CSS class for visually hidden but accessible text:

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

---

## React / JSX Specific Patterns

### Image alt in JSX

```jsx
<img src={logo} alt="Company logo" />
// Decorative:
<img src={divider} alt="" role="presentation" />
```

### onClick on non-interactive element

```jsx
// Before
<div onClick={handleClick}>Action</div>

// Fix: use a button
<button type="button" onClick={handleClick}>Action</button>
```

### Dynamic page title

```jsx
useEffect(() => {
  document.title = `${pageTitle} - My App`;
}, [pageTitle]);
```

### Form label in JSX

```jsx
<label htmlFor="email">Email</label>
<input type="email" id="email" />
```

### Route change announcements

```jsx
import { useLocation } from 'react-router-dom';

function RouteAnnouncer() {
  const location = useLocation();
  const [announcement, setAnnouncement] = useState('');

  useEffect(() => {
    setAnnouncement(`Navigated to ${document.title}`);
  }, [location]);

  return (
    <div role="status" aria-live="assertive" className="sr-only">
      {announcement}
    </div>
  );
}
```

### Focus management after navigation

```jsx
import { useEffect, useRef } from 'react';
import { useLocation } from 'react-router-dom';

function MainContent({ children }) {
  const mainRef = useRef(null);
  const location = useLocation();

  useEffect(() => {
    mainRef.current?.focus();
  }, [location.pathname]);

  return (
    <main ref={mainRef} tabIndex={-1} id="main-content">
      {children}
    </main>
  );
}
```

---

## Next.js Specific Patterns

### Head / metadata

```jsx
// app/layout.tsx (App Router)
export const metadata = {
  title: { default: 'My App', template: '%s - My App' },
};

// Per page
export const metadata = { title: 'Dashboard' };
// Renders: <title>Dashboard - My App</title>
```

### next/image alt

```jsx
import Image from 'next/image';
<Image src="/hero.jpg" alt="Team working together in office" width={800} height={400} />
```

### next/link

```jsx
import Link from 'next/link';
<Link href="/about">About Us</Link>
// Next.js renders <a>, no extra work needed for keyboard access
```

---

## Angular Specific Patterns

### Router-based page title

```typescript
{ path: 'dashboard', component: DashboardComponent, title: 'Dashboard - My App' }
```

### Live announcer for route changes

```typescript
constructor(private liveAnnouncer: LiveAnnouncer) {}

ngOnInit() {
  this.liveAnnouncer.announce('Dashboard page loaded');
}
```

### cdkTrapFocus for modals

```html
<div class="modal" cdkTrapFocus cdkTrapFocusAutoCapture>
  <h2>Dialog Title</h2>
  <button (click)="close()">Close</button>
</div>
```

### Angular Material a11y

```html
<!-- Angular Material components have built-in a11y -->
<mat-form-field>
  <mat-label>Email</mat-label>
  <input matInput type="email" required>
  <mat-error>Email is required</mat-error>
</mat-form-field>
```

---

## Vue Specific Patterns

### Dynamic page title

```javascript
// Vue 3 Composition API
import { watch } from 'vue';
import { useRoute } from 'vue-router';

const route = useRoute();
watch(() => route.meta.title, (title) => {
  document.title = `${title} - My App`;
}, { immediate: true });
```

```javascript
// Options API
watch: {
  '$route'(to) {
    document.title = `${to.meta.title} - My App`;
  }
}
```

### Accessible v-for lists

```html
<ul role="list">
  <li v-for="item in items" :key="item.id">{{ item.name }}</li>
</ul>
```

### Focus management on route change

```javascript
// router/index.js
router.afterEach((to) => {
  nextTick(() => {
    const main = document.getElementById('main-content');
    if (main) main.focus();
  });
});
```

### vue-announcer for screen readers

```html
<template>
  <div role="status" aria-live="assertive" class="sr-only">
    {{ announcement }}
  </div>
</template>
```

---

## Svelte Specific Patterns

### Page title

```svelte
<svelte:head>
  <title>{pageTitle} - My App</title>
</svelte:head>
```

### Accessible event handlers

```svelte
<!-- Svelte warns if on:click is used without on:keydown -->
<div role="button" tabindex="0"
     on:click={handleAction}
     on:keydown={(e) => { if (e.key === 'Enter' || e.key === ' ') handleAction(); }}>
  Action
</div>

<!-- Better: just use a button -->
<button on:click={handleAction}>Action</button>
```

### a11y linting

Svelte has built-in a11y warnings at compile time for:
- Missing alt text on images
- Non-interactive elements with event handlers
- Missing form labels
- Autofocus usage

---

## Web Components Patterns

### Shadow DOM and labels

```javascript
class MyInput extends HTMLElement {
  constructor() {
    super();
    const shadow = this.attachShadow({ mode: 'open', delegatesFocus: true });
    shadow.innerHTML = `
      <label for="inner-input"><slot name="label">Label</slot></label>
      <input id="inner-input" part="input">
    `;
  }

  static get observedAttributes() { return ['aria-label']; }

  attributeChangedCallback(name, _, newVal) {
    if (name === 'aria-label') {
      this.shadowRoot.querySelector('input').setAttribute('aria-label', newVal);
    }
  }
}
customElements.define('my-input', MyInput);
```

### Delegating focus

```javascript
this.attachShadow({ mode: 'open', delegatesFocus: true });
```

---

## Media Alternatives (WCAG 1.2.3, 1.2.5)

### Audio description for pre-recorded video (1.2.3 / 1.2.5)

**Rule IDs:** `audio-description`, `video-description`

Pre-recorded video with audio must have an audio description track or a text alternative that describes visual content not conveyed through audio alone.

```html
<!-- Before — video with no audio description -->
<video src="demo.mp4" controls></video>

<!-- Fix Option 1 — add audio description track -->
<video src="demo.mp4" controls>
  <track kind="descriptions" src="demo-descriptions.vtt" srclang="en" label="Audio Description">
</video>

<!-- Fix Option 2 — link to text alternative -->
<video src="demo.mp4" controls aria-describedby="video-desc"></video>
<p id="video-desc">
  This video shows a user clicking the Submit button on the registration form,
  entering their name and address, then receiving a confirmation message.
</p>
```

**Detection:** Any `<video>` element that has an audio track but no `<track kind="descriptions">` and no `aria-describedby` pointing to a descriptive element.

---

## Meaningful Sequence & Reflow (WCAG 1.3.2, 1.4.10)

### Meaningful reading order (1.3.2)

**Rule ID:** `meaningful-sequence`

When the sequence of content matters for comprehension, that sequence must be preserved in the DOM order — not just visually arranged via CSS.

```html
<!-- Before — visual order created by CSS float, DOM order is wrong -->
<div class="sidebar" style="float:right">Navigation</div>
<div class="main-content">Main article content here</div>

<!-- Fix — DOM order matches visual/logical reading order -->
<div class="main-content">Main article content here</div>
<aside class="sidebar">Navigation</aside>
```

```css
/* Use CSS Grid or Flexbox with order property carefully */
/* Never rely on float or absolute positioning to create logical reading order */
.container {
  display: grid;
  grid-template-areas: "main sidebar";
}
```

### Reflow at 320 CSS px (1.4.10)

**Rule ID:** `css-reflow`

Content must reflow to a single column at 320 CSS px (equivalent to 400% zoom at 1280 px desktop) without requiring horizontal scrolling.

```css
/* Before — fixed widths cause horizontal scroll at 320px */
.card { width: 500px; }
.table-wrapper { width: 800px; overflow-x: auto; }

/* Fix — fluid layout */
.card {
  width: 100%;
  max-width: 500px;
}

/* Tables — allow horizontal scroll only on the table container, not the page */
.table-wrapper {
  width: 100%;
  overflow-x: auto;
}

/* Responsive images */
img, video {
  max-width: 100%;
  height: auto;
}
```

**Never use:**
```css
/* BAD — prevents reflow */
white-space: nowrap;
overflow: hidden;
/* on the main body or page containers */
```

---

## Images of Text (WCAG 1.4.5)

### Replace images of text with real text (1.4.5)

**Rule ID:** `images-of-text`

Text must not be presented as images unless the visual presentation is essential (e.g., a logo).

```html
<!-- Before — heading presented as image -->
<img src="heading-welcome.png" alt="Welcome to our portal">

<!-- Fix — use real text styled with CSS -->
<h1 class="styled-heading">Welcome to our portal</h1>
```

```css
.styled-heading {
  font-family: 'CustomFont', Georgia, serif;
  font-size: 2rem;
  color: #1a3c5e;
  letter-spacing: 0.05em;
}
```

**Exceptions — allowed as images of text:**
- Logos and brand marks
- Charts and diagrams where the image itself conveys non-text information

---

## Non-Text Contrast (WCAG 1.4.11)

### UI component and graphical object contrast (1.4.11)

**Rule ID:** `non-text-contrast`

UI components (form inputs, buttons, checkboxes) and meaningful graphics must have at least **3:1** contrast ratio against adjacent colours.

```css
/* Before — input border too faint */
.form-control { border: 1px solid #ddd; }

/* Fix — 3:1 contrast against white background */
.form-control { border: 1px solid #767676; }

/* Before — checkbox outline invisible */
input[type="checkbox"] { outline: none; }

/* Fix — visible focus and boundary */
input[type="checkbox"] {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}

/* Before — icon colour too light */
.icon { color: #ccc; }

/* Fix — meets 3:1 */
.icon { color: #767676; }
```

**Required ratio:** 3:1 for all UI boundaries, focus indicators, and meaningful graphical objects.

**Note:** This criterion is distinct from colour contrast (1.4.3) which applies to text. Non-text contrast applies to the visual boundary of interactive elements.

---

## Focus Visible (WCAG 2.4.7)

### Keyboard focus must be visible (2.4.7)

**Rule ID:** `focus-visible`

Any keyboard-operable UI component must have a visible focus indicator when focused.

```css
/* Before — focus removed globally */
* { outline: none; }
:focus { outline: 0; }

/* Fix — provide a clear custom focus style */
:focus-visible {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
  border-radius: 2px;
}

/* For buttons specifically */
button:focus-visible {
  outline: 3px solid #005fcc;
  outline-offset: 3px;
}

/* For links */
a:focus-visible {
  outline: 2px solid #005fcc;
  text-decoration: underline;
}
```

```html
<!-- Never suppress focus for interactive elements -->
<!-- BAD -->
<button onfocus="this.blur()">Submit</button>

<!-- Fix — allow natural focus -->
<button>Submit</button>
```

**Important:** Never use `outline: none` or `outline: 0` without providing an equal or better custom focus indicator.

---

## Headings & Labels Descriptive (WCAG 2.4.6)

### Headings and labels must be descriptive (2.4.6)

**Rule ID:** `heading-label-descriptive`

Headings and form labels must describe the topic or purpose of the section/control. Vague or generic headings do not meet this criterion.

```html
<!-- Before — vague headings -->
<h2>Information</h2>
<h2>Details</h2>
<label for="field1">Field</label>

<!-- Fix — descriptive headings and labels -->
<h2>Personal Information</h2>
<h2>Vehicle Registration Details</h2>
<label for="field1">Date of Birth</label>
```

```html
<!-- Before — form with generic section headings -->
<h3>Section 1</h3>
<h3>Section 2</h3>

<!-- Fix -->
<h3>Owner Contact Details</h3>
<h3>Vehicle Identification</h3>
```

**Detection:** Flag headings whose text is only whitespace, generic numbers, or common placeholders (`Section`, `Details`, `Info`, `Item`, `Field`). Flag labels whose text does not describe the expected input.

---

## Pointer Gestures (WCAG 2.5.1)

### Single-pointer alternative for multi-point or path gestures (2.5.1)

**Rule ID:** `pointer-gestures`

All functionality using multi-point gestures (e.g., pinch-to-zoom) or path-based gestures (e.g., swipe) must also be operable with a single pointer without a path gesture.

```html
<!-- Before — swipe-only carousel with no button alternative -->
<div class="carousel" data-touch-only="true">...</div>

<!-- Fix — add explicit previous/next buttons -->
<div class="carousel">
  <button class="carousel-prev" aria-label="Previous slide">&#8249;</button>
  <div class="carousel-track">...</div>
  <button class="carousel-next" aria-label="Next slide">&#8250;</button>
</div>
```

```javascript
// Before — only touch/swipe events
element.addEventListener('touchstart', handleSwipe);

// Fix — add click/keyboard alternatives alongside touch
element.addEventListener('touchstart', handleSwipe);
document.querySelector('.carousel-prev').addEventListener('click', showPrev);
document.querySelector('.carousel-next').addEventListener('click', showNext);
```

---

## Consistent Navigation & Identification (WCAG 3.2.3, 3.2.4)

### Navigation repeated in same relative order (3.2.3)

**Rule ID:** `consistent-navigation`

Navigation menus that appear on multiple pages must appear in the same relative order each time unless the user changes it.

```html
<!-- Fix — use a shared partial/layout for navigation -->
<!-- _Layout.cshtml -->
<header>
  <nav aria-label="Main navigation">
    <ul>
      <li><a href="/home">Home</a></li>
      <li><a href="/vehicles">Vehicles</a></li>
      <li><a href="/account">Account</a></li>
      <li><a href="/help">Help</a></li>
    </ul>
  </nav>
</header>
```

**Detection:** Check that the shared navigation partial (`_Layout.cshtml`, `_Nav.cshtml`, `_Header.cshtml`) is used consistently and that nav item order does not differ between page templates.

### Consistent component identification (3.2.4)

**Rule ID:** `consistent-identification`

Components with the same function across pages must be identified consistently — same label, same accessible name.

```html
<!-- Before — same search field labelled differently on different pages -->
<!-- Page A -->
<label for="search">Search</label>
<input id="search" type="text">

<!-- Page B — inconsistent -->
<label for="search">Find</label>
<input id="search" type="text">

<!-- Fix — use the same label text across all pages -->
<label for="search">Search</label>
<input id="search" type="text" placeholder="Search registrations...">
```

---

## Error Identification & Suggestion (WCAG 3.3.1, 3.3.3)

### Error identification (3.3.1)

**Rule ID:** `error-identification`

If an input error is automatically detected, the item in error must be identified and the error described to the user in text — not colour alone.

```html
<!-- Before — error shown only in red colour -->
<input type="text" id="dob" class="error-field">
<span class="error-icon">!</span>

<!-- Fix — describe error in text associated with the field -->
<input type="text" id="dob" aria-describedby="dob-error" aria-invalid="true"
       class="error-field">
<span id="dob-error" class="error-message" role="alert">
  Date of birth is required. Enter in DD/MM/YYYY format.
</span>
```

```css
/* Always combine colour with text — never colour alone */
.error-field {
  border-color: #d32f2f;
  border-width: 2px;
}
.error-message {
  color: #d32f2f;
  font-size: 0.875rem;
  display: block;
  margin-top: 4px;
}
```

### Error suggestion (3.3.3)

**Rule ID:** `error-suggestion`

If an input error is detected and suggestions for correction are known, provide those suggestions — unless doing so would jeopardise security.

```html
<!-- Before — vague error -->
<span id="email-error">Invalid email.</span>

<!-- Fix — specific, actionable suggestion -->
<span id="email-error" role="alert">
  Enter a valid email address, for example: name@example.com
</span>

<!-- Date format suggestion -->
<span id="dob-error" role="alert">
  Enter date of birth as DD/MM/YYYY, for example: 15/03/1985
</span>

<!-- Required field suggestion -->
<span id="plate-error" role="alert">
  Licence plate number is required. Enter your plate without spaces, for example: ABC123
</span>
```

---

## Captions Live (WCAG 1.2.4)

### Live captions for real-time audio content (1.2.4)

**Rule ID:** `live-caption`

All live audio content in synchronised media (e.g., live video streams, webcasts, webinars) must have captions provided in real time.

```html
<!-- Before — live stream with no captions -->
<video id="live-stream" src="live.m3u8" autoplay controls></video>

<!-- Fix Option 1 — WebVTT live captions via TextTrack API -->
<video id="live-stream" src="live.m3u8" autoplay controls>
  <!-- Server must push live VTT segments to this track -->
  <track kind="captions" src="live-captions.vtt" srclang="en"
         label="English Captions" default>
</video>

<!-- Fix Option 2 — Third-party live captioning service integration -->
<!-- e.g., StreamText, 3Play Media, AI captioning service -->
<!-- Captions displayed in an adjacent container linked to the video -->
<div id="live-caption-display" aria-live="polite" aria-atomic="true"
     class="live-captions">
  <!-- Caption text injected here by captioning service JS -->
</div>
```

**Note:** Automated/AI captions are acceptable for WCAG 1.2.4 if they are substantially accurate. Pre-recorded captions (WCAG 1.2.2) have a higher accuracy expectation.

---

## Sensory Characteristics (WCAG 1.3.3)

### Instructions must not rely solely on shape, colour, size, or position (1.3.3)

**Rule ID:** `sensory-characteristics`

Instructions for understanding and operating content must not rely solely on sensory characteristics of components (shape, colour, size, visual location, orientation, sound).

```html
<!-- Before — instructions use only shape and position -->
<p>Click the round button on the right to submit.</p>
<p>Fill in the fields highlighted in red.</p>

<!-- Fix — include a text label or name in addition to sensory cue -->
<p>Click the "Submit" button to complete your application.</p>
<p>Fill in all required fields. Required fields are marked with an
   asterisk (*) and highlighted in red.</p>
```

```html
<!-- Before — navigation uses colour alone -->
<p>The selected menu item is shown in blue.</p>

<!-- Fix — name the item -->
<p>The currently selected menu item is underlined and shown in blue.</p>
```

**Pattern to detect:** Instructions containing words like `round`, `square`, `red`, `green`, `left`, `right`, `above`, `below`, `bigger`, `smaller` without also including a non-sensory text identifier.

---

## Character Key Shortcuts (WCAG 2.1.4)

### Single-key shortcuts must be remappable or disableable (2.1.4)

**Rule ID:** `character-key-shortcuts`

If a keyboard shortcut using only a single printable character (letter, number, punctuation) is implemented, then users must be able to turn it off, remap it, or the shortcut must only be active when the component has focus.

```javascript
// Before — single-key global shortcut that cannot be disabled
document.addEventListener('keydown', (e) => {
  if (e.key === 's') {
    saveForm();
  }
});

// Fix Option 1 — require modifier key (Ctrl, Alt, Shift)
document.addEventListener('keydown', (e) => {
  if (e.ctrlKey && e.key === 's') {
    saveForm();
  }
});

// Fix Option 2 — only active when component has focus
const searchInput = document.querySelector('#search');
searchInput.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    clearSearch();
  }
});

// Fix Option 3 — provide UI to remap or disable shortcuts
const shortcuts = {
  save: { key: 's', modifier: 'ctrl', enabled: true }
};
// Persist user preference to localStorage
```

```html
<!-- Provide shortcut settings UI -->
<section aria-labelledby="shortcut-settings-heading">
  <h2 id="shortcut-settings-heading">Keyboard Shortcuts</h2>
  <label>
    <input type="checkbox" id="enable-shortcuts" checked>
    Enable single-key shortcuts
  </label>
</section>
```

---

## Multiple Ways (WCAG 2.4.5)

### More than one way to locate a page (2.4.5)

**Rule ID:** `multiple-ways`

There must be more than one way to find a web page within a set of pages — except where the page is a step in a process (e.g., a checkout wizard).

This is a structural/site-level criterion. It requires at least two of:
- Site navigation menu
- Site search
- Site map
- Table of contents
- Links between related pages

```html
<!-- Fix — ensure at least two navigation mechanisms exist -->

<!-- 1. Primary navigation -->
<nav aria-label="Main navigation">
  <ul>
    <li><a href="/dashboard">Dashboard</a></li>
    <li><a href="/vehicles">Vehicles</a></li>
    <li><a href="/reports">Reports</a></li>
  </ul>
</nav>

<!-- 2. Site search -->
<form role="search" action="/search">
  <label for="site-search">Search site</label>
  <input type="search" id="site-search" name="q"
         placeholder="Search...">
  <button type="submit">Search</button>
</form>
```

**Note:** Page-level review only — flag if a page is not reachable via navigation menu AND has no search or sitemap link.

---

## Pointer Cancellation (WCAG 2.5.2)

### Pointer event cancellation (2.5.2)

**Rule ID:** `pointer-cancellation`

For functionality triggered by a single pointer, at least one of the following must be true:
- No Down-Event — the action is triggered on the up-event, not the down-event
- Abort or Undo — the action can be aborted or undone
- Up Reversal — releasing over the originating element reverses the action
- Essential — triggering on down-event is essential

```javascript
// Before — action triggered on mousedown / pointerdown only
button.addEventListener('mousedown', () => {
  deleteRecord();
});

// Fix — trigger on mouseup / pointerup (or click which fires on up)
button.addEventListener('click', () => {
  deleteRecord();
});

// For custom drag-and-drop — allow cancel via Escape
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && isDragging) {
    cancelDrag();
  }
});

// For critical destructive actions — add undo mechanism
async function deleteRecord() {
  markAsDeleted(recordId);
  showUndoToast('Record deleted. <button id="undo-delete">Undo</button>');
  await delay(5000);
  if (!undone) confirmDelete(recordId);
}
```

**Detection:** Find `mousedown`, `pointerdown`, `touchstart` handlers on buttons, links, or interactive elements where the associated action is not cancellable and is not also handled by a corresponding `mouseup`/`click`.

---

## Motion Actuation (WCAG 2.5.4)

### Device motion alternatives (2.5.4)

**Rule ID:** `motion-actuation`

Functionality triggered by device motion (shake, tilt, gyroscope) or user motion (camera gestures) must also be operable via user interface controls, and users must be able to disable motion actuation to prevent accidental triggering.

```javascript
// Before — shake-to-undo with no UI alternative or disable option
window.addEventListener('devicemotion', (e) => {
  if (isShake(e)) undoLastAction();
});

// Fix — provide UI control and disable setting
window.addEventListener('devicemotion', (e) => {
  if (motionEnabled && isShake(e)) undoLastAction();
});

// UI alternative
document.querySelector('#undo-btn').addEventListener('click', undoLastAction);

// Preference setting persisted to localStorage
const motionEnabled = localStorage.getItem('motionEnabled') !== 'false';
```

```html
<!-- Provide UI button alternative for every motion action -->
<button id="undo-btn" aria-label="Undo last action">
  Undo
</button>

<!-- Provide motion settings UI -->
<label>
  <input type="checkbox" id="disable-motion" onchange="toggleMotion(this)">
  Disable motion-activated actions
</label>
```

---

## On Focus & On Input (WCAG 3.2.1, 3.2.2)

### No context change on focus (3.2.1)

**Rule ID:** `on-focus`

Receiving focus must not automatically trigger a change of context (e.g., opening a new window, submitting a form, moving to the next page, opening a dialog).

```html
<!-- Before — focusing a select triggers page navigation -->
<select onchange="location = this.value">
  <option value="/home">Home</option>
  <option value="/reports">Reports</option>
</select>

<!-- Fix — require explicit user action (Submit button) -->
<form>
  <label for="nav-select">Go to section</label>
  <select id="nav-select" name="section">
    <option value="/home">Home</option>
    <option value="/reports">Reports</option>
  </select>
  <button type="submit">Go</button>
</form>
```

```javascript
// Before — auto-advance to next field when max length reached
input.addEventListener('focus', () => {
  if (/* some condition */) showModal();
});

// Fix — never open dialogs, navigate, or submit on focus alone
// Only open overlays in response to an explicit user gesture (click, Enter)
```

### No context change on input (3.2.2)

**Rule ID:** `on-input`

Changing the setting of a UI component must not automatically cause a change of context unless the user has been advised of the behaviour before using the component.

```html
<!-- Before — checkbox immediately navigates on change -->
<input type="checkbox" onchange="window.location='/settings'">

<!-- Fix — use a submit button -->
<form action="/settings" method="post">
  <label>
    <input type="checkbox" name="email-prefs" value="1">
    Receive email updates
  </label>
  <button type="submit">Save preferences</button>
</form>

<!-- Exception — if auto-submit is clearly stated in advance -->
<p>Selecting a filter below will immediately update the results.</p>
<select id="status-filter" onchange="filterResults(this.value)"
        aria-describedby="filter-note">
  <option value="all">All</option>
  <option value="active">Active</option>
</select>
<span id="filter-note" class="sr-only">
  Changing this filter immediately updates the list below.
</span>
```

---

## Status Messages (WCAG 4.1.3)

### Status messages must be programmatically determinable (4.1.3)

**Rule ID:** `status-messages`

Status messages (success, error, warning, loading) that are not given focus must be programmatically determined through role or property so that assistive technologies can announce them without requiring focus to move.

```html
<!-- Before — success message added to DOM with no ARIA role -->
<div id="success-msg" class="alert alert-success">
  Your registration has been submitted.
</div>

<!-- Fix — use role="status" for polite non-critical messages -->
<div id="success-msg" role="status" aria-live="polite"
     class="alert alert-success">
  Your registration has been submitted.
</div>

<!-- Fix — use role="alert" for critical/error messages -->
<div id="error-msg" role="alert" aria-live="assertive"
     class="alert alert-danger">
  Submission failed. Please try again.
</div>

<!-- Fix — search results count update -->
<div role="status" aria-live="polite" id="results-count">
  <!-- Updated dynamically: "14 results found" -->
</div>

<!-- Fix — loading/progress state -->
<div role="status" aria-live="polite" aria-atomic="true">
  <span class="sr-only" id="loading-status">Loading results…</span>
</div>
```

```javascript
// When injecting status messages dynamically
function showSuccess(message) {
  const el = document.getElementById('success-msg');
  el.textContent = message; // aria-live region will announce this
}
```

**Rules:**
- `role="status"` + `aria-live="polite"` — use for confirmations, search results, save states
- `role="alert"` + `aria-live="assertive"` — use for errors, warnings, time-sensitive messages
- Never use `aria-live` on content that changes repeatedly and rapidly (e.g., live clocks)

---

## Compliance Standards Quick Reference

| Standard | Scope | Based On | Key Requirement |
|----------|-------|----------|-----------------|
| **WCAG 2.2** | Global web standard | W3C Recommendation (Dec 2024) | Levels A, AA, AAA |
| **ADA Title III** | US — public accommodations | US law; references WCAG 2.1 AA | Websites of public entities |
| **Section 508** | US — federal agencies | Incorporates WCAG 2.0 AA | Federal ICT procurement |
| **EN 301 549** | EU — public sector | Incorporates WCAG 2.1 AA | European Accessibility Act |
| **AODA** | Ontario, Canada | WCAG 2.0 AA | Accessibility for Ontarians |
| **EAA** | EU — private sector (2025+) | WCAG 2.1 AA minimum | Products and services |

### WCAG 2.2 New Success Criteria Summary

| SC | Name | Level | Key Requirement |
|----|------|-------|-----------------|
| 2.4.11 | Focus Not Obscured (Min) | AA | Focused item not fully hidden by sticky elements |
| 2.4.12 | Focus Not Obscured (Enhanced) | AAA | No part of focused item hidden |
| 2.4.13 | Focus Appearance | AAA | 2px outline, 3:1 contrast on focus |
| 2.5.7 | Dragging Movements | AA | Single-pointer alternative to drag |
| 2.5.8 | Target Size (Minimum) | AA | 24x24 CSS px or adequate spacing |
| 3.2.6 | Consistent Help | A | Help in same relative location |
| 3.3.7 | Redundant Entry | A | Don't re-ask info already given |
| 3.3.8 | Accessible Auth (Min) | AA | No cognitive test without alternative |
| 3.3.9 | Accessible Auth (Enhanced) | AAA | No cognitive test at all |

**Removed in WCAG 2.2:** SC 4.1.1 Parsing (obsolete — modern browsers handle malformed HTML).

---

## References

- [WCAG 2.2 Specification](https://www.w3.org/TR/WCAG22/) — W3C Recommendation, December 2024
- [Understanding WCAG 2.2](https://www.w3.org/WAI/WCAG22/Understanding/) — explanations of each criterion
- [WAI-ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/) — widget patterns and examples
- [axe-core Rule Descriptions](https://github.com/dequelabs/axe-core/blob/develop/doc/rule-descriptions.md) — automated rule IDs
- [Deque University Rule List](https://dequeuniversity.com/rules/axe-devtools/4.5) — detailed rule documentation
- [Section 508 Standards](https://www.section508.gov/) — US federal accessibility requirements
- [EN 301 549](https://www.etsi.org/deliver/etsi_en/301500_301599/301549/) — European accessibility standard

---
