-- Grain: one row per product and price period, plus one row for the unknown member.
-- The key comes from business columns, so hand SQL and dbt give the same key for the same version.
select
    md5(s.id::text || '|' || to_char(s.dbt_valid_from, 'YYYY-MM-DD')) as produto_sk,
    s.id as produto_id,
    p.nome,
    p.categoria,
    p.custo,
    s.preco as preco_tabela,
    s.dbt_valid_from::date as valido_de,
    s.dbt_valid_to::date as valido_ate
from {{ ref('snap_produtos_preco') }} s
join {{ ref('stg_produtos') }} p on p.produto_id = s.id

union all

-- A sale with no version points here: the revenue stays and a test counts it.
select '-1', null, 'Desconhecido', 'desconhecido', null, null, null, null
