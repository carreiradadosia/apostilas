select
    pedido_id,
    quantidade * preco_unitario as valor_item
from {{ source('erp', 'itens_pedido') }}
