-- Ingestion stand-in: copies the replica into bronze as it is. Bronze adds load metadata, never cleans.
TRUNCATE bronze.lojas, bronze.pedidos, bronze.itens_pedido, bronze.pagamentos,
         bronze.produto_fornecedor, bronze.atendimentos;

-- Earlier load on purpose: order 103 was still pending at 18:30, so bronze holds it twice.
INSERT INTO bronze.pedidos VALUES
    (103, 2, 'cliente c', 45.00, '45,00', 'pendente', '20/10/2026',
     '2026-10-20 18:05', '2026-10-20 18:05', '2026-10-20 18:30-03');

INSERT INTO bronze.lojas SELECT *, now() FROM replica.lojas;
INSERT INTO bronze.pedidos SELECT *, now() FROM replica.pedidos;
INSERT INTO bronze.itens_pedido SELECT *, now() FROM replica.itens_pedido;
INSERT INTO bronze.pagamentos SELECT *, now() FROM replica.pagamentos;
INSERT INTO bronze.produto_fornecedor SELECT *, now() FROM replica.produto_fornecedor;
INSERT INTO bronze.atendimentos SELECT *, now() FROM replica.atendimentos;

SELECT 'bronze.pedidos' AS tabela, count(*) AS linhas FROM bronze.pedidos
UNION ALL SELECT 'replica.pedidos', count(*) FROM replica.pedidos;
