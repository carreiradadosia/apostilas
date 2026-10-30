-- One row per day for the dashboard, recomputed from silver on every run.
DELETE FROM gold.vendas_por_dia
WHERE dia = %(dia)s::date;

INSERT INTO gold.vendas_por_dia (dia, pedidos, pedidos_pagos, receita_paga)
SELECT
    %(dia)s::date,
    count(*),
    count(*) FILTER (WHERE status = 'pago'),
    COALESCE(sum(valor) FILTER (WHERE status = 'pago'), 0)
FROM silver.pedidos
WHERE dia_local = %(dia)s::date;
