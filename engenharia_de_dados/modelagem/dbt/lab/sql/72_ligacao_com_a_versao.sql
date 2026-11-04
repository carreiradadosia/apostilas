-- How a sale finds the price version in force on its day, over the 13 real items. Run after Lab 4 (three photos).
\pset border 1
\pset null '<nulo>'

\echo == Referência: a estrela do laboratório, feita por /sql/30_gold.sql.
SELECT count(*) AS linhas, count(DISTINCT venda_sk) AS chaves,
       sum(valor_item) FILTER (WHERE status = 'pago') AS receita_paga
FROM gold.fct_vendas;

\echo == Cada forma de ligar a venda à versão, sobre os mesmos 13 itens.
WITH vendas AS (
    SELECT i.pedido_id, i.item_seq, i.produto_id, i.valor_item, o.status, o.dia_local,
           o.criado_em_utc AT TIME ZONE 'America/Sao_Paulo' AS criado_em_local
    FROM silver.itens i JOIN silver.pedidos o USING (pedido_id)
), formas AS (
    SELECT 1 AS ordem, '>= e <, com fim nulo' AS forma, v.pedido_id, v.item_seq, v.valor_item, v.status
    FROM vendas v JOIN silver.produtos_vigencia d
      ON d.produto_id = v.produto_id AND v.dia_local >= d.valido_de
     AND (d.valido_ate IS NULL OR v.dia_local < d.valido_ate)
    UNION ALL
    SELECT 2, 'BETWEEN com fim em 9999-12-31', v.pedido_id, v.item_seq, v.valor_item, v.status
    FROM vendas v JOIN silver.produtos_vigencia d
      ON d.produto_id = v.produto_id
     AND v.dia_local BETWEEN d.valido_de AND COALESCE(d.valido_ate, DATE '9999-12-31')
    UNION ALL
    SELECT 3, 'BETWEEN com fim menos 1 dia, sobre date', v.pedido_id, v.item_seq, v.valor_item, v.status
    FROM vendas v JOIN silver.produtos_vigencia d
      ON d.produto_id = v.produto_id
     AND v.dia_local BETWEEN d.valido_de AND COALESCE(d.valido_ate - 1, DATE '9999-12-31')
    UNION ALL
    SELECT 4, 'BETWEEN com fim menos 1 dia, sobre timestamp', v.pedido_id, v.item_seq, v.valor_item, v.status
    FROM vendas v JOIN silver.produtos_vigencia d
      ON d.produto_id = v.produto_id
     AND v.criado_em_local BETWEEN d.valido_de AND COALESCE(d.valido_ate - 1, DATE '9999-12-31')
    UNION ALL
    SELECT 5, 'daterange com [)', v.pedido_id, v.item_seq, v.valor_item, v.status
    FROM vendas v JOIN silver.produtos_vigencia d
      ON d.produto_id = v.produto_id AND daterange(d.valido_de, d.valido_ate, '[)') @> v.dia_local
)
SELECT forma, count(*) AS linhas, count(DISTINCT (pedido_id, item_seq)) AS itens_distintos,
       sum(valor_item) FILTER (WHERE status = 'pago') AS receita_paga
FROM formas GROUP BY ordem, forma ORDER BY ordem;

\echo == A venda que o BETWEEN dobra: dia 22, o dia da troca de preço do caderno.
SELECT i.pedido_id, i.item_seq, o.dia_local, d.preco AS preco_tabela, d.valido_de, d.valido_ate, i.valor_item
FROM silver.itens i JOIN silver.pedidos o USING (pedido_id)
JOIN silver.produtos_vigencia d
  ON d.produto_id = i.produto_id
 AND o.dia_local BETWEEN d.valido_de AND COALESCE(d.valido_ate, DATE '9999-12-31')
WHERE i.pedido_id = 108 AND i.item_seq = 2 ORDER BY d.valido_de;

\echo == A venda que o BETWEEN sobre timestamp perde: 11h30 do dia 21, e o fim usado vira meia-noite do dia 21.
SELECT i.pedido_id, i.item_seq, o.status, o.criado_em_utc AT TIME ZONE 'America/Sao_Paulo' AS criado_em_local,
       d.valido_de, d.valido_ate, (d.valido_ate - 1)::timestamp AS fim_usado
FROM silver.itens i JOIN silver.pedidos o USING (pedido_id)
JOIN silver.produtos_vigencia d ON d.produto_id = i.produto_id AND d.valido_de = DATE '2026-10-20'
WHERE i.pedido_id = 107;

\echo == Só a versão aberta: itens antigos lidos com o preço de tabela de hoje.
SELECT f.pedido_id, f.item_seq, f.data_id, f.preco_tabela AS tabela_na_data, a.preco AS tabela_aberta
FROM gold.fct_vendas f
JOIN silver.itens i USING (pedido_id, item_seq)
JOIN silver.produtos_vigencia a ON a.produto_id = i.produto_id AND a.valido_ate IS NULL
WHERE f.preco_tabela <> a.preco ORDER BY 1, 2;

\echo == A vigência sai da foto diária, no calendário local. Pedidos que mudam de dia em UTC.
SELECT pedido_id, criado_em_utc AT TIME ZONE 'America/Sao_Paulo' AS hora_local, dia_local,
       (criado_em_utc AT TIME ZONE 'UTC')::date AS dia_em_utc
FROM silver.pedidos WHERE dia_local <> (criado_em_utc AT TIME ZONE 'UTC')::date ORDER BY 1;

\echo == Três eventos sintéticos e a meia-noite: BETWEEN conta a meia-noite em dois dias; >= e < conta uma vez.
WITH eventos (momento) AS (
    VALUES (TIMESTAMP '2026-10-20 10:00'), (TIMESTAMP '2026-10-21 00:00'), (TIMESTAMP '2026-10-21 15:00')
), dias (dia) AS (VALUES (DATE '2026-10-20'), (DATE '2026-10-21'))
SELECT d.dia,
       count(*) FILTER (WHERE e.momento BETWEEN d.dia AND d.dia + 1) AS com_between,
       count(*) FILTER (WHERE e.momento >= d.dia AND e.momento < d.dia + 1) AS com_meio_aberto
FROM dias d CROSS JOIN eventos e GROUP BY d.dia ORDER BY d.dia;
