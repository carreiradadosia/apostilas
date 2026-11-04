-- Sold price or list price? Three paid-revenue numbers over the same items. Run after Lab 4 (three photos).
\pset border 1
\pset null '<nulo>'

\echo == Que colunas de preço, valor e quantidade existem na bronze. Não há coluna de desconto nem de promoção.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'bronze' AND table_name IN ('itens_pedido', 'produtos_foto', 'pedidos')
  AND (column_name ILIKE '%preco%' OR column_name ILIKE '%valor%' OR column_name ILIKE '%custo%'
       OR column_name ILIKE '%desconto%' OR column_name ILIKE '%promo%' OR column_name ILIKE '%quantidade%')
ORDER BY 1, 2;

\echo == Três números de receita paga, três perguntas.
SELECT 'praticado: quantidade * preco_unitario do item' AS conta, sum(f.valor_item) AS receita_paga
FROM gold.fct_vendas f WHERE f.status = 'pago'
UNION ALL
SELECT 'tabela na data: quantidade * preco_tabela da versão', sum(f.quantidade * f.preco_tabela)
FROM gold.fct_vendas f WHERE f.status = 'pago'
UNION ALL
SELECT 'tabela de hoje: quantidade * preço da versão aberta', sum(f.quantidade * a.preco)
FROM gold.fct_vendas f
JOIN silver.itens i USING (pedido_id, item_seq)
JOIN silver.produtos_vigencia a ON a.produto_id = i.produto_id AND a.valido_ate IS NULL
WHERE f.status = 'pago'
UNION ALL
SELECT 'conferência: soma de pedidos.valor pagos na silver', sum(valor)
FROM silver.pedidos WHERE status = 'pago';

\echo == As linhas em que os três preços diferem, com todos os status.
SELECT f.pedido_id, f.item_seq, f.status, f.data_id, i.produto_id, f.quantidade,
       f.preco_unitario AS praticado, f.preco_tabela AS tabela_na_data, a.preco AS tabela_de_hoje
FROM gold.fct_vendas f
JOIN silver.itens i USING (pedido_id, item_seq)
JOIN silver.produtos_vigencia a ON a.produto_id = i.produto_id AND a.valido_ate IS NULL
WHERE f.preco_unitario <> f.preco_tabela OR f.preco_tabela <> a.preco
ORDER BY 1, 2;

\echo == Preço unitário não soma: média simples e média ponderada da caneca.
SELECT i.produto_id, count(*) AS itens, sum(f.quantidade) AS unidades,
       round(avg(f.preco_unitario), 2) AS media_simples,
       round(sum(f.valor_item) / sum(f.quantidade), 2) AS media_ponderada
FROM gold.fct_vendas f JOIN silver.itens i USING (pedido_id, item_seq)
WHERE i.produto_id = 30 GROUP BY 1;
