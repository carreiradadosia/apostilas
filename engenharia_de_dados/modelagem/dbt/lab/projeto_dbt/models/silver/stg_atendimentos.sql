-- The source stores UTC in a column without zone: declare it as UTC, then read it in local time.
select
    id as atendimento_id,
    loja_id,
    coalesce(atendido_em_utc, criado_em_utc) at time zone 'UTC' as inicio_utc,
    coalesce(atendido_em_utc, criado_em_utc) at time zone 'UTC' at time zone 'America/Sao_Paulo' as inicio_local,
    (coalesce(atendido_em_utc, criado_em_utc) at time zone 'UTC' at time zone 'America/Sao_Paulo')::date as dia_local,
    atendido_em_utc is null as sem_atendido_em
from {{ source('bronze', 'atendimentos') }}
