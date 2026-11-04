{{ config(materialized='incremental', unique_key='atendimento_id') }}

-- Same lookback, with unique_key: the row that comes back replaces the old one.
select atendimento_id, loja_id, dia_local
from {{ ref('stg_atendimentos') }}
{% if is_incremental() %}
where dia_local >= (select max(dia_local) from {{ this }})
{% endif %}
