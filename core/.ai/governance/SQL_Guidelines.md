# SQL Review Guidelines for Production

This document defines the mandatory rules for validating SQL scripts used for data fixes in Production.

> **Primary database for this project:** `{{DB_NAME}}` (populated per-project by
> `generators/create-knowledge-base.prompt.md` / the data-dictionary export — never hardcode a
> specific project's database name in this `core/` file).

> **Dialect note:** Examples below show SQL Server and Oracle syntax side by side. Use whichever
> matches `{{DB_NAME}}`'s engine, and follow its schema-qualification convention (for example,
> SQL Server projects may prefix objects with a schema such as `dbo.`; Oracle projects typically
> use the owning schema or none). Do not assume a dialect-specific form applies to every project.

> **Example data note:** All table names, column names, IDs, timestamps, status codes, and ticket
> numbers in this document (`<ID>`, `<TICKET-ID>`, `<TIMESTAMP>`, `STATUS = 'X'`, etc.) are
> synthetic placeholders. Replace them with real values verified against the data dictionary.

---

## 0. Authoritative Data Source (MANDATORY — Consult First)

> **Data-dictionary status for this project's engine.** `.ai/data-dictionary/` only exists once
> `generators/create-data-dictionary.prompt.md` has been run, and that generator currently supports
> **SQL Server only** (Oracle/other-engine export queries are a known gap in this toolkit version).
> Check whether `.ai/data-dictionary/README.md` exists:
> - **Present** → follow the rules below.
> - **Absent, SQL Server project** → the generator has not been run yet; ask the user whether to run it.
> - **Absent, Oracle/other engine** → no data dictionary is available yet. Use the schema facts in
>   `.ai/knowledge-base.md` Section 7 as the source instead, and for anything not documented there,
>   treat it as unknown and ask the user (see `behavior/decision-rules.md` STOP condition #9).
>   Record the engine's data-dictionary status here once a dictionary exists.

Before drafting, editing, or validating **any** SQL script (production data fix, ad-hoc query,
data analysis, or a new/modified stored procedure), consult `.ai/data-dictionary/` first (when present, per the note above):

| File | Use it to verify |
|---|---|
| `.ai/data-dictionary/db-schema-dictionary.md` | Table exists, column exists, exact column name/casing, data type, length/precision, nullability, primary key, default, and business description — required for correct literal formatting (quoting strings, date formats, decimal precision) and for building a correct `WHERE` clause |
| `.ai/data-dictionary/stored-procedures.md` | Whether a stored procedure already performs the needed operation (reuse/call it rather than writing new inline SQL), and the established script conventions (parameter naming, output/status parameters, error-correction variants, delimiter-parsed list parameters, as documented in the catalog) to follow if a new/modified procedure is required |
| `.ai/data-dictionary/stored-procedure-dataflows.md` | Quick visual map of which tables a candidate procedure reads/writes, before diving into the full script |

Rules:
- **Never invent a table name, column name, data type, or stored procedure signature.** If it is
  not found in the data dictionary (or, where no data dictionary exists, in `.ai/knowledge-base.md`
  Section 7), treat it as unknown — ask the user before proceeding (see
  `behavior/decision-rules.md` STOP condition #9).
- If the data dictionary conflicts with an assumption made from reading application code only,
  the data dictionary wins for schema facts (table/column/type/nullability); the application
  (service/Data Access) layer still governs what business logic is actually enforced. Flag any
  conflict between the two to the user.
- Full column-layout reference and usage rules: `.ai/data-dictionary/README.md`.

This step is in addition to — not a replacement for — the audit-stamp column, WHERE clause, record
count, and reversal script rules below.

---

## 1. Audit-Stamp Column (MANDATORY)

Every production data fix must record **which support ticket changed the row**. The project's
audit-stamp column (its exact name is in the data dictionary / `.ai/knowledge-base.md`; this
document calls it the *audit-stamp column*) is the column that holds this value.

**The audit-stamp column is MANDATORY for UPDATE and INSERT statements ONLY.**  
**DELETE statements do NOT require it.**

### Stamp Value Format:

`<STAMP_PREFIX>-<ticket number>_<yyyymmdd>` — the prefix convention (fixed prefix/suffix, optional
project or jurisdiction code) is defined by the project and recorded in `.ai/knowledge-base.md`.

**If `.ai/knowledge-base.md` does not document the audit-stamp column name or the stamp prefix,
STOP and ask the user before generating or validating any script. Never invent either value.**
(Check `.ai/knowledge-base.md` Section 7 → `Database Conventions` subsection; a value of
`Undocumented`, or the subsection being absent entirely, both count as "not documented" and
trigger the stop-and-ask rule.)

#### SQL Server:
```sql
AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112)
```

#### Oracle:
```sql
AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' || TO_CHAR(SYSDATE, 'YYYYMMDD')
```

**Where:**
- `<STAMP_PREFIX>` = project-defined prefix (may embed a project/jurisdiction code)
- `<TICKET-ID>` = Ticket/change number
- `_` = Underscore separator
- date portion = current date in `yyyymmdd`

### Project Policy Tier Detection:
If the project's stamp prefix embeds a project/jurisdiction code, extract it and look up the policy
tier (for example, whether a reversal script is required) in the project's documented mapping in
`.ai/knowledge-base.md`. If the code or mapping cannot be determined, report
"CANNOT BE DETERMINED" and ask — never guess.

### DELETE Statement Rules:

**DELETE statements do NOT require the audit-stamp column** because:
- The record is being removed from the database
- There is no field to store the stamp value
- Production databases typically have DELETE triggers or audit tables that automatically capture deletion metadata

**DELETE statements only need:**
1. WHERE clause (MANDATORY)
2. Record count comment (MANDATORY)
3. Reversal script (MANDATORY for reversal-required projects only)

---

## 2. Reversal Script (Governed by the Project's Documented Policy)

Whether a reversal script is required is decided by the project's reversal policy, which MUST be
documented in `.ai/knowledge-base.md`. There are exactly two valid documented outcomes:

- **Reversal-required project**: Reversal script is **MANDATORY** — the script will FAIL validation without it.
- **Other project** (the knowledge-base explicitly documents that reversal is not required): Reversal script is **NOT required**.

**If `.ai/knowledge-base.md` does not document the reversal-required policy — or does not document
the audit-stamp column name or the stamp prefix — STOP and ask the user before proceeding. Do not
assume either the requirement or the exemption. Never silently default to "reversal not required."**
(Check `.ai/knowledge-base.md` Section 7 → `Database Conventions` subsection; a value of
`Undocumented`, or the subsection being absent entirely, both count as "not documented" and
trigger the stop-and-ask rule.)

### Audit-Stamp Value in Reversal Scripts:
- **If original value was NOT blank/empty**: Use the same stamp format with the ticket number
- **If original value WAS blank/empty**: Use empty string `''` to restore original state

**Reversal-Required Example (Restoring Non-Empty Value):**
```sql
UPDATE TableName
SET StatusCode = 'ACTIVE',
    AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = <ID>
--COUNT: 1

--REVERSE QUERY
--UPDATE TableName
--SET StatusCode = 'PENDING',
--    AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112)
--WHERE RecordID = <ID>
--COUNT: 1
```

**Reversal-Required Example (Restoring Empty/Blank Value):**
```sql
UPDATE TableName
SET LastUpdatedTs = CURRENT_TIMESTAMP,
    AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = <ID>
--COUNT: 1

--REVERSE QUERY
--UPDATE TableName
--SET LastUpdatedTs = '<TIMESTAMP>',
--    AuditStampCol = ''
--WHERE RecordID = <ID>
--COUNT: 1
```

**Other Project Example (policy documents reversal not required):**
```sql
UPDATE TableName
SET StatusCode = 'ACTIVE',
    AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = <ID>
--COUNT: 1
```

---

## 3. Record Count (MANDATORY)

**Every SQL statement must include a record count comment.**

**Format:** Any format is acceptable as long as it clearly indicates the number of affected rows.

**Valid Examples:**
```sql
--COUNT: 5
--COUNT-5
--COUNT 5
--5 rows affected
--5 rows modified
--5 rows updated
--Expected rows: 5
--Rows to update: 5
--affected: 5
```

---

## 4. WHERE Clause (MANDATORY for UPDATE/DELETE)

**WHERE clause is MANDATORY for all UPDATE/DELETE statements.**

- Must include enough fields to uniquely identify records
- Must prevent full-table updates
- Should include primary key or unique identifiers
- Missing WHERE clause will cause **FAIL**

**Bad Example:**
```sql
UPDATE Orders SET Status = 'Cancelled' -- FAIL: Missing WHERE clause
```

**Good Example:**
```sql
UPDATE Orders
SET Status = 'Cancelled',
    AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE OrderID = <ID>
    AND Status = 'Pending'
--COUNT: 1
```

---

## 5. INSERT Statement Rules (MANDATORY)

**INSERT statements must follow proper syntax and safety patterns.**

### Column Names (Recommended):
```sql
INSERT INTO TableName (Column1, Column2, AuditStampCol)
VALUES ('Value1', 'Value2', '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### Without Column Names (Must match table order exactly):
```sql
INSERT INTO TableName
VALUES ('Value1', 'Value2', '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### Unsafe Patterns (FAIL):
- ❌ INSERT without the audit-stamp column
- ❌ Missing record count
- ❌ Inserting without validation of existing records (may cause duplicates)

**Good Example with Duplicate Check:**
```sql
-- Check for existing record first
IF NOT EXISTS (SELECT 1 FROM TableName WHERE UniqueKey = 'Value1')
BEGIN
    INSERT INTO TableName (Column1, Column2, AuditStampCol)
    VALUES ('Value1', 'Value2', '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112))
END
--COUNT: 1
```

---

## 6. Validation Rules Summary

### MANDATORY (FAIL if missing):
1. ✅ **Audit-stamp column** - Required for UPDATE/INSERT only (NOT for DELETE)
2. ✅ **Record Count** - Any clear format with number
3. ✅ **WHERE Clause** - For UPDATE/DELETE statements
4. ✅ **Reversal Script** - ONLY for reversal-required projects (policy must be documented — if undocumented, STOP and ask)
5. ✅ **INSERT Safety** - Column names recommended, no duplicates

### OPTIONAL (WARNING only):
- SQL formatting (uppercase keywords, indentation)
- Duplicate check for INSERT statements
- Transaction blocks

---

## 7. Validation Process

### Step 1: Identify Statement Type
- **UPDATE/INSERT**: Audit-stamp column is MANDATORY
- **DELETE**: Audit-stamp column is NOT required

### Step 2: Confirm Project Policy Is Documented (precondition for all later steps)
Confirm `.ai/knowledge-base.md` documents the audit-stamp column name, the stamp prefix, **and**
the reversal-required policy (check Section 7 → `Database Conventions` subsection; a value of
`Undocumented`, or the subsection being absent entirely, both count as "not documented" and
trigger the stop-and-ask rule). **If any of these is not documented, STOP and ask the user — do
not continue validation and never silently default to "reversal not required."** This must come
before Step 3, because the audit-stamp column cannot be checked if its name is unknown.

### Step 3: Check Audit-Stamp Column (for UPDATE/INSERT only)
- **UPDATE/INSERT**: If missing from SET/VALUES clause → **FAIL** immediately
- If present → Extract the project code (if the project's prefix embeds one)

### Step 4: Apply Project Policy
- **Reversal-required projects**: Require reversal script
- **Other projects** (reversal explicitly documented as not required): Do NOT require reversal script

### Step 5: Validate Statement Type
- **UPDATE**: Check WHERE clause, record count, audit-stamp column in SET clause
- **DELETE**: Check WHERE clause, record count only (plus reversal script if reversal-required)
- **INSERT**: Check audit-stamp column in VALUES/SET clause, record count, proper syntax

### Step 6: Validate Database Syntax
- **SQL Server**: `CONVERT(VARCHAR(8), GETDATE(), 112)`
- **Oracle**: `TO_CHAR(SYSDATE, 'YYYYMMDD')`
- Other engines: use the project's equivalent date-formatting function

---

## 8. Validation Output Format

### If Audit-Stamp Column Missing (UPDATE/INSERT only):
```
Project: ❌ CANNOT BE DETERMINED
Result: ❌ FAIL
Issue: Audit-stamp column missing - add it before validation can proceed
```

### If Project Policy Is Undocumented (column name, stamp prefix, or reversal policy not in knowledge-base):
```
Project: ❌ CANNOT BE DETERMINED
Result: ⏸️ STOPPED - USER INPUT REQUIRED
Issue: .ai/knowledge-base.md does not document [audit-stamp column / stamp prefix / reversal policy] - please provide it before validation can proceed
```

### If All Rules Pass:
```
Project: [Reversal-required / Other]
Result: ✅ PASS
```

### If Rules Fail:
```
Project: [Reversal-required / Other]
Result: ❌ FAIL
Issues:
- [List specific issues]
```

### For DELETE Statements:
```
Note: DELETE statements do not require the audit-stamp column
Project: [Reversal-required / Other] — per the policy documented in .ai/knowledge-base.md (if undocumented, STOP and ask)
Result: [PASS/FAIL based on WHERE clause, record count, and reversal script if required]
```

---

## 9. Complete Examples

### UPDATE - Reversal-Required Project (with reversal):
```sql
UPDATE TableName
SET Status = 'APPROVED',
    AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = <ID>
    AND Status = 'PENDING'
--COUNT: 1

--REVERSE QUERY
--UPDATE TableName
--SET Status = 'PENDING',
--    AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112)
--WHERE RecordID = <ID>
--COUNT: 1
```

### UPDATE - Reversal-Required Project (restoring blank audit-stamp value):
```sql
UPDATE ItemTable
SET LastUpdatedTs = CURRENT_TIMESTAMP,
    AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE ItemKey = '<ID>'
    AND ItemType = '<TYPE>'
    AND AccountKey = <ID>
--COUNT: 1

--REVERSE QUERY
--UPDATE ItemTable
--SET LastUpdatedTs = '<TIMESTAMP>',
--    AuditStampCol = ''
--WHERE ItemKey = '<ID>'
--    AND ItemType = '<TYPE>'
--    AND AccountKey = <ID>
--COUNT: 1
```

### UPDATE - Other Project (reversal documented as not required):
```sql
UPDATE TableName
SET Status = 'APPROVED',
    AuditStampCol = '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = <ID>
    AND Status = 'PENDING'
--1 row affected
```

### INSERT - Reversal-Required Project (with reversal):
```sql
INSERT INTO TableName (Column1, Column2, Status, AuditStampCol)
VALUES ('Value1', 'Value2', 'ACTIVE', '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1

--REVERSE QUERY
--DELETE FROM TableName
--WHERE Column1 = 'Value1' AND Column2 = 'Value2'
--COUNT: 1
```

### INSERT - Other Project (reversal documented as not required):
```sql
INSERT INTO TableName (Column1, Column2, Status, AuditStampCol)
VALUES ('Value1', 'Value2', 'ACTIVE', '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### DELETE - Reversal-Required Project (with reversal):
```sql
DELETE FROM TableName
WHERE RecordID = <ID>
    AND Status = 'PENDING'
--COUNT: 1

--REVERSE QUERY
--INSERT INTO TableName (RecordID, Status, AuditStampCol)
--VALUES (<ID>, 'PENDING', '<STAMP_PREFIX>-<TICKET-ID>_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### DELETE - Other Project (reversal documented as not required):
```sql
DELETE FROM RecordTable
WHERE RecordUid = <ID>
--COUNT: 1
```

### Oracle INSERT - Other Project (reversal documented as not required):
```sql
INSERT INTO RecordTable (RecordUid, StatusInd, AuditStampCol)
VALUES (<ID>, 'X', '<STAMP_PREFIX>-<TICKET-ID>_' || TO_CHAR(SYSDATE, 'YYYYMMDD'))
--COUNT: 1
```
