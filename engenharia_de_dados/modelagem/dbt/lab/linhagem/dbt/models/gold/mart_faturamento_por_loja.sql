with pedidos_pagos as (
    select pedido_id, loja_id, dia
    from {{ ref('stg_pedidos') }}
    where status = 'pago'
)

select
    l.loja,
    p.dia,
    sum(i.valor_item)::numeric(14, 2) as faturamento
from pedidos_pagos p
join {{ ref('stg_itens') }} i using (pedido_id)
join {{ ref('stg_lojas') }} l using (loja_id)
group by l.loja, p.dia
