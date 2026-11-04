-- Exercise input: a new table of the store chain, returns, as the source delivered them.
-- On purpose: padded text, mixed case, a redundant text column, UTC in a column without zone,
-- a return with unknown value and return 3 loaded twice.
DROP TABLE IF EXISTS bronze.devolucoes;
CREATE TABLE bronze.devolucoes (
    id                integer,
    pedido_id         integer,
    item_seq          integer,
    motivo            text,
    valor_devolvido   numeric(12, 2),
    valor_texto       text,
    registrada_em_utc timestamp without time zone,
    _carregado_em     timestamptz NOT NULL
);

INSERT INTO bronze.devolucoes VALUES
    (1, 101, 1, ' DEFEITO ',       60.00, '60,00', '2026-10-21 14:10', '2026-10-22 06:00-03'),
    (2, 104, 2, 'troca',           10.90, '10,90', '2026-10-21 00:30', '2026-10-22 06:00-03'),
    (3, 106, 1, 'em analise',      33.30, '33,30', '2026-10-22 00:40', '2026-10-22 06:00-03'),
    (3, 106, 1, 'Defeito',         33.30, '33,30', '2026-10-22 00:40', '2026-10-23 06:00-03'),
    (4, 108, 2, 'arrependimento ',  NULL,    NULL, '2026-10-22 16:00', '2026-10-23 06:00-03'),
    (5, 109, 1, 'Extraviado',      60.00, '60,00', '2026-10-22 18:20', '2026-10-23 06:00-03');

SELECT id, pedido_id, item_seq, motivo, valor_devolvido, valor_texto, registrada_em_utc,
       _carregado_em AT TIME ZONE 'America/Sao_Paulo' AS carregado_local
FROM bronze.devolucoes
ORDER BY id, _carregado_em;
