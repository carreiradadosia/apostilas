select
    id as pedido_id,
    loja_id,
    lower(trim(status)) as status,
    criado_em::date as dia
from {{ source('erp', 'pedidos') }}
