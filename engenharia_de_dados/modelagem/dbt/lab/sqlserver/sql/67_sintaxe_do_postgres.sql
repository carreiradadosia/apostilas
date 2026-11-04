PRINT N'== Sintaxe do laboratório em Postgres que não passa aqui. Cada erro vem com a troca usada no laboratório.';
GO
PRINT N'-- JOIN USING: troca por ON.';
GO
SELECT l.nome FROM silver.lojas l JOIN gold.dim_loja d USING (loja_id);
GO
PRINT N'-- FILTER (WHERE): troca por SUM(CASE WHEN ...).';
GO
SELECT COUNT(*) FILTER (WHERE status = N'pago') AS pagos FROM silver.pedidos;
GO
PRINT N'-- GROUP BY 1: troca pela coluna ou expressão.';
GO
SELECT status, COUNT(*) AS pedidos FROM silver.pedidos GROUP BY 1;
GO
PRINT N'-- x::date: troca por CAST ou CONVERT.';
GO
SELECT criado_em_utc::date AS dia FROM silver.pedidos;
GO
PRINT N'-- LIMIT: troca por TOP ou OFFSET FETCH.';
GO
SELECT pedido_id FROM silver.pedidos ORDER BY pedido_id LIMIT 1;
GO
PRINT N'-- CREATE TABLE AS: troca por SELECT INTO.';
GO
CREATE TABLE silver.tentativa AS SELECT pedido_id FROM silver.pedidos;
GO
PRINT N'-- DROP TABLE ... CASCADE: não existe. A ordem de remoção é de quem escreve.';
GO
DROP TABLE IF EXISTS silver.nao_existe CASCADE;
GO
PRINT N'-- boolean: troca por bit, com CASE.';
GO
SELECT pedido_id, status = N'pago' AS foi_pago FROM silver.pedidos;
GO
PRINT N'-- timestamp não é data e hora aqui: é sinônimo de rowversion.';
GO
DROP TABLE IF EXISTS #t;
CREATE TABLE #t (id int, momento timestamp);
INSERT INTO #t (id) VALUES (1);
SELECT c.name, ty.name AS tipo, c.max_length
FROM tempdb.sys.columns c JOIN tempdb.sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID('tempdb..#t') ORDER BY c.column_id;
GO
