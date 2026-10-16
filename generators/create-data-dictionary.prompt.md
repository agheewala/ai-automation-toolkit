---
description: >
  Setup generator. Exports the target project's database schema and stored procedure catalog
  to CSV, then converts both into the authoritative, git-diffable markdown data dictionary
  consulted before any SQL script or DB-touching code change: .ai/data-dictionary/
  db-schema-dictionary.md, stored-procedures.md, stored-procedure-dataflows.md, README.md.
---

# Create Data Dictionary

You will be invoked once, at integration time (or again after a schema change), to generate the
`.ai/data-dictionary/` folder for a project. This folder becomes the authoritative, priority
source of truth for all database schema facts and existing stored procedure logic — consulted
before any SQL script is written, any data analysis is performed, or any code change touches the
database (see `core/.ai/governance/SQL_Guidelines.md` Section 0, which already mandates this).

> **Self-deleting prompt.** After this file successfully writes the four files in
> `.ai/data-dictionary/` and deletes the intermediate CSV exports, delete this file
> (`create-data-dictionary.prompt.md`) from the target project's `.github/prompts/` folder (see
> the **Step 7: Self-Delete** step below). This generator can be re-run later from the toolkit source if the schema
> changes again — there is no regeneration script kept in the target project itself.

> **No shell script.** All CSV parsing and markdown authoring in this workflow is done by you
> (the agent) directly — via your own `read_file` and `create_file` tool calls — not by an
> external PowerShell/bash/Python script. Do not write one.

---

## Step 1: Ask the user which database engine they use

Ask the user directly: *"Which database engine does this project use? (SQL Server, Oracle, other, or none)"*

- **If the project has no database at all**: stop here. In the target project's own copy of
  `.ai/governance/SQL_Guidelines.md`, replace every `{{DB_NAME}}` token with
  `N/A — this project has no database` so no raw token is left behind, and tell the user that
  no data dictionary is needed. Do not create `.ai/data-dictionary/`, and end the generator run
  here (then delete this file per the cleanup note, since it has nothing further to do).
- **If SQL Server**: continue to Step 2.
- **If Oracle or any other engine**: stop here and tell the user plainly that Oracle/other-engine
  export queries are not yet available in this toolkit version — this is a known gap, not a
  silent failure. Do not fabricate an Oracle (or other engine) query, do not invent placeholder
  `.sql` files, and do not attempt to approximate the SQL Server queries for a different engine's
  system catalog. Suggest the user check back in a future toolkit release, or contribute their own
  export query back to `data-dictionary-tooling/` if they have one. End the generator run here.
  Also mention that `data-dictionary-tooling/*.sqlserver.sql` were installed unconditionally and
  do not apply to their engine, so they can be ignored or deleted.

---

## Step 2: Direct the user to export the two CSVs

Tell the user to run the two export queries shipped in this toolkit against their own database and
save each result set to CSV with **exactly** these headers (column names, spelling, and casing
matter — the next step parses the CSV by header name):

1. `data-dictionary-tooling/export-schema-catalog.sqlserver.sql`
   → export to `.ai/data-dictionary/_export/schema.csv`
   → headers: `DB Name, Table Name, Column #, PK, Column Name, Data Type, Null, Column Description, Default, Table Description`
2. `data-dictionary-tooling/export-stored-procedures.sqlserver.sql`
   → export to `.ai/data-dictionary/_export/procedures.csv`
   → headers: `ProcedureName, FullyQualifiedName, CreatedDate, ModifiedDate, GeneratedScript`

Wait for the user to confirm both CSV files exist before continuing. Do not guess their contents.

---

## Step 3: Read both CSVs and author the three markdown files

Read `.ai/data-dictionary/_export/schema.csv` and `.ai/data-dictionary/_export/procedures.csv`
directly with `read_file`. If either file is large, read it in chunks (by line range) rather than
skipping content — every table/column and every procedure must be accounted for.

### 3a. Determine the database name

Read the `DB Name` column from any data row in `schema.csv` (it is the same value — literally
`DB_NAME()` — on every row). Use this exact value as `{{DB_NAME}}` everywhere below and in Step 4.
Do not ask the user for the database name separately; it is already in the export.

### 3b. Group tables into categories — `db-schema-dictionary.md`

Infer categories generically from table name patterns actually present in `schema.csv` — do not
hardcode any specific project's module names (e.g. do not assume "IRP" or "Enterprise" exist).
Use heuristics such as:

- Tables whose name contains `AUDIT` → an Audit category.
- Tables whose name starts with a short all-caps prefix followed by an underscore and reads as a
  reference/lookup table (e.g. `CD_*`, `LOOKUP_*`, `CODE_*`), or whose columns are mostly
  code/description pairs → a Code/Reference Tables category.
- Tables whose name contains `FEE`, `INVOICE`, `PAY`, `BILL`, `BOND`, `REFUND`, or similar billing
  vocabulary → a Financial/Billing category.
- Tables whose name contains `ERROR`, `COR_`, `CORRECTION` → an Error Correction category (only if
  such tables actually exist).
- Tables whose name contains `BATCH` → a Batch Processing category.
- Tables whose name contains `ALERT` → an Alerting category.
- Tables whose name contains `DOCUMENT`, `COMMENT`, `ATTACHMENT` → a Document/Comment category.
- Tables whose name contains `CONV`, `XREF`, `CHANGELOG`, a migration-looking prefix, or numeric
  version suffixes → a Conversion/System Housekeeping category.
- The largest remaining group of tables that share the project's core composite key columns
  (inspect which columns recur across many tables — these are the "spine" of the schema) forms
  the **Core Tables** category; name it after the dominant business entity you find (e.g. "Core
  Order Tables", "Core Policy Tables") rather than copying a template name literally.
- Everything left over → **Other / Uncategorized**.

Use your judgment — these are starting heuristics, not an exhaustive or mandatory list. Adapt
category names and groupings to what is actually present in this project's `schema.csv`; it is
fine to end up with a different category set than the example above.

For each table, write a section:

```
### TABLE_NAME
*Table description (from the first non-"NULL" Table Description value for that table; omit the
italic line entirely if every row for that table has Table Description = "NULL")*

| # | PK | Column | Type | Null | Description | Default |
|---|----|--------|------|------|--------------|---------|
| 1 | PK | COLUMN_NAME | type | No | description | default |
...
```

- Sort columns within a table by `Column #`.
- A column is marked `PK` in the `#`/`PK` column of the output table when its CSV `PK` value is
  `PK`. Multiple `PK` rows in the same table together form a composite primary key — do not treat
  this as an error.
- Render `Default` and `Column Description` cells as-is from the CSV; when the CSV value is the
  literal string `NULL`, render the cell blank rather than printing the word `NULL`.
- Include a table of contents at the top of the file, grouped by category with a per-category
  table count, each table name linking to its `### TABLE_NAME` anchor.
- **Optional master-detail diagram**: if you find a clear hierarchy in the Core Tables category
  (e.g. table A's primary key is a strict prefix of table B's composite primary key, suggesting
  A is a parent of B), you may add one Mermaid `flowchart TD` diagram under the Core Tables
  category heading showing that hierarchy with `A --> B` edges and a short `<br/>` business-role
  label per node. This is best-effort — omit it entirely if no clear hierarchy is apparent rather
  than forcing one.
- Title the file `# {{DB_NAME}} -- Database Schema Dictionary (Full Catalog)` and include a short
  authority header (point at `.ai/data-dictionary/README.md` for the full usage rules) plus a
  `Generated: <today's date> | Tables: <count> | Columns: <count>` line, matching the structure
  used by `stored-procedures.md` below.

### 3c. Author `stored-procedures.md`

For each row in `procedures.csv`:

1. **Reformat the flattened script.** The `GeneratedScript` column is exported as one long run of
   text with multi-line SQL collapsed into runs of whitespace. Reconstruct readable line breaks by
   replacing every run of **2 or more consecutive whitespace characters** with a single newline
   (regex `\s{2,}` → `\n`). Do not alter single spaces (e.g. `SELECT col1, col2` must stay on one
   line) — only collapse-and-break on runs of 2+.
2. **Detect "Tables Touched".** Scan the reformatted script for `SELECT`, `INSERT INTO`,
   `UPDATE`, and `DELETE FROM` keywords and match the table name that follows (or, for `SELECT`,
   every table name appearing in its `FROM`/`JOIN` clauses) against the table list you already
   extracted from `schema.csv` in Step 3b. For each table found, record every operation detected
   for it (a table can appear with more than one operation in the same procedure) in a
   `| Table | Operations |` summary table, sorted alphabetically by table name.
3. **Handle old-style comma-joins.** A `FROM A x, B y, C z` clause (pre-ANSI-89 join syntax) lists
   multiple tables separated by commas with no `JOIN` keyword. When extracting table names from a
   `FROM` clause, use a regex with a single **named** capture group repeated via alternation/
   quantifier (e.g. `FROM\s+(?<tbl>\w+)(?:\s+\w+)?(?:\s*,\s*(?<tbl>\w+)(?:\s+\w+)?)*`) and then
   read **all** of `match.Groups["tbl"].Captures`, not just `match.Groups["tbl"].Value` — a plain
   (non-named, non-Captures) approach only returns the LAST repetition of a repeated capture group
   and silently drops every comma-joined table before it. Use the `Captures` approach so no
   comma-joined table is lost.
4. Write a section per procedure:
   ```
   ## PROCEDURE_NAME

   - **Fully Qualified Name**: `FullyQualifiedName value`
   - **Created**: CreatedDate | **Modified**: ModifiedDate
   - **Dataflow diagram**: see [stored-procedure-dataflows.md](stored-procedure-dataflows.md#procedure_name)

   **Tables Touched:**

   | Table | Operations |
   |---|---|
   ...

   **Script:**
   ```sql
   <reformatted script>
   ```
   ```
5. **Segregate SSMS system procedures into an appendix.** SQL Server Management Studio's built-in
   database-diagram-support procedures are not business logic. Detect them generically by name —
   any procedure named `sp_alterdiagram`, `sp_creatediagram`, `sp_dropdiagram`,
   `sp_helpdiagramdefinition`, `sp_helpdiagrams`, `sp_renamediagram`, `sp_upgraddiagrams`, or
   `fn_diagramobjects` (this is the fixed, well-known `sysdiagrams` procedure set shipped by SSMS,
   not project-specific) — and list them under an `## Appendix: System / SSMS-Generated
   Procedures` heading at the end of the file instead of in the main body. Exclude them from the
   table of contents' main list (they get their own appendix entry) and from
   `stored-procedure-dataflows.md` entirely.
6. Include a table of contents at the top linking every non-appendix procedure, plus a link to the
   appendix. Title the file `# {{DB_NAME}} -- Stored Procedure Catalog (Full Scripts)` with the
   same authority-header style as `db-schema-dictionary.md` and a
   `Generated: <today's date> | Procedures: <count>` line.

### 3d. Author `stored-procedure-dataflows.md`

For every non-appendix procedure from Step 3c, write one Mermaid flowchart:

- **Write procedures** (any procedure with at least one detected `insert`/`update`/`delete`):
  - For each write operation, check whether its `WHERE`/`IN (...)` clause contains a driving
    subquery of the shape `IN (SELECT col FROM DrivingTable WHERE ...)`. If found, draw
    `DrivingTable -->|operation| TargetTable`. If not found (the write has no driving subquery),
    draw `SP_PROCEDURE_NAME -->|operation| TargetTable` directly from the procedure node.
  - Any table the procedure only reads (no write detected) gets `SP_PROCEDURE_NAME -->|select|
    TargetTable` if it isn't already captured as a driving table in an edge above.
- **Read-only procedures** (no write operations at all — typically `GET*`/`Get*` naming, but
  detect by actual absence of insert/update/delete, not by name): a pure hub-and-spoke diagram,
  `SP_PROCEDURE_NAME -->|select| TargetTable` for every table the procedure reads from (including
  tables found only via the old-style comma-join extraction in Step 3c.3).
- Reuse this exact color-coding legend and `classDef` block in every diagram (copy verbatim — it
  is already generic, not project-specific):

  ```mermaid
  flowchart LR
      classDef del fill:#fde2e2,stroke:#c0392b,color:#7b241c;
      classDef ins fill:#e2f7e2,stroke:#239b56,color:#145a32;
      classDef upd fill:#d6eaf8,stroke:#2874a6,color:#1b4f72;
      classDef sel fill:#f4f6f7,stroke:#7f8c8d,color:#2c3e50;
      classDef proc fill:#fef9e7,stroke:#b7950b,color:#7d6608,stroke-width:2px;

      SP_PROCEDURE_NAME["PROCEDURE_NAME (procedure)"]:::proc
      ...edges...

      class TABLE_A,TABLE_B del;
      class TABLE_C upd;
      class TABLE_D ins;
      class TABLE_E sel;
  ```
  Color a table by the **highest-impact operation detected for it** (priority: delete > update >
  insert > select), even if multiple operations were recorded in `stored-procedures.md`.
- Include a legend table and the "heuristic, not a full T-SQL parser — verify against the actual
  script for anything safety-critical" caveat at the top of the file, plus a table of contents
  matching `stored-procedures.md`'s non-appendix list.

### 3e. Write `.ai/data-dictionary/README.md`

Write a README with the following structure and authority rules (sections: a
summary table of the 4 files, what's in each of the 3 generated files, mandatory usage rules
instructing never to invent a table/column/procedure name, and a maintenance section explaining
that these are point-in-time exports with no kept regeneration script — refreshing means re-running
this generator). Replace every reference to a specific database name with `{{DB_NAME}}` (the value
you determined in Step 3a) — do not hardcode any particular project's database name into this file.

---

## Step 4: Fill `{{DB_NAME}}` in `SQL_Guidelines.md`

`core/.ai/governance/SQL_Guidelines.md` ships with an unfilled `{{DB_NAME}}` placeholder near the
top of the file:

```
> **Primary database for this project:** `{{DB_NAME}}` (populated per-project by
> `generators/create-knowledge-base.prompt.md` / the data-dictionary export — never hardcode a
> specific project's database name in this `core/` file).
```

In the target project's own copy of `.ai/governance/SQL_Guidelines.md` (not the `core/` template),
replace `{{DB_NAME}}` with the same database name value you determined in Step 3a. If
`create-knowledge-base.prompt.md` has already filled this placeholder (e.g. it was run first and
already knows the database name from scanning the codebase), leave its value as-is instead of
overwriting it with a possibly different literal — only fill it here if it is still the literal
unfilled `{{DB_NAME}}` token.

---

## Step 5: Delete the CSV exports

Once all four markdown files have been written and reviewed, delete
`.ai/data-dictionary/_export/schema.csv` and `.ai/data-dictionary/_export/procedures.csv` (and the
now-empty `_export/` folder, if your delete tooling supports removing empty directories). Only the
markdown files are kept in the project — raw CSVs are large, not git-diff-friendly, and not
directly useful to a reader once the markdown exists.

---

## Step 6: Report to the user

Summarize: database name detected, table/column counts, procedure count (business logic vs.
appendix), and which categories were inferred for `db-schema-dictionary.md`.

---

## Step 7: Self-Delete

Once the four files in `.ai/data-dictionary/` have been written, the CSVs deleted, and the summary
reported, delete this file (`create-data-dictionary.prompt.md`) from the target project's
`.github/prompts/` folder. Re-run instructions live in `.ai/data-dictionary/README.md`'s
Maintenance section if the schema changes again — point the user back to this toolkit's source if
they need to regenerate.
