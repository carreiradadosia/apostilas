-- Clean the day: nulls, padding, case, drop the redundant text column, local time to UTC.
DELETE FROM silver.pedidos
WHERE dia_local = %(dia)s::date;

INSERT INTO silver.pedidos (id, cliente, valor, status, criado_em_utc, dia_local)
SELECT
    id,
    COALESCE(NULLIF(initcap(trim(cliente)), ''), 'Não informado'),
    valor,
    COALESCE(lower(trim(status)), 'desconhecido'),
    criado_em AT TIME ZONE 'America/Sao_Paulo',
    criado_em::date
FROM bronze.pedidos
WHERE _dia_referencia = %(dia)s::date;
