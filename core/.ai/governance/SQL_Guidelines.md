# SQL Review Guidelines for Production

This document defines the mandatory rules for validating SQL scripts used for data fixes in Production.

> **Primary database for this project:** `{{DB_NAME}}` (populated per-project by
> `generators/create-knowledge-base.prompt.md` / the data-dictionary export — never hardcode a
> specific project's database name in this `core/` file).

> **Dialect note:** Examples below show SQL Server and Oracle syntax side by side. Use whichever
> matches `{{DB_NAME}}`'s engine, and follow its schema-qualification convention (for example,
> SQL Server projects may prefix objects with a schema such as `dbo.`; Oracle projects typically
> use the owning schema or none). Do not assume a dialect-specific form applies to every project.

---

## 0. Authoritative Data Source (MANDATORY — Consult First)

Before drafting, editing, or validating **any** SQL script (production data fix, ad-hoc query,
data analysis, or a new/modified stored procedure), consult `.ai/data-dictionary/` first:

| File | Use it to verify |
|---|---|
| `.ai/data-dictionary/db-schema-dictionary.md` | Table exists, column exists, exact column name/casing, data type, length/precision, nullability, primary key, default, and business description — required for correct literal formatting (quoting strings, date formats, decimal precision) and for building a correct `WHERE` clause |
| `.ai/data-dictionary/stored-procedures.md` | Whether a stored procedure already performs the needed operation (reuse/call it rather than writing new inline SQL), and the established script conventions (parameter naming, output/status parameters, error-correction variants, delimiter-parsed list parameters, as documented in the catalog) to follow if a new/modified procedure is required |
| `.ai/data-dictionary/stored-procedure-dataflows.md` | Quick visual map of which tables a candidate procedure reads/writes, before diving into the full script |

Rules:
- **Never invent a table name, column name, data type, or stored procedure signature.** If it is
  not found in the data dictionary, treat it as unknown — ask the user before proceeding (see
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
If the project has not documented one, ask the user before generating scripts.

#### SQL Server:
```sql
AuditStampCol = '<STAMP_PREFIX>-####_' + CONVERT(VARCHAR(8), GETDATE(), 112)
```

#### Oracle:
```sql
AuditStampCol = '<STAMP_PREFIX>-####_' || TO_CHAR(SYSDATE, 'YYYYMMDD')
```

**Where:**
- `<STAMP_PREFIX>` = project-defined prefix (may embed a project/jurisdiction code)
- `####` = Ticket/change number
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

## 2. Reversal Script (MANDATORY for Reversal-Required Projects ONLY)

**A reversal script is only required for projects whose policy (see `.ai/knowledge-base.md`) marks it mandatory.** For all other projects it is recommended but not enforced.

- **Reversal-required projects**: Reversal script is **MANDATORY** — the script will FAIL validation without it
- **Other projects**: Reversal script is **NOT required**

### Audit-Stamp Value in Reversal Scripts:
- **If original value was NOT blank/empty**: Use the same stamp format with the ticket number
- **If original value WAS blank/empty**: Use empty string `''` to restore original state

**Reversal-Required Example (Restoring Non-Empty Value):**
```sql
UPDATE TableName
SET StatusCode = 'ACTIVE',
    AuditStampCol = '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = 98765
--COUNT: 1

--REVERSE QUERY
--UPDATE TableName
--SET StatusCode = 'PENDING',
--    AuditStampCol = '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
--WHERE RecordID = 98765
--COUNT: 1
```

**Reversal-Required Example (Restoring Empty/Blank Value):**
```sql
UPDATE TableName
SET LAST_UPD_TS = CURRENT_TIMESTAMP,
    AuditStampCol = '<STAMP_PREFIX>-2448_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = 98765
--COUNT: 1

--REVERSE QUERY
--UPDATE TableName
--SET LAST_UPD_TS = '2026-04-16 10:50:08.000',
--    AuditStampCol = ''
--WHERE RecordID = 98765
--COUNT: 1
```

**Other Project Example (no reversal required):**
```sql
UPDATE TableName
SET StatusCode = 'ACTIVE',
    AuditStampCol = '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = 98765
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
    AuditStampCol = '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE OrderID = 45678
    AND Status = 'Pending'
--COUNT: 1
```

---

## 5. INSERT Statement Rules (MANDATORY)

**INSERT statements must follow proper syntax and safety patterns.**

### Column Names (Recommended):
```sql
INSERT INTO TableName (Column1, Column2, AuditStampCol)
VALUES ('Value1', 'Value2', '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### Without Column Names (Must match table order exactly):
```sql
INSERT INTO TableName
VALUES ('Value1', 'Value2', '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
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
    VALUES ('Value1', 'Value2', '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
END
--COUNT: 1
```

---

## 6. Validation Rules Summary

### MANDATORY (FAIL if missing):
1. ✅ **Audit-stamp column** - Required for UPDATE/INSERT only (NOT for DELETE)
2. ✅ **Record Count** - Any clear format with number
3. ✅ **WHERE Clause** - For UPDATE/DELETE statements
4. ✅ **Reversal Script** - ONLY for reversal-required projects
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

### Step 2: Check Audit-Stamp Column (for UPDATE/INSERT only)
- **UPDATE/INSERT**: If missing from SET/VALUES clause → **FAIL** immediately
- If present → Extract the project code (if the project's prefix embeds one)

### Step 3: Validate Based on Project Policy
- **Reversal-required projects**: Require reversal script
- **Other projects**: Do NOT require reversal script

### Step 4: Validate Statement Type
- **UPDATE**: Check WHERE clause, record count, audit-stamp column in SET clause
- **DELETE**: Check WHERE clause, record count only
- **INSERT**: Check audit-stamp column in VALUES/SET clause, record count, proper syntax

### Step 5: Validate Database Syntax
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
Project: Determined from reversal script (if reversal-required project) or marked as "Other"
Result: [PASS/FAIL based on WHERE clause, record count, and reversal script if required]
```

---

## 9. Complete Examples

### UPDATE - Reversal-Required Project (with reversal):
```sql
UPDATE TableName
SET Status = 'APPROVED',
    AuditStampCol = '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = 12345
    AND Status = 'PENDING'
--COUNT: 1

--REVERSE QUERY
--UPDATE TableName
--SET Status = 'PENDING',
--    AuditStampCol = '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
--WHERE RecordID = 12345
--COUNT: 1
```

### UPDATE - Reversal-Required Project (restoring blank audit-stamp value):
```sql
UPDATE Inventory
SET LAST_UPD_TS = CURRENT_TIMESTAMP,
    AuditStampCol = '<STAMP_PREFIX>-2448_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE ItemControlNbr = '26979'
    AND ItemType = 'ABC'
    AND ItemYear = 2026
    AND AccountNbr = 36980936
--COUNT: 1

--REVERSE QUERY
--UPDATE Inventory
--SET LAST_UPD_TS = '2026-04-16 10:50:08.000',
--    AuditStampCol = ''
--WHERE ItemControlNbr = '26979'
--    AND ItemType = 'ABC'
--    AND ItemYear = 2026
--    AND AccountNbr = 36980936
--COUNT: 1
```

### UPDATE - Other Project (no reversal):
```sql
UPDATE TableName
SET Status = 'APPROVED',
    AuditStampCol = '<STAMP_PREFIX>-5678_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = 54321
    AND Status = 'PENDING'
--1 row affected
```

### INSERT - Reversal-Required Project (with reversal):
```sql
INSERT INTO TableName (Column1, Column2, Status, AuditStampCol)
VALUES ('Value1', 'Value2', 'ACTIVE', '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1

--REVERSE QUERY
--DELETE FROM TableName
--WHERE Column1 = 'Value1' AND Column2 = 'Value2'
--COUNT: 1
```

### INSERT - Other Project (no reversal):
```sql
INSERT INTO TableName (Column1, Column2, Status, AuditStampCol)
VALUES ('Value1', 'Value2', 'ACTIVE', '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### DELETE - Reversal-Required Project (with reversal):
```sql
DELETE FROM TableName
WHERE RecordID = 12345
    AND Status = 'PENDING'
--COUNT: 1

--REVERSE QUERY
--INSERT INTO TableName (RecordID, Status, AuditStampCol)
--VALUES (12345, 'PENDING', '<STAMP_PREFIX>-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### DELETE - Other Project (no reversal):
```sql
DELETE FROM Payments
WHERE PaymentUid = 66004
--COUNT: 1
```

### Oracle INSERT - Other Project:
```sql
INSERT INTO Payments (PaymentUid, PayStatInd, AuditStampCol)
VALUES (66003, 'V', '<STAMP_PREFIX>-923_' || TO_CHAR(SYSDATE, 'YYYYMMDD'))
--COUNT: 1
```

---
