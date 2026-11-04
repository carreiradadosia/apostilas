-- Numbers from the Postgres lab (saidas/lab1 to lab4 of the parent folder) against this server.
-- Runs after Lab 4, with the three photos loaded, so the expected value of each row is the one Lab 4 shows.
WITH conferencia AS (
    SELECT N'bronze.pedidos, linhas' AS item, CAST(11 AS numeric(14, 2)) AS postgres,
           CAST((SELECT COUNT(*) FROM bronze.pedidos) AS numeric(14, 2)) AS sql_server
    UNION ALL SELECT N'silver.pedidos, linhas', 10, (SELECT COUNT(*) FROM silver.pedidos)
    UNION ALL SELECT N'silver.itens, linhas', 13, (SELECT COUNT(*) FROM silver.itens)
    UNION ALL SELECT N'silver.lojas, linhas', 3, (SELECT COUNT(*) FROM silver.lojas)
    UNION ALL SELECT N'silver.produtos, linhas', 5, (SELECT COUNT(*) FROM silver.produtos)
    UNION ALL SELECT N'silver.produtos_vigencia, linhas', 7, (SELECT COUNT(*) FROM silver.produtos_vigencia)
    UNION ALL SELECT N'silver.atendimentos, linhas', 4, (SELECT COUNT(*) FROM silver.atendimentos)
    UNION ALL SELECT N'status pago, pedidos', 7, (SELECT COUNT(*) FROM silver.pedidos WHERE status = N'pago')
    UNION ALL SELECT N'status pago, valor', 836.10, (SELECT SUM(valor) FROM silver.pedidos WHERE status = N'pago')
    UNION ALL SELECT N'status desconhecido, valor', 80.50, (SELECT SUM(valor) FROM silver.pedidos WHERE status = N'desconhecido')
    UNION ALL SELECT N'status cancelado, valor', 45.00, (SELECT SUM(valor) FROM silver.pedidos WHERE status = N'cancelado')
    UNION ALL SELECT N'status pendente, valor', 15.00, (SELECT SUM(valor) FROM silver.pedidos WHERE status = N'pendente')
    UNION ALL SELECT N'gold.dim_data, linhas', 92, (SELECT COUNT(*) FROM gold.dim_data)
    UNION ALL SELECT N'gold.dim_loja, linhas', 3, (SELECT COUNT(*) FROM gold.dim_loja)
    UNION ALL SELECT N'gold.dim_produto, linhas', 8, (SELECT COUNT(*) FROM gold.dim_produto)
    UNION ALL SELECT N'gold.dim_produto, membro -1', 1, (SELECT COUNT(*) FROM gold.dim_produto WHERE produto_sk = '-1')
    UNION ALL SELECT N'gold.fct_vendas, vendas no membro -1', 0, (SELECT COUNT(*) FROM gold.fct_vendas WHERE produto_sk = '-1')
    UNION ALL SELECT N'gold.fct_vendas, linhas', 13, (SELECT COUNT(*) FROM gold.fct_vendas)
    UNION ALL SELECT N'gold.fct_vendas, chaves', 13, (SELECT COUNT(DISTINCT venda_sk) FROM gold.fct_vendas)
    UNION ALL SELECT N'receita paga, dia 20', 430.90, (SELECT receita_paga FROM gold.vendas_por_dia WHERE dia = '2026-10-20')
    UNION ALL SELECT N'receita paga, dia 21', 111.90, (SELECT receita_paga FROM gold.vendas_por_dia WHERE dia = '2026-10-21')
    UNION ALL SELECT N'receita paga, dia 22', 293.30, (SELECT receita_paga FROM gold.vendas_por_dia WHERE dia = '2026-10-22')
    UNION ALL SELECT N'receita paga, total', 836.10, (SELECT SUM(receita_paga) FROM gold.vendas_por_dia)
    UNION ALL SELECT N'fotos, linhas', 15, (SELECT COUNT(*) FROM bronze.produtos_foto)
    UNION ALL SELECT N'fan-out 1, linhas', 9,
        (SELECT COUNT(*) FROM gold.fct_vendas f
         JOIN gold.dim_produto p ON p.produto_sk = f.produto_sk
         JOIN bronze.produto_fornecedor pf ON pf.produto_id = p.produto_id
         WHERE f.data_id = '2026-10-20')
    UNION ALL SELECT N'fan-out 1, receita dobrada', 850.90,
        (SELECT SUM(CASE WHEN f.status = N'pago' THEN f.valor_item END) FROM gold.fct_vendas f
         JOIN gold.dim_produto p ON p.produto_sk = f.produto_sk
         JOIN bronze.produto_fornecedor pf ON pf.produto_id = p.produto_id
         WHERE f.data_id = '2026-10-20')
    UNION ALL SELECT N'fan-out 2, receita com join', 1347.00,
        (SELECT SUM(f.valor_item) FROM gold.fct_vendas f
         JOIN bronze.pagamentos pg ON pg.pedido_id = f.pedido_id WHERE f.status = N'pago')
    UNION ALL SELECT N'fan-out 2, sum distinct', 716.10,
        (SELECT SUM(DISTINCT f.valor_item) FROM gold.fct_vendas f
         JOIN bronze.pagamentos pg ON pg.pedido_id = f.pedido_id WHERE f.status = N'pago')
    UNION ALL SELECT N'margem ignorando nulo', 397.10,
        (SELECT SUM(i.valor_item - i.quantidade * p.custo) FROM silver.itens i
         JOIN silver.produtos p ON p.produto_id = i.produto_id
         JOIN silver.pedidos o ON o.pedido_id = i.pedido_id WHERE o.status = N'pago')
    UNION ALL SELECT N'margem com zero', 409.10,
        (SELECT SUM(i.valor_item - i.quantidade * COALESCE(p.custo, 0)) FROM silver.itens i
         JOIN silver.produtos p ON p.produto_id = i.produto_id
         JOIN silver.pedidos o ON o.pedido_id = i.pedido_id WHERE o.status = N'pago')
    UNION ALL SELECT N'atendimentos no dia local 20', 3,
        (SELECT COUNT(*) FROM silver.atendimentos WHERE dia_local = '2026-10-20')
    UNION ALL SELECT N'atendimentos no dia local 21', 1,
        (SELECT COUNT(*) FROM silver.atendimentos WHERE dia_local = '2026-10-21')
)
SELECT item, postgres, sql_server,
       CASE WHEN postgres = sql_server THEN N'bate' ELSE N'DIVERGE' END AS resultado
FROM conferencia;
GO
