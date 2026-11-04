{{ config(materialized='incremental') }}

-- No unique_key: dbt appends, so the lookback window duplicates rows on every reprocess.
select atendimento_id, loja_id, dia_local
from {{ ref('stg_atendimentos') }}
{% if is_incremental() %}
where dia_local >= (select max(dia_local) from {{ this }})
{% endif %}
