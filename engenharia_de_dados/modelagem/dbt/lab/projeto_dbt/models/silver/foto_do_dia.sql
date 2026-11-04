{{ config(materialized='ephemeral') }}

-- The photo the snapshot reads: one day of the raw table, chosen by a variable.
-- foto_em is a timestamp because the snapshot meta columns are timestamps.
select
    id,
    nome,
    categoria,
    preco,
    custo,
    atualizado_em,
    _dia_referencia,
    _dia_referencia::timestamp as foto_em
from {{ source('bronze', 'produtos_foto') }}
where _dia_referencia = '{{ var("dia_foto") }}'::date
