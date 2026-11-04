{{ config(severity='warn') }}

-- Warns when the source sends a status nobody mapped, so the else branch does not hide it.
select pedido_id, status_origem
from {{ ref('stg_pedidos') }}
where status = 'desconhecido'
