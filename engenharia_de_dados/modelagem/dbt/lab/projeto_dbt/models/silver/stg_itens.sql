select
    pedido_id,
    item_seq,
    produto_id,
    quantidade,
    preco_unitario,
    quantidade * preco_unitario as valor_item
from {{ source('bronze', 'itens_pedido') }}
