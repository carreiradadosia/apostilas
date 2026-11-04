-- Gold star. Grain written before the SQL:
--   fct_vendas: one row per order item.
--   dim_produto: one row per product and price period (type 2), plus one row for the unknown member.
--   dim_loja: one row per store. dim_data: one row per calendar day.
-- Hash keys here for the same reason as the Postgres lab: the star is rebuilt from silver and the key has
-- to survive the rebuild. 65_chave_substituta.sql shows what IDENTITY does in that same rebuild.
SET XACT_ABORT ON;
GO
BEGIN TRANSACTION;

DROP VIEW IF EXISTS gold.obt_vendas;
DROP TABLE IF EXISTS gold.vendas_por_dia, gold.fct_vendas, gold.dim_produto, gold.dim_loja, gold.dim_data;

-- Recursive CTE instead of GENERATE_SERIES: it runs before 2022 too. Weekday independent from SET DATEFIRST.
WITH dias AS (
    SELECT CONVERT(date, '20261001', 112) AS d
    UNION ALL
    SELECT DATEADD(day, 1, d) FROM dias WHERE d < CONVERT(date, '20261231', 112)
)
SELECT d AS data_id,
       YEAR(d) AS ano,
       MONTH(d) AS mes,
       ((DATEPART(weekday, d) + @@DATEFIRST - 2) % 7) + 1 AS dia_da_semana,
       CAST(CASE WHEN ((DATEPART(weekday, d) + @@DATEFIRST - 2) % 7) + 1 IN (6, 7) THEN 1 ELSE 0 END AS bit) AS fim_de_semana
INTO gold.dim_data
FROM dias
OPTION (MAXRECURSION 0);

SELECT CONVERT(char(64), HASHBYTES('SHA2_256', CONVERT(varchar(20), loja_id)), 2) AS loja_sk,
       loja_id, nome, cidade
INTO gold.dim_loja
FROM silver.lojas;

SELECT CONVERT(char(64), HASHBYTES('SHA2_256', CONCAT(v.produto_id, '|', CONVERT(char(10), v.valido_de, 23))), 2) AS produto_sk,
       v.produto_id, p.nome, p.categoria, p.custo, v.preco AS preco_tabela,
       v.valido_de, v.valido_ate
INTO gold.dim_produto
FROM silver.produtos_vigencia v
JOIN silver.produtos p ON p.produto_id = v.produto_id
UNION ALL
-- A sale with no version points here: the revenue stays and 70_conferencia_postgres.sql counts it.
SELECT '-1', NULL, N'Desconhecido', N'desconhecido', NULL, NULL, NULL, NULL;

-- The day goes in the half-open interval: from valido_de, up to but not including valido_ate.
SELECT CONVERT(char(64), HASHBYTES('SHA2_256', CONCAT(i.pedido_id, '|', i.item_seq)), 2) AS venda_sk,
       i.pedido_id, i.item_seq,
       l.loja_sk, COALESCE(dp.produto_sk, '-1') AS produto_sk, o.dia_local AS data_id,
       o.status,
       i.quantidade, i.preco_unitario, i.valor_item,
       dp.preco_tabela
INTO gold.fct_vendas
FROM silver.itens i
JOIN silver.pedidos o ON o.pedido_id = i.pedido_id
JOIN gold.dim_loja l ON l.loja_id = o.loja_id
LEFT JOIN gold.dim_produto dp
       ON dp.produto_id = i.produto_id
      AND o.dia_local >= dp.valido_de
      AND (dp.valido_ate IS NULL OR o.dia_local < dp.valido_ate);

-- Same daily table of the orchestration lab, now read from the star.
SELECT data_id AS dia,
       COUNT(DISTINCT pedido_id) AS pedidos,
       COUNT(DISTINCT CASE WHEN status = N'pago' THEN pedido_id END) AS pedidos_pagos,
       CAST(COALESCE(SUM(CASE WHEN status = N'pago' THEN valor_item END), 0) AS numeric(14, 2)) AS receita_paga
INTO gold.vendas_por_dia
FROM gold.fct_vendas
GROUP BY data_id;
GO
-- One big table: a consumption view over the star, not a second source of truth.
CREATE OR ALTER VIEW gold.obt_vendas AS
SELECT f.venda_sk, f.pedido_id, f.item_seq, f.data_id, d.mes, d.fim_de_semana,
       l.nome AS loja, l.cidade, p.nome AS produto, p.categoria, f.status,
       f.quantidade, f.preco_unitario, f.valor_item, f.preco_tabela
FROM gold.fct_vendas f
JOIN gold.dim_data d ON d.data_id = f.data_id
JOIN gold.dim_loja l ON l.loja_sk = f.loja_sk
LEFT JOIN gold.dim_produto p ON p.produto_sk = f.produto_sk;
GO
COMMIT;
GO
SELECT dia, pedidos, pedidos_pagos, receita_paga FROM gold.vendas_por_dia ORDER BY dia;
SELECT COUNT(*) AS linhas_fct, COUNT(DISTINCT venda_sk) AS chaves_fct,
       (SELECT COUNT(*) FROM silver.itens) AS itens_silver,
       (SELECT COUNT(*) FROM gold.obt_vendas) AS linhas_obt,
       (SELECT SUM(CASE WHEN status = N'pago' THEN valor_item END) FROM gold.obt_vendas) AS receita_obt,
       (SELECT COUNT(*) FROM gold.dim_data) AS linhas_dim_data
FROM gold.fct_vendas;

INSERT INTO controle.carga (executor, linhas_bronze, linhas_silver, receita_paga)
SELECT N'a_mao', (SELECT COUNT(*) FROM bronze.pedidos), (SELECT COUNT(*) FROM silver.pedidos),
       (SELECT SUM(receita_paga) FROM gold.vendas_por_dia);
SELECT executor, linhas_bronze, linhas_silver, receita_paga FROM controle.carga ORDER BY id;
GO
