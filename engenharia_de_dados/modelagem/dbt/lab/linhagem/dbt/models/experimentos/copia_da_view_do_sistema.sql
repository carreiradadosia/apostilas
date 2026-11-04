-- Reads the system view: the graph stops at the source and never reaches the tables inside the view.
select loja, dia, sum(valor_item) as faturamento
from {{ source('sistema', 'vw_faturamento_itens') }}
group by loja, dia
