-- Fictional store chain, same synthetic rows of the modeling lab. The business rule lives inside a
-- view and procedures, so the text of the report call does not reveal it.
-- $(APP_PW) and $(MON_PW) arrive through sqlcmd -v from the container environment.
CREATE DATABASE rede;
GO
USE rede;
GO
CREATE SCHEMA erp;
GO
CREATE SCHEMA relatorios;
GO
CREATE TABLE erp.lojas (
    id     int NOT NULL PRIMARY KEY,
    nome   nvarchar(100) NOT NULL,
    cidade nvarchar(100) NOT NULL
);
INSERT INTO erp.lojas VALUES
    (1, N'  Loja Centro ', N'São Paulo'),
    (2, N'LOJA NORTE',     N'SAO PAULO '),
    (3, N'loja são joão',  N'Santo André');

CREATE TABLE erp.pedidos (
    id        int NOT NULL PRIMARY KEY,
    loja_id   int NOT NULL REFERENCES erp.lojas (id),
    cliente   nvarchar(100) NULL,
    status    nvarchar(30) NULL,
    criado_em datetime2(0) NOT NULL
);
INSERT INTO erp.pedidos VALUES
    (101, 1, N'  Cliente A ', N'PAGO',      '2026-10-20T08:15:00'),
    (102, 1, N'Cliente B',    NULL,         '2026-10-20T09:40:00'),
    (103, 2, N'cliente c',    N'cancelado', '2026-10-20T18:05:00'),
    (104, 2, N'Cliente D',    N'pago',      '2026-10-20T21:30:00'),
    (105, 3, NULL,            N'pago',      '2026-10-21T00:10:00'),
    (106, 1, N'Cliente E',    N'pago',      '2026-10-21T10:00:00'),
    (107, 2, N'cliente f ',   N'pendente',  '2026-10-21T11:30:00'),
    (108, 1, N'Cliente G',    N'pago',      '2026-10-22T07:45:00'),
    (109, 3, N'Cliente H',    N' Pago ',    '2026-10-22T13:20:00'),
    (110, 2, N'',             N'pago',      '2026-10-22T23:30:00');

CREATE TABLE erp.itens_pedido (
    pedido_id      int NOT NULL REFERENCES erp.pedidos (id),
    item_seq       int NOT NULL,
    quantidade     int NOT NULL,
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
GO
-- The rule: revenue counts only paid orders, after normalizing the status text.
CREATE VIEW relatorios.vw_faturamento_itens AS
SELECT p.id AS pedido_id,
       p.loja_id,
       l.nome AS loja,
       p.cliente,
       CAST(p.criado_em AS date) AS dia,
       i.quantidade * i.preco_unitario AS valor_item
FROM erp.pedidos AS p
JOIN erp.itens_pedido AS i ON i.pedido_id = p.id
JOIN erp.lojas AS l ON l.id = p.loja_id
WHERE LOWER(TRIM(p.status)) = N'pago';
GO
CREATE PROCEDURE relatorios.faturamento_por_loja @inicio date, @fim date AS
BEGIN
    SET NOCOUNT ON;
    SELECT TRIM(v.loja) AS loja, CAST(SUM(v.valor_item) AS numeric(14, 2)) AS faturamento
    FROM relatorios.vw_faturamento_itens AS v
    WHERE v.dia BETWEEN @inicio AND @fim
    GROUP BY TRIM(v.loja)
    ORDER BY loja;
END;
GO
-- Encrypted module: what a packaged system may ship.
CREATE PROCEDURE relatorios.faturamento_cifrado @inicio date, @fim date WITH ENCRYPTION AS
BEGIN
    SET NOCOUNT ON;
    SELECT TRIM(v.loja) AS loja, CAST(SUM(v.valor_item) AS numeric(14, 2)) AS faturamento
    FROM relatorios.vw_faturamento_itens AS v
    WHERE v.dia BETWEEN @inicio AND @fim
    GROUP BY TRIM(v.loja);
END;
GO
-- Dynamic SQL: the table names are only text until run time. EXECUTE AS OWNER because dynamic SQL
-- breaks the ownership chain and the application role has no grant on the erp schema.
CREATE PROCEDURE relatorios.faturamento_dinamico @inicio date, @fim date WITH EXECUTE AS OWNER AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql nvarchar(max) = N'SELECT TRIM(l.nome) AS loja, SUM(i.quantidade * i.preco_unitario) AS faturamento '
        + N'FROM erp.pedidos AS p JOIN erp.itens_pedido AS i ON i.pedido_id = p.id '
        + N'JOIN erp.lojas AS l ON l.id = p.loja_id '
        + N'WHERE LOWER(TRIM(p.status)) = N''pago'' AND CAST(p.criado_em AS date) BETWEEN @inicio AND @fim '
        + N'GROUP BY TRIM(l.nome);';
    EXEC sys.sp_executesql @sql, N'@inicio date, @fim date', @inicio, @fim;
END;
GO
-- WITH RECOMPILE: the plan is not kept in the cache, which the plan cache DMV depends on.
CREATE PROCEDURE relatorios.faturamento_recompila @inicio date, @fim date WITH RECOMPILE AS
BEGIN
    SET NOCOUNT ON;
    SELECT TRIM(v.loja) AS loja, COUNT_BIG(*) AS itens
    FROM relatorios.vw_faturamento_itens AS v
    WHERE v.dia BETWEEN @inicio AND @fim
    GROUP BY TRIM(v.loja);
END;
GO
-- Held open for a moment so the running request can be observed.
CREATE PROCEDURE relatorios.faturamento_lento @inicio date, @fim date AS
BEGIN
    SET NOCOUNT ON;
    WAITFOR DELAY '00:00:06';
    SELECT COUNT_BIG(*) AS itens FROM relatorios.vw_faturamento_itens AS v WHERE v.dia BETWEEN @inicio AND @fim;
END;
GO
CREATE LOGIN app_relatorio WITH PASSWORD = N'$(APP_PW)';  -- higiene:ignore, sqlcmd variable
CREATE LOGIN leitor_monitor WITH PASSWORD = N'$(MON_PW)';  -- higiene:ignore, sqlcmd variable
GO
CREATE USER app_relatorio FOR LOGIN app_relatorio;
CREATE USER leitor_monitor FOR LOGIN leitor_monitor;
GRANT EXECUTE, SELECT ON SCHEMA::relatorios TO app_relatorio;
GO
