-- Fictional store chain, same synthetic rows of the modeling lab. The business rule of the number
-- lives inside a view and a function, so the report text alone does not reveal it.
GRANT CREATE ON DATABASE rede TO erp_dono, transformador;
SET ROLE erp_dono;

CREATE SCHEMA erp;
CREATE SCHEMA relatorios;

CREATE TABLE erp.lojas (
    id       integer PRIMARY KEY,
    nome     text NOT NULL,
    cidade   text NOT NULL
);
INSERT INTO erp.lojas VALUES
    (1, '  Loja Centro ', 'São Paulo'),
    (2, 'LOJA NORTE',     'SAO PAULO '),
    (3, 'loja são joão',  'Santo André');

CREATE TABLE erp.pedidos (
    id        integer PRIMARY KEY,
    loja_id   integer NOT NULL REFERENCES erp.lojas (id),
    cliente   text,
    status    text,
    criado_em timestamp without time zone NOT NULL
);
INSERT INTO erp.pedidos VALUES
    (101, 1, '  Cliente A ', 'PAGO',      '2026-10-20 08:15'),
    (102, 1, 'Cliente B',    NULL,        '2026-10-20 09:40'),
    (103, 2, 'cliente c',    'cancelado', '2026-10-20 18:05'),
    (104, 2, 'Cliente D',    'pago',      '2026-10-20 21:30'),
    (105, 3, NULL,           'pago',      '2026-10-21 00:10'),
    (106, 1, 'Cliente E',    'pago',      '2026-10-21 10:00'),
    (107, 2, 'cliente f ',   'pendente',  '2026-10-21 11:30'),
    (108, 1, 'Cliente G',    'pago',      '2026-10-22 07:45'),
    (109, 3, 'Cliente H',    ' Pago ',    '2026-10-22 13:20'),
    (110, 2, '',             'pago',      '2026-10-22 23:30');

CREATE TABLE erp.itens_pedido (
    pedido_id      integer NOT NULL REFERENCES erp.pedidos (id),
    item_seq       integer NOT NULL,
    quantidade     integer NOT NULL,
    preco_unitario numeric(12, 2) NOT NULL,
    PRIMARY KEY (pedido_id, item_seq)
);
INSERT INTO erp.itens_pedido VALUES
    (101, 1, 2, 60.00),
    (102, 1, 1, 60.00),
    (102, 2, 1, 20.50),
    (103, 1, 3, 15.00),
    (104, 1, 5, 60.00),
    (104, 2, 1, 10.90),
    (105, 1, 1, 12.00),
    (106, 1, 3, 33.30),
    (107, 1, 1, 15.00),
    (108, 1, 2, 60.00),
    (108, 2, 4, 20.00),
    (109, 1, 1, 60.00),
    (110, 1, 1, 33.30);

-- The rule: revenue counts only paid orders, after normalizing the status text.
CREATE VIEW relatorios.vw_faturamento_itens AS
SELECT p.id AS pedido_id,
       p.loja_id,
       l.nome AS loja,
       p.cliente,
       p.criado_em::date AS dia,
       i.quantidade * i.preco_unitario AS valor_item
FROM erp.pedidos p
JOIN erp.itens_pedido i ON i.pedido_id = p.id
JOIN erp.lojas l ON l.id = p.loja_id
WHERE lower(trim(p.status)) = 'pago';

-- PL/pgSQL body is a string literal: the catalog does not track what it reads.
CREATE FUNCTION relatorios.faturamento_por_loja(p_inicio date, p_fim date)
RETURNS TABLE (loja text, faturamento numeric)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    SELECT trim(v.loja), sum(v.valor_item)::numeric(14, 2)
    FROM relatorios.vw_faturamento_itens v
    WHERE v.dia BETWEEN p_inicio AND p_fim
    GROUP BY trim(v.loja)
    ORDER BY 1;
END
$$;

-- Same logic with a SQL-standard body: parsed at creation, so the dependency is recorded.
CREATE FUNCTION relatorios.faturamento_por_loja_padrao(p_inicio date, p_fim date)
RETURNS TABLE (loja text, faturamento numeric)
LANGUAGE sql STABLE
BEGIN ATOMIC
    SELECT trim(v.loja), sum(v.valor_item)::numeric(14, 2)
    FROM relatorios.vw_faturamento_itens v
    WHERE v.dia BETWEEN p_inicio AND p_fim
    GROUP BY trim(v.loja)
    ORDER BY 1;
END;

GRANT USAGE ON SCHEMA relatorios TO app_relatorio;
GRANT SELECT ON relatorios.vw_faturamento_itens TO app_relatorio;
GRANT USAGE ON SCHEMA erp, relatorios TO transformador;
GRANT SELECT ON ALL TABLES IN SCHEMA erp TO transformador;
GRANT SELECT ON relatorios.vw_faturamento_itens TO transformador;

RESET ROLE;
