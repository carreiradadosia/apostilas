-- Same silver rules of the Postgres lab, written for DuckDB.
with ultima_carga as (
    select
        *,
        row_number() over (partition by id order by _carregado_em desc) as ordem
    from {{ ref('bronze_pedidos') }}
)

select
    id as pedido_id,
    loja_id,
    coalesce(nullif(trim(cliente), ''), 'Não informado') as cliente,
    valor,
    case lower(trim(status))
        when 'pago' then 'pago'
        when 'cancelado' then 'cancelado'
        when 'pendente' then 'pendente'
        else 'desconhecido'
    end as status,
    strptime(emissao_texto, '%d/%m/%Y')::date as dia_emissao,
    criado_em::date as dia_local
from ultima_carga
where ordem = 1
