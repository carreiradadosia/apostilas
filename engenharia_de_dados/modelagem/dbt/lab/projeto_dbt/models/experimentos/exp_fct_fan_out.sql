-- Fan-out on purpose: products with two suppliers multiply the fact rows.
select
    f.venda_sk,
    f.valor_item,
    f.status,
    f.data_id,
    pf.fornecedor
from {{ ref('fct_vendas') }} f
join {{ ref('dim_produto') }} p using (produto_sk)
join {{ source('bronze', 'produto_fornecedor') }} pf using (produto_id)
