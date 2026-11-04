\pset border 1
\echo == Número certo do dia 20: um lado só, no grão do item.
SELECT sum(valor_item) FILTER (WHERE status = 'pago') AS receita_paga_dia_20
FROM gold.fct_vendas WHERE data_id = '2026-10-20';

\echo == Fan-out 1: dimensão com duas linhas para a mesma chave. Sem erro nenhum.
SELECT count(*) AS linhas,
       sum(f.valor_item) FILTER (WHERE f.status = 'pago') AS receita_dobrada
FROM gold.fct_vendas f
JOIN gold.dim_produto p USING (produto_sk)
JOIN bronze.produto_fornecedor pf USING (produto_id)
WHERE f.data_id = '2026-10-20';

\echo == Fan-out 2: dois lados muitos do mesmo pedido, itens e pagamentos.
SELECT f.pedido_id, count(*) AS linhas,
       sum(f.valor_item) AS soma_itens,
       sum(pg.valor) AS soma_pagamentos
FROM gold.fct_vendas f
JOIN bronze.pagamentos pg USING (pedido_id)
WHERE f.data_id = '2026-10-20' AND f.status = 'pago'
GROUP BY 1 ORDER BY 1;
\echo == SUM(DISTINCT) parece conserto: tira a repetição e leva junto a venda legítima de mesmo valor.
SELECT sum(f.valor_item) AS receita_com_join,
       sum(DISTINCT f.valor_item) AS receita_com_sum_distinct
FROM gold.fct_vendas f
JOIN bronze.pagamentos pg USING (pedido_id)
WHERE f.status = 'pago';
SELECT sum(valor_item) AS receita_certa_todos_os_dias
FROM gold.fct_vendas WHERE status = 'pago';

\echo == O conserto: agregar cada lado no próprio grão antes de juntar.
WITH itens AS (
    SELECT pedido_id, sum(valor_item) AS total_itens FROM gold.fct_vendas WHERE status = 'pago' GROUP BY 1
), pagos AS (
    SELECT pedido_id, sum(valor) AS total_pago FROM bronze.pagamentos GROUP BY 1
)
SELECT sum(total_itens) AS receita, sum(total_pago) AS pago, sum(total_itens) - sum(total_pago) AS diferenca
FROM itens JOIN pagos USING (pedido_id);

\echo == O teste do grão, em SQL puro: devolve linhas quando quebra.
SELECT 'fct_vendas' AS tabela, count(*) AS chaves_repetidas FROM (
    SELECT pedido_id, item_seq FROM gold.fct_vendas GROUP BY 1, 2 HAVING count(*) > 1) x
UNION ALL
SELECT 'itens com fornecedor', count(*) FROM (
    SELECT i.pedido_id, i.item_seq FROM silver.itens i
    JOIN bronze.produto_fornecedor pf USING (produto_id) GROUP BY 1, 2 HAVING count(*) > 1) x;
