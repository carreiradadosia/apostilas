select
    dia_local as dia,
    count(*) as pedidos,
    sum(valor) filter (where status = 'pago') as receita_paga
from {{ ref('stg_pedidos') }}
group by dia_local
