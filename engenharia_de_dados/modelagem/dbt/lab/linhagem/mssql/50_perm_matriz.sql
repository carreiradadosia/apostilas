-- Run as leitor_monitor after each GRANT. Each batch stands alone so a denied one does not stop the next.
SET NOCOUNT ON;
GO
SELECT N'dm_exec_requests, sessoes de outros' AS teste, COUNT(*) AS linhas FROM sys.dm_exec_requests WHERE session_id <> @@SPID;
GO
SELECT N'dm_exec_query_stats' AS teste, COUNT(*) AS linhas FROM sys.dm_exec_query_stats;
GO
SELECT N'query_store_query' AS teste, COUNT(*) AS linhas FROM sys.query_store_query;
GO
SELECT N'query_store_query_text' AS teste, COUNT(*) AS linhas FROM sys.query_store_query_text;
GO
SELECT N'query_store_plan' AS teste, COUNT(*) AS linhas FROM sys.query_store_plan;
GO
SELECT N'OBJECT_DEFINITION da view' AS teste,
       CASE WHEN OBJECT_DEFINITION(OBJECT_ID(N'relatorios.vw_faturamento_itens')) IS NULL THEN N'NULL' ELSE N'legivel' END AS resultado;
GO
SELECT N'sql_expression_dependencies' AS teste, COUNT(*) AS linhas FROM sys.sql_expression_dependencies;
GO
SELECT N'dm_sql_referenced_entities' AS teste, COUNT(*) AS linhas FROM sys.dm_sql_referenced_entities(N'relatorios.vw_faturamento_itens', N'OBJECT');
GO
SELECT N'dados: SELECT na view' AS teste, COUNT(*) AS linhas FROM relatorios.vw_faturamento_itens;
GO
