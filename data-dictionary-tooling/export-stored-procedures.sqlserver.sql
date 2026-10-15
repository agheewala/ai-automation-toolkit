-- Data Dictionary Toolkit: stored procedure catalog export (SQL Server)
-- Run against the target jurisdiction's database. Export the result set to CSV with
-- headers: ProcedureName, FullyQualifiedName, CreatedDate, ModifiedDate, GeneratedScript
-- (these exact column names are required by generate-data-dictionary tooling).
SELECT
    p.name                              AS ProcedureName,
    s.name + N'.' + p.name              AS FullyQualifiedName,
    p.create_date                       AS CreatedDate,
    p.modify_date                       AS ModifiedDate,
    N'SET ANSI_NULLS ' + CASE WHEN m.uses_ansi_nulls = 1 THEN N'ON' ELSE N'OFF' END
        + CHAR(13) + CHAR(10) + N'GO' + CHAR(13) + CHAR(10)
        + N'SET QUOTED_IDENTIFIER ' + CASE WHEN m.uses_quoted_identifier = 1 THEN N'ON' ELSE N'OFF' END
        + CHAR(13) + CHAR(10) + N'GO' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10)
        + CASE
              WHEN m.definition IS NULL THEN N'-- Definition unavailable (encrypted procedure)'
              ELSE STUFF(m.definition, PATINDEX('%CREATE%', m.definition), 6, N'ALTER')
          END
    AS GeneratedScript
FROM sys.procedures AS p
INNER JOIN sys.schemas AS s
    ON p.schema_id = s.schema_id
LEFT JOIN sys.sql_modules AS m
    ON m.object_id = p.object_id
WHERE p.is_ms_shipped = 0
ORDER BY s.name, p.name;
