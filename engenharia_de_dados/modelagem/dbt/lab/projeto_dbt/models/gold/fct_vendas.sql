-- Grain: one row per order item. The day goes in the half-open interval of the price period.
select
    md5(i.pedido_id::text || '|' || i.item_seq::text) as venda_sk,
    i.pedido_id,
    i.item_seq,
    l.loja_sk,
    coalesce(dp.produto_sk, '-1') as produto_sk,
    o.dia_local as data_id,
    o.status,
    i.quantidade,
    i.preco_unitario,
    i.valor_item,
    dp.preco_tabela
from {{ ref('stg_itens') }} i
join {{ ref('stg_pedidos') }} o using (pedido_id)
join {{ ref('dim_loja') }} l using (loja_id)
left join {{ ref('dim_produto') }} dp
    on dp.produto_id = i.produto_id
    and o.dia_local >= dp.valido_de
    and (dp.valido_ate is null or o.dia_local < dp.valido_ate)
