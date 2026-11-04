-- Query Store: queries, their containing object and how many executions it counted.
-- Only counts and text, no duration or CPU column.
SET NOCOUNT ON;
USE rede;
SELECT q.query_id,
       ISNULL(OBJECT_NAME(CAST(q.object_id AS int)), N'(ad hoc)') AS objeto,
       q.query_parameterization_type_desc AS parametrizacao,
       t.is_part_of_encrypted_module AS cifrado,
       SUM(rs.count_executions) AS execucoes,
       CAST(LEFT(REPLACE(REPLACE(t.query_sql_text, CHAR(10), ' '), CHAR(13), ' '), 165) AS nvarchar(165)) AS texto
FROM sys.query_store_query AS q
JOIN sys.query_store_query_text AS t ON t.query_text_id = q.query_text_id
LEFT JOIN sys.query_store_plan AS p ON p.query_id = q.query_id
LEFT JOIN sys.query_store_runtime_stats AS rs ON rs.plan_id = p.plan_id
WHERE q.is_internal_query = 0
  AND t.query_sql_text NOT LIKE N'%query_store%'
  AND t.query_sql_text NOT LIKE N'%sys.%'
  AND t.query_sql_text NOT LIKE N'%SERVERPROPERTY%'
  AND t.query_sql_text NOT LIKE N'%@@SPID%'
  AND t.query_sql_text NOT LIKE N'%AS teste%'
  AND (t.query_sql_text LIKE N'%faturamento%' OR t.query_sql_text LIKE N'%erp.%'
       OR t.is_part_of_encrypted_module = 1 OR t.query_sql_text LIKE N'%marcador%')
GROUP BY q.query_id, q.object_id, q.query_parameterization_type_desc, t.is_part_of_encrypted_module, t.query_sql_text
ORDER BY objeto, q.query_id;
GO
