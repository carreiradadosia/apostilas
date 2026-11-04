select
    md5(loja_id::text) as loja_sk,
    loja_id,
    nome,
    cidade
from {{ ref('stg_lojas') }}
