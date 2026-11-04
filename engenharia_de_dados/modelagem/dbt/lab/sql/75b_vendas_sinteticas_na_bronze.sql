-- The same 4 synthetic sales of 75_venda_sem_versao.sql, now written to bronze so dbt sees them.
-- Changes the published revenue on purpose. Undo it by running 10_bronze_carga.sql again.
INSERT INTO bronze.pedidos (id, loja_id, cliente, valor, valor_texto, status, emissao_texto, criado_em, atualizado_em, _carregado_em) VALUES
    (900, 1, 'Cliente S', 60.00, '60,00', 'pago', '19/10/2026', '2026-10-19 12:00', '2026-10-19 12:00', now()),
    (901, 1, 'Cliente T', 20.50, '20,50', 'pago', '21/10/2026', '2026-10-21 22:30', '2026-10-21 22:30', now()),
    (902, 1, 'Cliente U', 20.50, '20,50', 'pago', '22/10/2026', '2026-10-22 01:00', '2026-10-22 01:00', now()),
    (903, 1, 'Cliente V',  9.00, '9,00',  'pago', '22/10/2026', '2026-10-22 15:00', '2026-10-22 15:00', now());
INSERT INTO bronze.itens_pedido (pedido_id, item_seq, produto_id, quantidade, preco_unitario, _carregado_em) VALUES
    (900, 1, 10, 1, 60.00, now()),
    (901, 1, 40, 1, 20.50, now()),
    (902, 1, 40, 1, 20.50, now()),
    (903, 1, 60, 1,  9.00, now());
SELECT i.pedido_id, i.produto_id, i.preco_unitario, p.criado_em, p.status
FROM bronze.itens_pedido i JOIN bronze.pedidos p ON p.id = i.pedido_id
WHERE i.pedido_id >= 900 ORDER BY 1;
