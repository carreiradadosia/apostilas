PRINT N'== Número certo do dia 20: um lado só, no grão do item.';
SELECT SUM(CASE WHEN status = N'pago' THEN valor_item END) AS receita_paga_dia_20
FROM gold.fct_vendas
WHERE data_id = '2026-10-20';

PRINT N'== Fan-out 1: dimensão com duas linhas para a mesma chave. Sem erro nenhum.';
SELECT COUNT(*) AS linhas,
       SUM(CASE WHEN f.status = N'pago' THEN f.valor_item END) AS receita_dobrada
FROM gold.fct_vendas f
JOIN gold.dim_produto p ON p.produto_sk = f.produto_sk
JOIN bronze.produto_fornecedor pf ON pf.produto_id = p.produto_id
WHERE f.data_id = '2026-10-20';

PRINT N'== Fan-out 2: dois lados muitos do mesmo pedido, itens e pagamentos.';
SELECT f.pedido_id, COUNT(*) AS linhas,
       SUM(f.valor_item) AS soma_itens,
       SUM(pg.valor) AS soma_pagamentos
FROM gold.fct_vendas f
JOIN bronze.pagamentos pg ON pg.pedido_id = f.pedido_id
WHERE f.data_id = '2026-10-20' AND f.status = N'pago'
GROUP BY f.pedido_id
ORDER BY f.pedido_id;

PRINT N'== SUM(DISTINCT) parece conserto: tira a repetição e leva junto a venda legítima de mesmo valor.';
SELECT SUM(f.valor_item) AS receita_com_join,
       SUM(DISTINCT f.valor_item) AS receita_com_sum_distinct
FROM gold.fct_vendas f
JOIN bronze.pagamentos pg ON pg.pedido_id = f.pedido_id
WHERE f.status = N'pago';
SELECT SUM(valor_item) AS receita_certa_todos_os_dias
FROM gold.fct_vendas
WHERE status = N'pago';

PRINT N'== O conserto: agregar cada lado no próprio grão antes de juntar.';
WITH itens AS (
    SELECT pedido_id, SUM(valor_item) AS total_itens
    FROM gold.fct_vendas
    WHERE status = N'pago'
    GROUP BY pedido_id
), pagos AS (
    SELECT pedido_id, SUM(valor) AS total_pago
    FROM bronze.pagamentos
    GROUP BY pedido_id
)
SELECT SUM(i.total_itens) AS receita, SUM(p.total_pago) AS pago, SUM(i.total_itens) - SUM(p.total_pago) AS diferenca
FROM itens i JOIN pagos p ON p.pedido_id = i.pedido_id;

PRINT N'== O teste do grão, em SQL puro: devolve linhas quando quebra.';
SELECT N'fct_vendas' AS tabela, COUNT(*) AS chaves_repetidas FROM (
    SELECT pedido_id, item_seq FROM gold.fct_vendas GROUP BY pedido_id, item_seq HAVING COUNT(*) > 1) x
UNION ALL
SELECT N'itens com fornecedor', COUNT(*) FROM (
    SELECT i.pedido_id, i.item_seq
    FROM silver.itens i
    JOIN bronze.produto_fornecedor pf ON pf.produto_id = i.produto_id
    GROUP BY i.pedido_id, i.item_seq
    HAVING COUNT(*) > 1) x;
