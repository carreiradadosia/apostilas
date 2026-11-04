-- Texts and plans against the runtime counters: they do not reach the disk at the same moment.
SET NOCOUNT ON;
USE rede;
SELECT (SELECT COUNT(*) FROM sys.query_store_query_text) AS textos,
       (SELECT COUNT(*) FROM sys.query_store_plan) AS planos,
       (SELECT COUNT(*) FROM sys.query_store_query_text WHERE query_sql_text LIKE N'%marcador_antes_da_queda%'
                                                          AND query_sql_text NOT LIKE N'%query_store%') AS texto_do_marcador,
       (SELECT ISNULL(SUM(count_executions), 0) FROM sys.query_store_runtime_stats) AS execucoes_contadas;
GO
