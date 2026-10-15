# SQL Review Guidelines for Production

This document defines the mandatory rules for validating SQL scripts used for data fixes in Production.

> **Primary database for this project:** `{{DB_NAME}}` (populated per-project by
> `generators/create-knowledge-base.prompt.md` / the data-dictionary export — never hardcode a
> specific project's database name in this `core/` file).

---

## 0. Authoritative Data Source (MANDATORY — Consult First)

Before drafting, editing, or validating **any** SQL script (production data fix, ad-hoc query,
data analysis, or a new/modified stored procedure), consult `.ai/data-dictionary/` first:

| File | Use it to verify |
|---|---|
| `.ai/data-dictionary/db-schema-dictionary.md` | Table exists, column exists, exact column name/casing, data type, length/precision, nullability, primary key, default, and business description — required for correct literal formatting (quoting strings, date formats, decimal precision) and for building a correct `WHERE` clause |
| `.ai/data-dictionary/stored-procedures.md` | Whether a stored procedure already performs the needed operation (reuse/call it rather than writing new inline SQL), and the established script conventions (parameter naming, `OUT_SQLCODE OUTPUT`, `_E` error-correction variants, delimiter-parsed list parameters) to follow if a new/modified procedure is required |
| `.ai/data-dictionary/stored-procedure-dataflows.md` | Quick visual map of which tables a candidate procedure reads/writes, before diving into the full script |

Rules:
- **Never invent a table name, column name, data type, or stored procedure signature.** If it is
  not found in the data dictionary, treat it as unknown — ask the user before proceeding (see
  `behavior/decision-rules.md` STOP condition #9).
- If the data dictionary conflicts with an assumption made from reading application code only,
  the data dictionary wins for schema facts (table/column/type/nullability); the application
  (service/DAO) layer still governs what business logic is actually enforced. Flag any conflict
  between the two to the user.
- Full column-layout reference and usage rules: `.ai/data-dictionary/README.md`.

This step is in addition to — not a replacement for — the SUPPORT_USERID, WHERE clause, record
count, and reversal script rules below.

---

## 1. SUPPORT_USERID (MANDATORY)

**SUPPORT_USERID is MANDATORY for UPDATE and INSERT statements ONLY.**  
**DELETE statements do NOT require SUPPORT_USERID.**

### Format Based on Database Type:

#### SQL Server:
```sql
SUPPORT_USERID = 'TTxxSD-####_' + CONVERT(VARCHAR(8), GETDATE(), 112)
```

#### Oracle:
```sql
SUPPORT_USERID = 'TTxxSD-####_' || TO_CHAR(SYSDATE, 'YYYYMMDD')
```

**Where:**
- `TT` = Fixed prefix
- `xx` = 2-character jurisdiction/project code
- `SD` = Fixed suffix
- `####` = Ticket/change number
- `_` = Underscore separator

**Examples:**
- `'TTSCSD-2448_' + CONVERT(VARCHAR(8), GETDATE(), 112)` → SC Project
- `'TTxxSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)` → Other Project
- `'TTxxSD-923_' || TO_CHAR(SYSDATE, 'YYYYMMDD')` → Other Project (Oracle)

### Project Auto-Detection:
The AI will extract the project code from positions 3-4 in SUPPORT_USERID:
- `TTSCSD-####` → SC Project
- `TTxxSD-####` → Other Project (where xx = any other jurisdiction code)

### DELETE Statement Rules:

**DELETE statements do NOT require SUPPORT_USERID** because:
- The record is being removed from the database
- There is no field to store the SUPPORT_USERID value
- Production databases typically have DELETE triggers or audit tables that automatically capture deletion metadata

**DELETE statements only need:**
1. WHERE clause (MANDATORY)
2. Record count comment (MANDATORY)
3. Reversal script (MANDATORY for SC Project only)

---

## 2. Reversal Script (MANDATORY for SC Project ONLY)

**Reversal script is ONLY required for SC project.**

- **SC Project** (`TTSCSD-####`): Reversal script is **MANDATORY** - Script will FAIL without it
- **Other Projects** (`TTxxSD-####`): Reversal script is **NOT required**

### SUPPORT_USERID in Reversal Scripts:
- **If original value was NOT blank/empty**: Use the same SUPPORT_USERID format with ticket number
- **If original value WAS blank/empty**: Use empty string `''` to restore original state

**SC Project Example (Restoring Non-Empty Value):**
```sql
UPDATE TableName
SET StatusCode = 'ACTIVE',
    SUPPORT_USERID = 'TTSCSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = 98765
--COUNT: 1

--REVERSE QUERY
--UPDATE TableName
--SET StatusCode = 'PENDING',
--    SUPPORT_USERID = 'TTSCSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
--WHERE RecordID = 98765
--COUNT: 1
```

**SC Project Example (Restoring Empty/Blank Value):**
```sql
UPDATE TableName
SET LAST_UPD_TS = CURRENT_TIMESTAMP,
    SUPPORT_USERID = 'TTSCSD-2448_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = 98765
--COUNT: 1

--REVERSE QUERY
--UPDATE TableName
--SET LAST_UPD_TS = '2026-04-16 10:50:08.000',
--    SUPPORT_USERID = ''
--WHERE RecordID = 98765
--COUNT: 1
```

**Other Project Example:**
```sql
UPDATE TableName
SET StatusCode = 'ACTIVE',
    SUPPORT_USERID = 'TTxxSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
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
    SUPPORT_USERID = 'TTxxSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE OrderID = 45678
    AND Status = 'Pending'
--COUNT: 1
```

---

## 5. INSERT Statement Rules (MANDATORY)

**INSERT statements must follow proper syntax and safety patterns.**

### Column Names (Recommended):
```sql
INSERT INTO TableName (Column1, Column2, SUPPORT_USERID)
VALUES ('Value1', 'Value2', 'TTSCSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### Without Column Names (Must match table order exactly):
```sql
INSERT INTO TableName
VALUES ('Value1', 'Value2', 'TTSCSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### Unsafe Patterns (FAIL):
- ❌ INSERT without SUPPORT_USERID
- ❌ Missing record count
- ❌ Inserting without validation of existing records (may cause duplicates)

**Good Example with Duplicate Check:**
```sql
-- Check for existing record first
IF NOT EXISTS (SELECT 1 FROM TableName WHERE UniqueKey = 'Value1')
BEGIN
    INSERT INTO TableName (Column1, Column2, SUPPORT_USERID)
    VALUES ('Value1', 'Value2', 'TTSCSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
END
--COUNT: 1
```

---

## 6. Validation Rules Summary

### MANDATORY (FAIL if missing):
1. ✅ **SUPPORT_USERID** - Required for UPDATE/INSERT only (NOT for DELETE)
2. ✅ **Record Count** - Any clear format with number
3. ✅ **WHERE Clause** - For UPDATE/DELETE statements
4. ✅ **Reversal Script** - ONLY for SC project
5. ✅ **INSERT Safety** - Column names recommended, no duplicates

### OPTIONAL (WARNING only):
- SQL formatting (uppercase keywords, indentation)
- Duplicate check for INSERT statements
- Transaction blocks

---

## 7. Validation Process

### Step 1: Identify Statement Type
- **UPDATE/INSERT**: SUPPORT_USERID is MANDATORY
- **DELETE**: SUPPORT_USERID is NOT required

### Step 2: Check SUPPORT_USERID (for UPDATE/INSERT only)
- **UPDATE/INSERT**: If missing from SET/VALUES clause → **FAIL** immediately
- If present → Extract project code (characters 3-4 after 'TT')

### Step 3: Validate Based on Project
- **SC Project**: Require reversal script
- **Other Projects**: Do NOT require reversal script

### Step 4: Validate Statement Type
- **UPDATE**: Check WHERE clause, record count, SUPPORT_USERID in SET clause
- **DELETE**: Check WHERE clause, record count only
- **INSERT**: Check SUPPORT_USERID in VALUES/SET clause, record count, proper syntax

### Step 5: Validate Database Syntax
- **SQL Server**: `CONVERT(VARCHAR(8), GETDATE(), 112)`
- **Oracle**: `TO_CHAR(SYSDATE, 'YYYYMMDD')`

---

## 8. Validation Output Format

### If SUPPORT_USERID Missing (UPDATE/INSERT only):
```
Project: ❌ CANNOT BE DETERMINED
Result: ❌ FAIL
Issue: SUPPORT_USERID missing - add it before validation can proceed
```

### If All Rules Pass:
```
Project: [SC/Other]
Result: ✅ PASS
```

### If Rules Fail:
```
Project: [SC/Other]
Result: ❌ FAIL
Issues:
- [List specific issues]
```

### For DELETE Statements:
```
Note: DELETE statements do not require SUPPORT_USERID
Project: Determined from reversal script (if SC project) or marked as "Other"
Result: [PASS/FAIL based on WHERE clause, record count, and reversal script if SC]
```

---

## 9. Complete Examples

### UPDATE - SC Project (with reversal):
```sql
UPDATE TableName
SET Status = 'APPROVED',
    SUPPORT_USERID = 'TTSCSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = 12345
    AND Status = 'PENDING'
--COUNT: 1

--REVERSE QUERY
--UPDATE TableName
--SET Status = 'PENDING',
--    SUPPORT_USERID = 'TTSCSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112)
--WHERE RecordID = 12345
--COUNT: 1
```

### UPDATE - SC Project (restoring blank SUPPORT_USERID):
```sql
UPDATE MCS_INVENTORY 
SET LAST_UPD_TS = CURRENT_TIMESTAMP,
    SUPPORT_USERID = 'TTSCSD-2448_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE PROD_CNTL_NBR = '26979' 
    AND PROD_TYPE = 'MCD' 
    AND PROD_EXP_CCYY = 2026 
    AND ACCOUNT_NBR = 36980936
--COUNT: 1

--REVERSE QUERY
--UPDATE MCS_INVENTORY 
--SET LAST_UPD_TS = '2026-04-16 10:50:08.000',
--    SUPPORT_USERID = ''
--WHERE PROD_CNTL_NBR = '26979' 
--    AND PROD_TYPE = 'MCD' 
--    AND PROD_EXP_CCYY = 2026 
--    AND ACCOUNT_NBR = 36980936
--COUNT: 1
```

### UPDATE - Other Project (no reversal):
```sql
UPDATE TableName
SET Status = 'APPROVED',
    SUPPORT_USERID = 'TTxxSD-5678_' + CONVERT(VARCHAR(8), GETDATE(), 112)
WHERE RecordID = 54321
    AND Status = 'PENDING'
--1 row affected
```

### INSERT - SC Project (with reversal):
```sql
INSERT INTO TableName (Column1, Column2, Status, SUPPORT_USERID)
VALUES ('Value1', 'Value2', 'ACTIVE', 'TTSCSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1

--REVERSE QUERY
--DELETE FROM TableName
--WHERE Column1 = 'Value1' AND Column2 = 'Value2'
--COUNT: 1
```

### INSERT - Other Project (no reversal):
```sql
INSERT INTO TableName (Column1, Column2, Status, SUPPORT_USERID)
VALUES ('Value1', 'Value2', 'ACTIVE', 'TTxxSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### DELETE - SC Project (with reversal):
```sql
DELETE FROM TableName
WHERE RecordID = 12345
    AND Status = 'PENDING'
--COUNT: 1

--REVERSE QUERY
--INSERT INTO TableName (RecordID, Status, SUPPORT_USERID)
--VALUES (12345, 'PENDING', 'TTSCSD-1234_' + CONVERT(VARCHAR(8), GETDATE(), 112))
--COUNT: 1
```

### DELETE - Other Project (no reversal):
```sql
DELETE FROM mv_web_pay
WHERE web_pay_uid = 66004
--COUNT: 1
```

### Oracle INSERT - Other Project:
```sql
INSERT INTO MV_WEB_PAY (WEB_PAY_UID, PAY_STAT_IND, SUPPORT_USERID)
VALUES (66003, 'V', 'TTxxSD-923_' || TO_CHAR(SYSDATE, 'YYYYMMDD'))
--COUNT: 1
```

---
