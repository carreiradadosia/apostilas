select
    id as loja_id,
    initcap(trim(nome)) as nome,
    initcap(unaccent(trim(cidade))) as cidade,
    fecha_as
from {{ source('bronze', 'lojas') }}
