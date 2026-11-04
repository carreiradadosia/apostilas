{{ config(materialized='view') }}

-- One big table: a consumption view over the star, not a second source of truth.
select
    f.venda_sk,
    f.pedido_id,
    f.item_seq,
    f.data_id,
    d.mes,
    d.fim_de_semana,
    l.nome as loja,
    l.cidade,
    p.nome as produto,
    p.categoria,
    f.status,
    f.quantidade,
    f.preco_unitario,
    f.valor_item,
    f.preco_tabela
from {{ ref('fct_vendas') }} f
join {{ ref('dim_data') }} d using (data_id)
join {{ ref('dim_loja') }} l using (loja_sk)
left join {{ ref('dim_produto') }} p using (produto_sk)
