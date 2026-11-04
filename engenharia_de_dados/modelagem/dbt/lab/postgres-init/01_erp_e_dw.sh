#!/bin/sh
# Two databases on one server: "erp" plays the read-only replica of a fictional store chain ERP,
# "dw" holds the bronze, silver and gold layers and reads the replica through postgres_fdw.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v erp_pw="$ERP_DB_PASSWORD" -v replica_pw="$REPLICA_DB_PASSWORD" -v dw_pw="$DW_DB_PASSWORD" <<'EOSQL'
CREATE ROLE erp LOGIN PASSWORD :'erp_pw';
CREATE ROLE replica_leitura LOGIN PASSWORD :'replica_pw';
ALTER ROLE replica_leitura SET default_transaction_read_only = on;
CREATE ROLE dw LOGIN PASSWORD :'dw_pw';
CREATE DATABASE erp OWNER erp;
CREATE DATABASE dw OWNER dw;
EOSQL

psql -v ON_ERROR_STOP=1 --username erp --dbname erp <<'EOSQL'
-- As the source systems store it: padded text, mixed case, nulls, a redundant text column.
CREATE TABLE lojas (
    id       integer PRIMARY KEY,
    nome     text NOT NULL,
    cidade   text NOT NULL,
    fecha_as time NOT NULL
);

INSERT INTO lojas VALUES
    (1, '  Loja Centro ', 'São Paulo',   '22:00'),
    (2, 'LOJA NORTE',     'SAO PAULO ',  '22:00'),
    (3, 'loja são joão',  'Santo André', '20:00');

-- The ERP overwrites this table every night: no price history, and a nightly job touches
-- atualizado_em on every row even when nothing changed.
CREATE TABLE produtos (
    id            integer PRIMARY KEY,
    nome          text NOT NULL,
    categoria     text NOT NULL,
    preco         numeric(12, 2) NOT NULL,
    custo         numeric(12, 2),
    atualizado_em timestamp without time zone NOT NULL
);

INSERT INTO produtos VALUES
    (10, 'Camiseta básica',    'Vestuário',  60.00, 30.00, '2026-10-20 03:00'),
    (20, ' CAFÉ TORRADO 500G', 'mercearia',  33.30, 20.00, '2026-10-20 03:00'),
    (30, 'caneca de cerâmica', 'UTILIDADES', 15.00,  7.00, '2026-10-20 03:00'),
    (40, 'Caderno',            'Papelaria',  20.50, 10.00, '2026-10-20 03:00'),
    (50, 'Lápis',              'Papelria ',  12.00,  NULL, '2026-10-20 03:00');

-- Same ten orders of the orchestration lab, now with a store and a text date.
CREATE TABLE pedidos (
    id            integer PRIMARY KEY,
    loja_id       integer NOT NULL REFERENCES lojas (id),
    cliente       text,
    valor         numeric(12, 2) NOT NULL,
    valor_texto   text,
    status        text,
    emissao_texto text NOT NULL,
    criado_em     timestamp without time zone NOT NULL,
    atualizado_em timestamp without time zone NOT NULL
);

INSERT INTO pedidos VALUES
    (101, 1, '  Cliente A ', 120.00, '120,00', 'PAGO',      '20/10/2026', '2026-10-20 08:15', '2026-10-20 08:15'),
    (102, 1, 'Cliente B',     80.50, '80,50',  NULL,        '20/10/2026', '2026-10-20 09:40', '2026-10-20 09:40'),
    (103, 2, 'cliente c',     45.00, '45,00',  'cancelado', '20/10/2026', '2026-10-20 18:05', '2026-10-20 19:00'),
    (104, 2, 'Cliente D',    310.90, '310,90', 'pago',      '20/10/2026', '2026-10-20 21:30', '2026-10-20 21:30'),
    (105, 3, NULL,            12.00, '12,00',  'pago',      '21/10/2026', '2026-10-21 00:10', '2026-10-21 00:10'),
    (106, 1, 'Cliente E',     99.90, '99,90',  'pago',      '21/10/2026', '2026-10-21 10:00', '2026-10-21 10:00'),
    (107, 2, 'cliente f ',    15.00, '15,00',  'pendente',  '21/10/2026', '2026-10-21 11:30', '2026-10-21 11:30'),
    (108, 1, 'Cliente G',    200.00, '200,00', 'pago',      '22/10/2026', '2026-10-22 07:45', '2026-10-22 07:45'),
    (109, 3, 'Cliente H',     60.00, '60,00',  ' Pago ',    '22/10/2026', '2026-10-22 13:20', '2026-10-22 13:20'),
    (110, 2, '',              33.30, '33,30',  'pago',      '22/10/2026', '2026-10-22 23:30', '2026-10-22 23:30');

CREATE TABLE itens_pedido (
    pedido_id      integer NOT NULL REFERENCES pedidos (id),
    item_seq       integer NOT NULL,
    produto_id     integer NOT NULL REFERENCES produtos (id),
    quantidade     integer NOT NULL,
    preco_unitario numeric(12, 2) NOT NULL,
    PRIMARY KEY (pedido_id, item_seq)
);

INSERT INTO itens_pedido VALUES
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
CREATE TABLE pagamentos (
    pedido_id integer NOT NULL REFERENCES pedidos (id),
    parcela   integer NOT NULL,
    valor     numeric(12, 2) NOT NULL,
    PRIMARY KEY (pedido_id, parcela)
);

INSERT INTO pagamentos VALUES
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
CREATE TABLE produto_fornecedor (
    produto_id integer NOT NULL REFERENCES produtos (id),
    fornecedor text NOT NULL,
    PRIMARY KEY (produto_id, fornecedor)
);

INSERT INTO produto_fornecedor VALUES
    (10, 'Fornecedor A'),
    (10, 'Fornecedor B'),
    (20, 'Fornecedor C'),
    (30, 'Fornecedor A'),
    (40, 'Fornecedor D'),
    (50, 'Fornecedor D');

-- The new customer service system stores UTC in a column without zone.
CREATE TABLE atendimentos (
    id              integer PRIMARY KEY,
    loja_id         integer NOT NULL REFERENCES lojas (id),
    criado_em_utc   timestamp without time zone NOT NULL,
    atendido_em_utc timestamp without time zone
);

INSERT INTO atendimentos VALUES
    (1, 1, '2026-10-20 13:15', '2026-10-20 13:20'),
    (2, 1, '2026-10-21 00:25', '2026-10-21 00:30'),
    (3, 2, '2026-10-21 00:50', NULL),
    (4, 3, '2026-10-21 12:00', '2026-10-21 12:05');

GRANT CONNECT ON DATABASE erp TO replica_leitura;
GRANT USAGE ON SCHEMA public TO replica_leitura;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replica_leitura;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname dw -v replica_pw="$REPLICA_DB_PASSWORD" <<'EOSQL'
CREATE EXTENSION postgres_fdw;
CREATE EXTENSION unaccent;
CREATE SERVER replica_erp FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'postgres', port '5432', dbname 'erp');
GRANT USAGE ON FOREIGN SERVER replica_erp TO dw;
CREATE USER MAPPING FOR dw SERVER replica_erp
    OPTIONS (user 'replica_leitura', password :'replica_pw');
EOSQL

psql -v ON_ERROR_STOP=1 --username dw --dbname dw <<'EOSQL'
CREATE SCHEMA replica;
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
CREATE SCHEMA controle;

-- Declared by hand because the server only listens on a socket while this script runs.
CREATE FOREIGN TABLE replica.lojas (
    id integer, nome text, cidade text, fecha_as time
) SERVER replica_erp OPTIONS (schema_name 'public', table_name 'lojas');

CREATE FOREIGN TABLE replica.produtos (
    id integer, nome text, categoria text, preco numeric(12, 2), custo numeric(12, 2),
    atualizado_em timestamp without time zone
) SERVER replica_erp OPTIONS (schema_name 'public', table_name 'produtos');

CREATE FOREIGN TABLE replica.pedidos (
    id integer, loja_id integer, cliente text, valor numeric(12, 2), valor_texto text, status text,
    emissao_texto text, criado_em timestamp without time zone, atualizado_em timestamp without time zone
) SERVER replica_erp OPTIONS (schema_name 'public', table_name 'pedidos');

CREATE FOREIGN TABLE replica.itens_pedido (
    pedido_id integer, item_seq integer, produto_id integer, quantidade integer, preco_unitario numeric(12, 2)
) SERVER replica_erp OPTIONS (schema_name 'public', table_name 'itens_pedido');

CREATE FOREIGN TABLE replica.pagamentos (
    pedido_id integer, parcela integer, valor numeric(12, 2)
) SERVER replica_erp OPTIONS (schema_name 'public', table_name 'pagamentos');

CREATE FOREIGN TABLE replica.produto_fornecedor (
    produto_id integer, fornecedor text
) SERVER replica_erp OPTIONS (schema_name 'public', table_name 'produto_fornecedor');

CREATE FOREIGN TABLE replica.atendimentos (
    id integer, loja_id integer, criado_em_utc timestamp without time zone,
    atendido_em_utc timestamp without time zone
) SERVER replica_erp OPTIONS (schema_name 'public', table_name 'atendimentos');

-- Raw copies, no key on purpose: bronze keeps what came, plus load metadata.
CREATE TABLE bronze.lojas (LIKE replica.lojas);
CREATE TABLE bronze.pedidos (LIKE replica.pedidos);
CREATE TABLE bronze.itens_pedido (LIKE replica.itens_pedido);
CREATE TABLE bronze.pagamentos (LIKE replica.pagamentos);
CREATE TABLE bronze.produto_fornecedor (LIKE replica.produto_fornecedor);
CREATE TABLE bronze.atendimentos (LIKE replica.atendimentos);
CREATE TABLE bronze.produtos_foto (LIKE replica.produtos);
ALTER TABLE bronze.lojas ADD COLUMN _carregado_em timestamptz NOT NULL DEFAULT now();
ALTER TABLE bronze.pedidos ADD COLUMN _carregado_em timestamptz NOT NULL DEFAULT now();
ALTER TABLE bronze.itens_pedido ADD COLUMN _carregado_em timestamptz NOT NULL DEFAULT now();
ALTER TABLE bronze.pagamentos ADD COLUMN _carregado_em timestamptz NOT NULL DEFAULT now();
ALTER TABLE bronze.produto_fornecedor ADD COLUMN _carregado_em timestamptz NOT NULL DEFAULT now();
ALTER TABLE bronze.atendimentos ADD COLUMN _carregado_em timestamptz NOT NULL DEFAULT now();
ALTER TABLE bronze.produtos_foto ADD COLUMN _dia_referencia date NOT NULL;

CREATE TABLE controle.carga (
    id            bigserial PRIMARY KEY,
    executor      text NOT NULL,
    linhas_bronze integer NOT NULL,
    linhas_silver integer NOT NULL,
    receita_paga  numeric(14, 2),
    registrado_em timestamptz NOT NULL DEFAULT now()
);
EOSQL
