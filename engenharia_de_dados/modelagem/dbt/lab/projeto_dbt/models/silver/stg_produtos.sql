-- Latest photo of each product, not the latest global one: a product that leaves
-- the last photo keeps its name and category, so its versions stay in the dimension.
with ultima_foto as (
    select distinct on (id) *
    from {{ source('bronze', 'produtos_foto') }}
    order by id, _dia_referencia desc
)

select
    u.id as produto_id,
    initcap(trim(u.nome)) as nome,
    coalesce(d.categoria, lower(unaccent(trim(u.categoria)))) as categoria,
    u.preco,
    -- stays null on purpose: unknown cost is not zero cost
    u.custo
from ultima_foto u
left join {{ ref('de_para_categoria') }} d
    on d.categoria_origem = lower(unaccent(trim(u.categoria)))
