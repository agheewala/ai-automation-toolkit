-- Data Dictionary Toolkit: table/column schema catalog export (SQL Server)
-- Run against the target jurisdiction's database. Export the result set to CSV with
-- headers: DB Name, Table Name, Column #, PK, Column Name, Data Type, Null,
-- Column Description, Default, Table Description (these exact column names are
-- required by generate-data-dictionary tooling).
SELECT
    DB_NAME()                                                      AS [DB Name],
    t.name                                                         AS [Table Name],
    c.column_id                                                    AS [Column #],
    CASE WHEN pk.column_id IS NOT NULL THEN 'PK' ELSE NULL END     AS [PK],
    c.name                                                         AS [Column Name],
    ty.name +
        CASE
            WHEN ty.name IN ('varchar', 'char', 'varbinary', 'binary')
                THEN '(' + CASE WHEN c.max_length = -1 THEN 'max'
                                ELSE CAST(c.max_length AS varchar(10)) END + ')'
            WHEN ty.name IN ('nvarchar', 'nchar')
                THEN '(' + CASE WHEN c.max_length = -1 THEN 'max'
                                ELSE CAST(c.max_length / 2 AS varchar(10)) END + ')'
            WHEN ty.name IN ('decimal', 'numeric')
                THEN '(' + CAST(c.precision AS varchar(10)) + ',' + CAST(c.scale AS varchar(10)) + ')'
            WHEN ty.name IN ('datetime2', 'datetimeoffset', 'time')
                THEN '(' + CAST(c.scale AS varchar(10)) + ')'
            ELSE ''
        END                                                         AS [Data Type],
    CASE WHEN c.is_nullable = 1 THEN 'Yes' ELSE 'No' END           AS [Null],
    ISNULL(CAST(ep_col.value AS nvarchar(max)), 'NULL')            AS [Column Description],
    ISNULL(dc.definition, 'NULL')                                  AS [Default],
    ISNULL(CAST(ep_tbl.value AS nvarchar(max)), 'NULL')            AS [Table Description]
FROM sys.tables t
JOIN sys.columns c
    ON c.object_id = t.object_id
JOIN sys.types ty
    ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc
    ON dc.object_id = c.default_object_id
LEFT JOIN (
    SELECT ic.object_id, ic.column_id
    FROM sys.index_columns ic
    JOIN sys.indexes i
        ON i.object_id = ic.object_id
       AND i.index_id  = ic.index_id
    WHERE i.is_primary_key = 1
) pk
    ON pk.object_id = c.object_id
   AND pk.column_id = c.column_id
LEFT JOIN sys.extended_properties ep_col
    ON ep_col.major_id = c.object_id
   AND ep_col.minor_id = c.column_id
   AND ep_col.name     = 'MS_Description'
LEFT JOIN sys.extended_properties ep_tbl
    ON ep_tbl.major_id = t.object_id
   AND ep_tbl.minor_id = 0
   AND ep_tbl.name     = 'MS_Description'
ORDER BY
    t.name,
    c.column_id;
