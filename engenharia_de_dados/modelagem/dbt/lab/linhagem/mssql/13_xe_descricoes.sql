-- The engine's own description of the events this lab uses and of the plan event it avoids.
SET NOCOUNT ON;
SELECT o.name AS evento, CAST(o.description AS nvarchar(250)) AS descricao
FROM sys.dm_xe_objects AS o
JOIN sys.dm_xe_packages AS p ON p.guid = o.package_guid
WHERE o.object_type = N'event' AND p.name = N'sqlserver'
  AND o.name IN (N'sql_batch_completed', N'rpc_completed', N'sp_statement_completed',
                 N'query_post_execution_showplan')
ORDER BY o.name;
GO
