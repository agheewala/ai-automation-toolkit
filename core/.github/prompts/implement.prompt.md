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
2. **Which layers are affected?** (Controller / Service / DAO / ViewModel / View / CSS)
3. **Does this touch a supplement lifecycle step?** (If yes — what is the current status and what is the expected transition?)
4. **Does this involve fees, payments, or credentials?** (If yes — flag as high-risk)
5. **Is this a read or a write operation?** (Writes require `[ValidateAntiForgeryToken]` + logging)
6. **Does this affect UI?** (If yes — identify which theme/CSS files need updating)

---

## Implementation Order

Always implement in this layer order — never skip layers:

```
1. DTO (shared utility project's Dto/) — if a new data structure is needed
2. DAO Interface (XxxDataLayer/Dao/XxxDao.cs)
3. DAO SQL Implementation (XxxDataLayer/Dao/Sql/XxxDaoSql.cs)
4. DAO Factory entry (XxxDataLayer/Dao/XxxDaoFactory.cs)
5. Service Interface (XxxServiceLayer/Service/XxxService.cs)
6. Service Implementation (XxxServiceLayer/Service/Impl/XxxServiceImpl.cs)
7. Service Locator entry (XxxServiceLayer/Service/XxxServiceLocator.cs)
8. ViewModel (shared utility project's Models/Xxx/XxxVM.cs) — if UI change
9. Controller (XxxMvcApp/Controllers/XxxController.cs)
10. View (XxxMvcApp/Views/Xxx/XxxPage.cshtml) — if UI change
11. CSS (theme files in Content/themes/) — if visual change
```

---

## Layer Rules

### DAO Layer
- Interface in `XxxDataLayer/Dao/XxxDao.cs` — **no `I` prefix on interface**
- Implementation in `XxxDataLayer/Dao/Sql/XxxDaoSql.cs` — must be `internal class`
- Extends `BasicDaoSql` — use `getDatabaseConnection()`, `CreateDBCommand()`, `CreateDBParameter()`, `PopulateDBParameter()`
- **No inline SQL in service or controller** — SQL belongs in DAO only
- SQL parameters: suffix input params with `_IN` (e.g., `@ACCOUNT_NBR_IN`, `@FL_NBR_IN`)
- Schema prefix: `dbo.` for each module
- Always close connection in `finally` block
- Use the read-only database connection helper only for read-only reporting/reference queries against a secondary data source, if one exists

### Service Layer
- Interface in `XxxServiceLayer/Service/XxxService.cs`
- Implementation in `XxxServiceLayer/Service/Impl/XxxServiceImpl.cs` — must be `internal class`
- DAOs accessed **only** via factory: `XxxDaoFactory.getXxxDao()` (one factory per module)
- Logging: `Applogger.debug("entering XxxServiceImpl.method()")` on entry; `Applogger.fatal(...)` in catch
- Throw `BusinessException` (not generic `Exception`) on service errors
- Pass `SessionContext` when the operation requires user context (inserts, updates, audit trails)

### Controller Layer
- Extends `BaseController`
- Single `ProcessRequest` entry point — routes via `switch (displayPage)`
- Each display page handled by a private `[NonAction]` method
- Inside `[NonAction]` handlers: switch on `IsPostBack` first, then on `model.form_button_Name`
- Services accessed via `XxxServiceLocator.getXxxService()` (one locator per module)
- Declare `public static string ControllerName { get { return Constants.ControllersName.XXX; } }`
- **Never** put business logic directly in the controller — delegate to service

### View Layer (Razor CSHTML)
- **No raw HTML inputs** — use `Html.c*` helpers exclusively
- All labels: `@Html.cLabelFor(m => m.Xxx, AppResources.lblXxx)` — no hardcoded strings
- Form declaration: `@using (Html.BeginForm(ControllerConstants.ProcessRequest, XxxController.ControllerName, new { displayPage = ControllerConstants.DisplayPage.Xxx }, FormMethod.Post, ...))`
- Always include: `Html.RenderPartial("~/Views/Shared/PartialView/_ComHiddenFieldProps.cshtml");`
- Always include: `@Html.cValidationSummary()`
- Layout: the module's shared layout view (e.g. `~/Views/Shared/_XxxPageLayout.cshtml`)
- Session: `SessionContext context = UtilSettings.SessionContext;` at top of view

### CSS / Theme Layer
- **Module-specific pages**: edit the project's shared stylesheet in every theme folder under `Content/themes/` (see `.ai/governance/coding-standards.md` for the exact theme folder list for this project)
- Edit SCSS source where a theme provides one; hand-edit CSS directly for themes that ship compiled CSS only
- **Never use inline styles** — only CSS classes

---

## Critical Rules (Never Violate)

- ❌ No inline SQL anywhere outside DAO layer
- ❌ No raw `<input>`, `<select>`, `<textarea>` in Razor views — use `Html.c*` helpers
- ❌ No hardcoded UI strings — use `AppResources.lblXxx`
- ❌ No `new XxxDaoSql()` directly — use the DAO factory
- ❌ No `new XxxServiceImpl()` directly in controllers — use the service locator
- ❌ No cross-module DAO calls (one module's DAO from another, etc.) without explicit justification
- ❌ No business logic in controllers
- ❌ No DB logic in service layer
- ✅ Every new class that logs must declare: `private static AppLogger logger = new AppLogger(typeof(XxxClass));`
- ✅ All fee/payment/credential changes require senior review before push
