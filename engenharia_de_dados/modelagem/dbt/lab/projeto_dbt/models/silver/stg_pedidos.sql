with ultima_carga as (
    select
        *,
        row_number() over (partition by id order by _carregado_em desc) as ordem
    from {{ source('bronze', 'pedidos') }}
)

select
    id as pedido_id,
    loja_id,
    coalesce(nullif(initcap(trim(cliente)), ''), 'Não informado') as cliente,
    valor,
    lower(trim(status)) as status_origem,
    case lower(trim(status))
        when 'pago' then 'pago'
        when 'cancelado' then 'cancelado'
        when 'pendente' then 'pendente'
        else 'desconhecido'
    end as status,
    to_date(emissao_texto, 'DD/MM/YYYY') as dia_emissao,
    criado_em at time zone 'America/Sao_Paulo' as criado_em_utc,
    criado_em::date as dia_local
from ultima_carga
where ordem = 1
