-- Ingestion bug on purpose: the item load runs a second time without the truncate.
-- Fix it by running 10_bronze_carga.sql again.
INSERT INTO bronze.itens_pedido SELECT *, now() FROM replica.itens_pedido WHERE pedido_id = 104;
SELECT pedido_id, item_seq, count(*) AS cargas FROM bronze.itens_pedido
WHERE pedido_id = 104 GROUP BY 1, 2 ORDER BY 1, 2;
