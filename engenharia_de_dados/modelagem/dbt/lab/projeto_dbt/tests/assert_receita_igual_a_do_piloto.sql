-- The star must not change the number the orchestration lab published.
select dia, receita_paga, esperado
from {{ ref('vendas_por_dia') }}
join (values (date '2026-10-20', 430.90), (date '2026-10-21', 111.90), (date '2026-10-22', 293.30)) as t(dia, esperado) using (dia)
where receita_paga <> esperado
