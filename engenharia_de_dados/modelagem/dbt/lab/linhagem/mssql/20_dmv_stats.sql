-- Plan cache: what is still cached and its text. Only counts and text, no timing column.
SET NOCOUNT ON;
USE rede;
SELECT qs.execution_count AS execucoes,
       OBJECT_NAME(st.objectid, st.dbid) AS objeto,
       st.encrypted AS cifrado,
       CAST(LEFT(REPLACE(REPLACE(SUBSTRING(st.text, qs.statement_start_offset / 2 + 1,
            (CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text) ELSE qs.statement_end_offset END
             - qs.statement_start_offset) / 2 + 1), CHAR(10), ' '), CHAR(13), ' '), 170) AS nvarchar(170)) AS texto
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE (st.text LIKE N'%faturamento%' OR st.encrypted = 1)
  AND ISNULL(st.text, N'') NOT LIKE N'%dm_exec_query_stats%'
ORDER BY objeto, texto;
GO
