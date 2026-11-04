-- Ingestion stand-in: copies the replica into bronze as it is. Bronze adds load metadata, never cleans.
TRUNCATE TABLE bronze.lojas;
TRUNCATE TABLE bronze.pedidos;
TRUNCATE TABLE bronze.itens_pedido;
TRUNCATE TABLE bronze.pagamentos;
TRUNCATE TABLE bronze.produto_fornecedor;
TRUNCATE TABLE bronze.atendimentos;

-- Earlier load on purpose: order 103 was still pending at 18:30, so bronze holds it twice.
INSERT INTO bronze.pedidos
    (id, loja_id, cliente, valor, valor_texto, status, emissao_texto, criado_em, atualizado_em, _carregado_em)
VALUES
    (103, 2, N'cliente c', 45.00, N'45,00', N'pendente', N'20/10/2026',
     '2026-10-20 18:05', '2026-10-20 18:05', '2026-10-20 18:30 -03:00');

INSERT INTO bronze.lojas (id, nome, cidade, fecha_as)
SELECT id, nome, cidade, fecha_as FROM replica.lojas;

INSERT INTO bronze.pedidos
    (id, loja_id, cliente, valor, valor_texto, status, emissao_texto, criado_em, atualizado_em)
SELECT id, loja_id, cliente, valor, valor_texto, status, emissao_texto, criado_em, atualizado_em
FROM replica.pedidos;

INSERT INTO bronze.itens_pedido (pedido_id, item_seq, produto_id, quantidade, preco_unitario)
SELECT pedido_id, item_seq, produto_id, quantidade, preco_unitario FROM replica.itens_pedido;

INSERT INTO bronze.pagamentos (pedido_id, parcela, valor)
SELECT pedido_id, parcela, valor FROM replica.pagamentos;

INSERT INTO bronze.produto_fornecedor (produto_id, fornecedor)
SELECT produto_id, fornecedor FROM replica.produto_fornecedor;

INSERT INTO bronze.atendimentos (id, loja_id, criado_em_utc, atendido_em_utc)
SELECT id, loja_id, criado_em_utc, atendido_em_utc FROM replica.atendimentos;

SELECT N'bronze.pedidos' AS tabela, COUNT(*) AS linhas FROM bronze.pedidos
UNION ALL SELECT N'replica.pedidos', COUNT(*) FROM replica.pedidos;
