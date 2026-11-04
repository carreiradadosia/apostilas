{{ config(severity='warn') }}

-- Warns when a sale found no product version, so the unknown member does not hide it.
select f.pedido_id, f.item_seq, f.data_id, i.produto_id, f.valor_item
from {{ ref('fct_vendas') }} f
join {{ ref('stg_itens') }} i using (pedido_id, item_seq)
where f.produto_sk = '-1'
