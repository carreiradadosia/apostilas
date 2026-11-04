-- Two databases on one server: erp plays the read-only replica of a fictional store chain ERP,
-- dw holds the bronze, silver and gold layers and reads the replica through synonyms.
-- Same synthetic data as the Postgres lab. A real replica is a separate server, see README.md.
CREATE DATABASE erp;
GO
CREATE DATABASE dw;
GO
USE erp;
GO
-- As the source systems store it: padded text, mixed case, nulls, a redundant text column.
CREATE TABLE dbo.lojas (
    id       int PRIMARY KEY,
    nome     nvarchar(100) NOT NULL,
    cidade   nvarchar(100) NOT NULL,
    fecha_as time(0) NOT NULL
);

INSERT INTO dbo.lojas VALUES
    (1, N'  Loja Centro ', N'São Paulo',   '22:00'),
    (2, N'LOJA NORTE',     N'SAO PAULO ',  '22:00'),
    (3, N'loja são joão',  N'Santo André', '20:00');

-- The ERP overwrites this table every night: no price history, and a nightly job touches
-- atualizado_em on every row even when nothing changed.
CREATE TABLE dbo.produtos (
    id            int PRIMARY KEY,
    nome          nvarchar(100) NOT NULL,
    categoria     nvarchar(100) NOT NULL,
    preco         numeric(12, 2) NOT NULL,
    custo         numeric(12, 2),
    atualizado_em datetime2(0) NOT NULL
);

INSERT INTO dbo.produtos VALUES
    (10, N'Camiseta básica',    N'Vestuário',  60.00, 30.00, '2026-10-20 03:00'),
    (20, N' CAFÉ TORRADO 500G', N'mercearia',  33.30, 20.00, '2026-10-20 03:00'),
    (30, N'caneca de cerâmica', N'UTILIDADES', 15.00,  7.00, '2026-10-20 03:00'),
    (40, N'Caderno',            N'Papelaria',  20.50, 10.00, '2026-10-20 03:00'),
    (50, N'Lápis',              N'Papelria ',  12.00,  NULL, '2026-10-20 03:00');

-- Same ten orders of the orchestration lab, now with a store and a text date.
CREATE TABLE dbo.pedidos (
    id            int PRIMARY KEY,
    loja_id       int NOT NULL REFERENCES dbo.lojas (id),
    cliente       nvarchar(100),
    valor         numeric(12, 2) NOT NULL,
    valor_texto   nvarchar(20),
    status        nvarchar(20),
    emissao_texto nvarchar(20) NOT NULL,
    criado_em     datetime2(0) NOT NULL,
    atualizado_em datetime2(0) NOT NULL
);

INSERT INTO dbo.pedidos VALUES
    (101, 1, N'  Cliente A ', 120.00, N'120,00', N'PAGO',      N'20/10/2026', '2026-10-20 08:15', '2026-10-20 08:15'),
    (102, 1, N'Cliente B',     80.50, N'80,50',  NULL,         N'20/10/2026', '2026-10-20 09:40', '2026-10-20 09:40'),
    (103, 2, N'cliente c',     45.00, N'45,00',  N'cancelado', N'20/10/2026', '2026-10-20 18:05', '2026-10-20 19:00'),
    (104, 2, N'Cliente D',    310.90, N'310,90', N'pago',      N'20/10/2026', '2026-10-20 21:30', '2026-10-20 21:30'),
    (105, 3, NULL,             12.00, N'12,00',  N'pago',      N'21/10/2026', '2026-10-21 00:10', '2026-10-21 00:10'),
    (106, 1, N'Cliente E',     99.90, N'99,90',  N'pago',      N'21/10/2026', '2026-10-21 10:00', '2026-10-21 10:00'),
    (107, 2, N'cliente f ',    15.00, N'15,00',  N'pendente',  N'21/10/2026', '2026-10-21 11:30', '2026-10-21 11:30'),
    (108, 1, N'Cliente G',    200.00, N'200,00', N'pago',      N'22/10/2026', '2026-10-22 07:45', '2026-10-22 07:45'),
    (109, 3, N'Cliente H',     60.00, N'60,00',  N' Pago ',    N'22/10/2026', '2026-10-22 13:20', '2026-10-22 13:20'),
    (110, 2, N'',              33.30, N'33,30',  N'pago',      N'22/10/2026', '2026-10-22 23:30', '2026-10-22 23:30');

CREATE TABLE dbo.itens_pedido (
    pedido_id      int NOT NULL REFERENCES dbo.pedidos (id),
    item_seq       int NOT NULL,
    produto_id     int NOT NULL REFERENCES dbo.produtos (id),
    quantidade     int NOT NULL,
    preco_unitario numeric(12, 2) NOT NULL,
    PRIMARY KEY (pedido_id, item_seq)
);

INSERT INTO dbo.itens_pedido VALUES
    (101, 1, 10, 2, 60.00),
    (102, 1, 10, 1, 60.00),
    (102, 2, 40, 1, 20.50),
    (103, 1, 30, 3, 15.00),
    (104, 1, 10, 5, 60.00),
    (104, 2, 30, 1, 10.90),
    (105, 1, 50, 1, 12.00),
    (106, 1, 20, 3, 33.30),
    (107, 1, 30, 1, 15.00),
    (108, 1, 10, 2, 60.00),
    (108, 2, 40, 4, 20.00),
    (109, 1, 10, 1, 60.00),
    (110, 1, 20, 1, 33.30);

-- A second "many" side of an order: one order can have many items and many payments.
CREATE TABLE dbo.pagamentos (
    pedido_id int NOT NULL REFERENCES dbo.pedidos (id),
    parcela   int NOT NULL,
    valor     numeric(12, 2) NOT NULL,
    PRIMARY KEY (pedido_id, parcela)
);

INSERT INTO dbo.pagamentos VALUES
    (101, 1, 120.00),
    (104, 1, 110.90),
    (104, 2, 200.00),
    (105, 1,  12.00),
    (106, 1,  99.90),
    (108, 1, 100.00),
    (108, 2, 100.00),
    (109, 1,  60.00),
    (110, 1,  33.30);

-- One product can have two suppliers: joining this table to sales multiplies rows.
CREATE TABLE dbo.produto_fornecedor (
    produto_id int NOT NULL REFERENCES dbo.produtos (id),
    fornecedor nvarchar(50) NOT NULL,
    PRIMARY KEY (produto_id, fornecedor)
);

INSERT INTO dbo.produto_fornecedor VALUES
    (10, N'Fornecedor A'),
    (10, N'Fornecedor B'),
    (20, N'Fornecedor C'),
    (30, N'Fornecedor A'),
    (40, N'Fornecedor D'),
    (50, N'Fornecedor D');

-- The new customer service system stores UTC in a column without zone.
CREATE TABLE dbo.atendimentos (
    id              int PRIMARY KEY,
    loja_id         int NOT NULL REFERENCES dbo.lojas (id),
    criado_em_utc   datetime2(0) NOT NULL,
    atendido_em_utc datetime2(0)
);

INSERT INTO dbo.atendimentos VALUES
    (1, 1, '2026-10-20 13:15', '2026-10-20 13:20'),
    (2, 1, '2026-10-21 00:25', '2026-10-21 00:30'),
    (3, 2, '2026-10-21 00:50', NULL),
    (4, 3, '2026-10-21 12:00', '2026-10-21 12:05');
GO
USE dw;
GO
CREATE SCHEMA replica;
GO
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
CREATE SCHEMA controle;
GO
CREATE SYNONYM replica.lojas FOR erp.dbo.lojas;
CREATE SYNONYM replica.produtos FOR erp.dbo.produtos;
CREATE SYNONYM replica.pedidos FOR erp.dbo.pedidos;
CREATE SYNONYM replica.itens_pedido FOR erp.dbo.itens_pedido;
CREATE SYNONYM replica.pagamentos FOR erp.dbo.pagamentos;
CREATE SYNONYM replica.produto_fornecedor FOR erp.dbo.produto_fornecedor;
CREATE SYNONYM replica.atendimentos FOR erp.dbo.atendimentos;

-- Raw copies, no key on purpose: bronze keeps what came, plus load metadata.
CREATE TABLE bronze.lojas (
    id int, nome nvarchar(100), cidade nvarchar(100), fecha_as time(0),
    _carregado_em datetimeoffset(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
CREATE TABLE bronze.pedidos (
    id int, loja_id int, cliente nvarchar(100), valor numeric(12, 2), valor_texto nvarchar(20),
    status nvarchar(20), emissao_texto nvarchar(20), criado_em datetime2(0), atualizado_em datetime2(0),
    _carregado_em datetimeoffset(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
CREATE TABLE bronze.itens_pedido (
    pedido_id int, item_seq int, produto_id int, quantidade int, preco_unitario numeric(12, 2),
    _carregado_em datetimeoffset(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
CREATE TABLE bronze.pagamentos (
    pedido_id int, parcela int, valor numeric(12, 2),
    _carregado_em datetimeoffset(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
CREATE TABLE bronze.produto_fornecedor (
    produto_id int, fornecedor nvarchar(50),
    _carregado_em datetimeoffset(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
CREATE TABLE bronze.atendimentos (
    id int, loja_id int, criado_em_utc datetime2(0), atendido_em_utc datetime2(0),
    _carregado_em datetimeoffset(3) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
CREATE TABLE bronze.produtos_foto (
    id int, nome nvarchar(100), categoria nvarchar(100), preco numeric(12, 2), custo numeric(12, 2),
    atualizado_em datetime2(0),
    _dia_referencia date NOT NULL
);

CREATE TABLE controle.carga (
    id            bigint IDENTITY PRIMARY KEY,
    executor      nvarchar(50) NOT NULL,
    linhas_bronze int NOT NULL,
    linhas_silver int NOT NULL,
    receita_paga  numeric(14, 2),
    registrado_em datetimeoffset(0) NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO
