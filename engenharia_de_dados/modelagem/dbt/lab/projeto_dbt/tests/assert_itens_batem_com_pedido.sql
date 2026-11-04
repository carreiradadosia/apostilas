-- Reconciliation: the items of an order must add up to the order value.
select o.pedido_id, o.valor, sum(i.valor_item) as soma_itens
from {{ ref('stg_pedidos') }} o
join {{ ref('stg_itens') }} i using (pedido_id)
group by 1, 2
having o.valor <> sum(i.valor_item)
