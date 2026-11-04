select
    id as loja_id,
    trim(nome) as loja
from {{ source('erp', 'lojas') }}
