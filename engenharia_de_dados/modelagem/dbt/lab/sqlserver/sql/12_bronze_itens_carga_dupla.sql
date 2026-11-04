-- Ingestion bug on purpose: the item load runs a second time without the truncate.
-- Fix it by running 10_bronze_carga.sql again.
INSERT INTO bronze.itens_pedido (pedido_id, item_seq, produto_id, quantidade, preco_unitario)
SELECT pedido_id, item_seq, produto_id, quantidade, preco_unitario
FROM replica.itens_pedido
WHERE pedido_id = 104;

SELECT pedido_id, item_seq, COUNT(*) AS cargas
FROM bronze.itens_pedido
WHERE pedido_id = 104
GROUP BY pedido_id, item_seq
ORDER BY pedido_id, item_seq;
