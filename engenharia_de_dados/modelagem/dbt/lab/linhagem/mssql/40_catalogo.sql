-- From the object name in the captured SQL to the source tables, reading only the catalog.
SET NOCOUNT ON;
USE rede;
GO
-- Definition of each module, with NULL where it is encrypted.
SELECT OBJECT_SCHEMA_NAME(m.object_id) AS esquema, OBJECT_NAME(m.object_id) AS objeto,
       CASE WHEN m.definition IS NULL THEN N'NULL' ELSE N'legivel' END AS sql_modules,
       CASE WHEN OBJECT_DEFINITION(m.object_id) IS NULL THEN N'NULL' ELSE N'legivel' END AS object_definition
FROM sys.sql_modules AS m
WHERE OBJECT_SCHEMA_NAME(m.object_id) = N'relatorios'
ORDER BY objeto;
GO
SELECT CAST(REPLACE(REPLACE(OBJECT_DEFINITION(OBJECT_ID(N'relatorios.vw_faturamento_itens')), CHAR(13), ' '), CHAR(10), ' ') AS nvarchar(400)) AS definicao_da_view;
GO
-- Dependencies by name, recorded when each module was created.
SELECT OBJECT_NAME(d.referencing_id) AS objeto, d.referenced_schema_name AS esquema,
       d.referenced_entity_name AS referencia, d.is_caller_dependent AS depende_de_quem_chama
FROM sys.sql_expression_dependencies AS d
WHERE OBJECT_SCHEMA_NAME(d.referencing_id) = N'relatorios'
ORDER BY objeto, referencia;
GO
-- Column level, through the function that resolves names when called.
SELECT referenced_schema_name AS esquema, referenced_entity_name AS referencia, referenced_minor_name AS coluna
FROM sys.dm_sql_referenced_entities(N'relatorios.vw_faturamento_itens', N'OBJECT')
ORDER BY referencia, coluna;
GO
-- The same function on the encrypted and on the dynamic SQL procedures.
SELECT N'faturamento_cifrado' AS objeto, referenced_schema_name AS esquema, referenced_entity_name AS referencia, referenced_minor_name AS coluna
FROM sys.dm_sql_referenced_entities(N'relatorios.faturamento_cifrado', N'OBJECT');
GO
SELECT N'faturamento_dinamico' AS objeto, referenced_schema_name AS esquema, referenced_entity_name AS referencia, referenced_minor_name AS coluna
FROM sys.dm_sql_referenced_entities(N'relatorios.faturamento_dinamico', N'OBJECT');
GO
EXEC sp_helptext N'relatorios.faturamento_cifrado';
GO
