DROP TABLE IF EXISTS silver.merge_demo, silver.merge_sem_chave;
CREATE TABLE silver.merge_demo (pedido_id int PRIMARY KEY, status nvarchar(20) NOT NULL);
CREATE TABLE silver.merge_sem_chave (pedido_id int NOT NULL, status nvarchar(20) NOT NULL);
INSERT INTO silver.merge_demo VALUES (103, N'pendente');
INSERT INTO silver.merge_sem_chave VALUES (103, N'pendente');
GO
PRINT N'== Chave repetida no lote, e ela já existe no alvo: erro 8672, nada gravado.';
MERGE silver.merge_demo AS t
USING (VALUES (103, N'pendente'), (103, N'cancelado')) AS s (pedido_id, status)
   ON t.pedido_id = s.pedido_id
WHEN MATCHED THEN UPDATE SET status = s.status
WHEN NOT MATCHED THEN INSERT (pedido_id, status) VALUES (s.pedido_id, s.status);
GO
SELECT pedido_id, status FROM silver.merge_demo ORDER BY pedido_id;
GO
PRINT N'== Chave repetida no lote, nova no alvo com PRIMARY KEY: não é 8672, é violação de chave, 2627.';
MERGE silver.merge_demo AS t
USING (VALUES (104, N'pago'), (104, N'estornado')) AS s (pedido_id, status)
   ON t.pedido_id = s.pedido_id
WHEN MATCHED THEN UPDATE SET status = s.status
WHEN NOT MATCHED THEN INSERT (pedido_id, status) VALUES (s.pedido_id, s.status);
GO
SELECT pedido_id, status FROM silver.merge_demo ORDER BY pedido_id;
GO
PRINT N'== Chave repetida no lote, nova no alvo sem chave: grava as duas e não reclama.';
MERGE silver.merge_sem_chave AS t
USING (VALUES (104, N'pago'), (104, N'estornado')) AS s (pedido_id, status)
   ON t.pedido_id = s.pedido_id
WHEN MATCHED THEN UPDATE SET status = s.status
WHEN NOT MATCHED THEN INSERT (pedido_id, status) VALUES (s.pedido_id, s.status);
GO
SELECT pedido_id, status FROM silver.merge_sem_chave ORDER BY pedido_id, status;
GO
PRINT N'== Sem ponto e vírgula no fim: erro 10713.';
GO
MERGE silver.merge_demo AS t
USING (VALUES (105, N'pago')) AS s (pedido_id, status)
   ON t.pedido_id = s.pedido_id
WHEN NOT MATCHED THEN INSERT (pedido_id, status) VALUES (s.pedido_id, s.status)
GO
PRINT N'== O conserto: deduplicar a fonte antes, no próprio grão.';
WITH lote AS (
    SELECT pedido_id, status, ordem_chegada,
           ROW_NUMBER() OVER (PARTITION BY pedido_id ORDER BY ordem_chegada DESC) AS ordem
    FROM (VALUES (103, N'pendente', 1), (103, N'cancelado', 2), (104, N'pago', 3)) AS v (pedido_id, status, ordem_chegada)
)
MERGE silver.merge_demo AS t
USING (SELECT pedido_id, status FROM lote WHERE ordem = 1) AS s
   ON t.pedido_id = s.pedido_id
WHEN MATCHED THEN UPDATE SET status = s.status
WHEN NOT MATCHED THEN INSERT (pedido_id, status) VALUES (s.pedido_id, s.status);
SELECT pedido_id, status FROM silver.merge_demo ORDER BY pedido_id;
GO
