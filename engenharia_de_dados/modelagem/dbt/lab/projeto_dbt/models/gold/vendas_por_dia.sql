-- Grain: one row per day. Same daily table of the orchestration lab, now read from the star.
select
    data_id as dia,
    count(distinct pedido_id)::int as pedidos,
    (count(distinct pedido_id) filter (where status = 'pago'))::int as pedidos_pagos,
    coalesce(sum(valor_item) filter (where status = 'pago'), 0)::numeric(14, 2) as receita_paga
from {{ ref('fct_vendas') }}
group by data_id
