-- DROP plus SELECT INTO in one transaction, with a failure after the DROP: the table has to survive.
SET XACT_ABORT ON;
DROP TABLE IF EXISTS silver.reconstrucao_demo;
SELECT 1 AS versao, N'tabela antiga' AS conteudo INTO silver.reconstrucao_demo;

BEGIN TRANSACTION;
DROP TABLE silver.reconstrucao_demo;
SELECT 2 AS versao, CONVERT(date, N'31/02/2026', 103) AS conteudo INTO silver.reconstrucao_demo;
COMMIT;
GO
