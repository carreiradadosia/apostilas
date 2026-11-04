-- Same reconciliation of the Postgres lab: the engine changes, the number does not.
select v.dia, v.receita_paga, t.esperado
from {{ ref('vendas_por_dia') }} as v
join (values (date '2026-10-20', 430.90), (date '2026-10-21', 111.90), (date '2026-10-22', 293.30)) as t(dia, esperado)
    on t.dia = v.dia
where v.receita_paga <> t.esperado
