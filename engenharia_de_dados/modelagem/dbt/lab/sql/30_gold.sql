-- Gold star. Grain written before the SQL:
--   fct_vendas: one row per order item.
--   dim_produto: one row per product and price period (type 2), plus one row for the unknown member.
--   dim_loja: one row per store. dim_data: one row per calendar day.
DROP TABLE IF EXISTS gold.fct_vendas, gold.dim_produto, gold.dim_loja, gold.dim_data, gold.vendas_por_dia CASCADE;

CREATE TABLE gold.dim_data AS
SELECT d::date AS data_id,
       EXTRACT(year FROM d)::int AS ano,
       EXTRACT(month FROM d)::int AS mes,
       EXTRACT(isodow FROM d)::int AS dia_da_semana,
       EXTRACT(isodow FROM d) IN (6, 7) AS fim_de_semana
FROM generate_series(DATE '2026-10-01', DATE '2026-12-31', INTERVAL '1 day') AS d;

CREATE TABLE gold.dim_loja AS
SELECT md5(loja_id::text) AS loja_sk, loja_id, nome, cidade FROM silver.lojas;

CREATE TABLE gold.dim_produto AS
SELECT md5(v.produto_id::text || '|' || to_char(v.valido_de, 'YYYY-MM-DD')) AS produto_sk,
       v.produto_id, p.nome, p.categoria, p.custo, v.preco AS preco_tabela,
       v.valido_de, v.valido_ate
FROM silver.produtos_vigencia v
JOIN silver.produtos p USING (produto_id)
UNION ALL
-- A sale with no version points here: the revenue stays and a test counts it.
SELECT '-1', NULL, 'Desconhecido', 'desconhecido', NULL, NULL, NULL, NULL;

-- The day goes in the half-open interval: from valido_de, up to but not including valido_ate.
CREATE TABLE gold.fct_vendas AS
SELECT md5(i.pedido_id::text || '|' || i.item_seq::text) AS venda_sk,
       i.pedido_id, i.item_seq,
       l.loja_sk, COALESCE(dp.produto_sk, '-1') AS produto_sk, o.dia_local AS data_id,
       o.status,
       i.quantidade, i.preco_unitario, i.valor_item,
       dp.preco_tabela
FROM silver.itens i
JOIN silver.pedidos o USING (pedido_id)
JOIN gold.dim_loja l USING (loja_id)
LEFT JOIN gold.dim_produto dp
       ON dp.produto_id = i.produto_id
      AND o.dia_local >= dp.valido_de
      AND (dp.valido_ate IS NULL OR o.dia_local < dp.valido_ate);

-- Same daily table of the orchestration lab, now read from the star.
CREATE TABLE gold.vendas_por_dia AS
SELECT data_id AS dia,
       count(DISTINCT pedido_id)::int AS pedidos,
       count(DISTINCT pedido_id) FILTER (WHERE status = 'pago')::int AS pedidos_pagos,
       COALESCE(sum(valor_item) FILTER (WHERE status = 'pago'), 0)::numeric(14, 2) AS receita_paga
FROM gold.fct_vendas
GROUP BY data_id;

-- One big table: a consumption view over the star, not a second source of truth.
CREATE VIEW gold.obt_vendas AS
SELECT f.venda_sk, f.pedido_id, f.item_seq, f.data_id, d.mes, d.fim_de_semana,
       l.nome AS loja, l.cidade, p.nome AS produto, p.categoria, f.status,
       f.quantidade, f.preco_unitario, f.valor_item, f.preco_tabela
FROM gold.fct_vendas f
JOIN gold.dim_data d USING (data_id)
JOIN gold.dim_loja l USING (loja_sk)
LEFT JOIN gold.dim_produto p USING (produto_sk);

SELECT dia, pedidos, pedidos_pagos, receita_paga FROM gold.vendas_por_dia ORDER BY dia;
SELECT count(*) AS linhas_fct, count(DISTINCT venda_sk) AS chaves_fct,
       (SELECT count(*) FROM silver.itens) AS itens_silver,
       (SELECT count(*) FROM gold.obt_vendas) AS linhas_obt,
       (SELECT sum(valor_item) FILTER (WHERE status = 'pago') FROM gold.obt_vendas) AS receita_obt
FROM gold.fct_vendas;

INSERT INTO controle.carga (executor, linhas_bronze, linhas_silver, receita_paga)
SELECT 'a_mao', (SELECT count(*) FROM bronze.pedidos), (SELECT count(*) FROM silver.pedidos),
       (SELECT sum(receita_paga) FROM gold.vendas_por_dia);
SELECT executor, linhas_bronze, linhas_silver, receita_paga FROM controle.carga ORDER BY id;
