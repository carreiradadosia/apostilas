-- The stored plan names the base tables even though the procedure only mentions the view.
SET NOCOUNT ON;
USE rede;
;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT DISTINCT OBJECT_NAME(CAST(q.object_id AS int)) AS procedimento,
       n.o.value('@Schema', 'nvarchar(40)') AS esquema,
       n.o.value('@Table', 'nvarchar(40)') AS tabela
FROM sys.query_store_plan AS p
JOIN sys.query_store_query AS q ON q.query_id = p.query_id
CROSS APPLY (SELECT TRY_CAST(p.query_plan AS xml)) AS plano (x)
CROSS APPLY plano.x.nodes('//Object') AS n (o)
WHERE q.object_id IN (OBJECT_ID(N'relatorios.faturamento_por_loja'), OBJECT_ID(N'relatorios.faturamento_cifrado'))
ORDER BY procedimento, tabela;
GO
-- Is there any column that says who ran it or from which application?
SELECT OBJECT_NAME(c.object_id) AS visao, COUNT(*) AS colunas,
       SUM(CASE WHEN c.name LIKE N'%login%' OR c.name LIKE N'%user%' OR c.name LIKE N'%principal%'
                  OR c.name LIKE N'%app%' OR c.name LIKE N'%host%' OR c.name LIKE N'%program%'
                THEN 1 ELSE 0 END) AS colunas_de_identidade
FROM sys.all_columns AS c
WHERE c.object_id IN (OBJECT_ID(N'sys.query_store_query'), OBJECT_ID(N'sys.query_store_query_text'),
                      OBJECT_ID(N'sys.query_store_plan'), OBJECT_ID(N'sys.query_store_runtime_stats'),
                      OBJECT_ID(N'sys.dm_exec_query_stats'))
GROUP BY c.object_id
ORDER BY visao;
GO
