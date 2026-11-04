\pset border 1
\echo == Same flow, two executors: hand SQL in silver and gold, dbt in dbt_silver and dbt_gold.
\echo == Each line counts the rows that exist on one side and not on the other. Zero means equal.
SELECT 'vendas_por_dia' AS tabela,
       (SELECT count(*) FROM (SELECT * FROM gold.vendas_por_dia EXCEPT SELECT * FROM dbt_gold.vendas_por_dia) x) AS so_a_mao,
       (SELECT count(*) FROM (SELECT * FROM dbt_gold.vendas_por_dia EXCEPT SELECT * FROM gold.vendas_por_dia) x) AS so_dbt
UNION ALL
SELECT 'fct_vendas',
       (SELECT count(*) FROM (SELECT venda_sk, pedido_id, item_seq, loja_sk, produto_sk, data_id, status, quantidade, preco_unitario, valor_item, preco_tabela FROM gold.fct_vendas
                              EXCEPT SELECT venda_sk, pedido_id, item_seq, loja_sk, produto_sk, data_id, status, quantidade, preco_unitario, valor_item, preco_tabela FROM dbt_gold.fct_vendas) x),
       (SELECT count(*) FROM (SELECT venda_sk, pedido_id, item_seq, loja_sk, produto_sk, data_id, status, quantidade, preco_unitario, valor_item, preco_tabela FROM dbt_gold.fct_vendas
                              EXCEPT SELECT venda_sk, pedido_id, item_seq, loja_sk, produto_sk, data_id, status, quantidade, preco_unitario, valor_item, preco_tabela FROM gold.fct_vendas) x)
UNION ALL
SELECT 'dim_produto',
       (SELECT count(*) FROM (SELECT produto_sk, produto_id, nome, categoria, custo, preco_tabela, valido_de, valido_ate FROM gold.dim_produto
                              EXCEPT SELECT produto_sk, produto_id, nome, categoria, custo, preco_tabela, valido_de, valido_ate FROM dbt_gold.dim_produto) x),
       (SELECT count(*) FROM (SELECT produto_sk, produto_id, nome, categoria, custo, preco_tabela, valido_de, valido_ate FROM dbt_gold.dim_produto
                              EXCEPT SELECT produto_sk, produto_id, nome, categoria, custo, preco_tabela, valido_de, valido_ate FROM gold.dim_produto) x)
UNION ALL
SELECT 'pedidos da silver',
       (SELECT count(*) FROM (SELECT * FROM silver.pedidos EXCEPT SELECT * FROM dbt_silver.stg_pedidos) x),
       (SELECT count(*) FROM (SELECT * FROM dbt_silver.stg_pedidos EXCEPT SELECT * FROM silver.pedidos) x)
UNION ALL
SELECT 'atendimentos da silver',
       (SELECT count(*) FROM (SELECT * FROM silver.atendimentos EXCEPT SELECT * FROM dbt_silver.stg_atendimentos) x),
       (SELECT count(*) FROM (SELECT * FROM dbt_silver.stg_atendimentos EXCEPT SELECT * FROM silver.atendimentos) x);

\echo == The surrogate key is part of the comparison above: both sides compute it from the same columns.
SELECT 'a_mao' AS lado, count(*) AS linhas, count(DISTINCT produto_sk) AS chaves FROM gold.dim_produto
UNION ALL SELECT 'dbt', count(*), count(DISTINCT produto_sk) FROM dbt_gold.dim_produto;

\echo == Where each one lives: hand tables and dbt relations side by side.
SELECT table_schema, table_type, count(*) AS objetos
FROM information_schema.tables
WHERE table_schema IN ('silver', 'gold', 'dbt_silver', 'dbt_gold', 'dbt_snapshots')
GROUP BY 1, 2 ORDER BY 1, 2;
