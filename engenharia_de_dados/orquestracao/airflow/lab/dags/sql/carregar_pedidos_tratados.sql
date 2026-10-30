-- Full overwrite inside one transaction: running it twice gives the same result.
BEGIN;

DELETE FROM pedidos_tratados;

INSERT INTO pedidos_tratados (id, cliente, valor, status, criado_em_utc)
SELECT
    id,
    COALESCE(NULLIF(initcap(trim(cliente)), ''), 'Não informado'),
    valor,
    COALESCE(status, 'desconhecido'),
    criado_em AT TIME ZONE 'America/Sao_Paulo'
FROM pedidos_origem;

COMMIT;
