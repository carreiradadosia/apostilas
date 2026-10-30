#!/bin/sh
# Two databases on one server: "erp" plays the read-only replica of a fictional ERP,
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
-- As the ERP stores it: local time without zone, padded text, nulls, a redundant text column.
CREATE TABLE pedidos (
    id            integer PRIMARY KEY,
    cliente       text,
    valor         numeric(12, 2) NOT NULL,
    valor_texto   text,
    status        text,
    criado_em     timestamp without time zone NOT NULL,
    atualizado_em timestamp without time zone NOT NULL
);

INSERT INTO pedidos VALUES
    (101, '  Cliente A ', 120.00, '120,00', 'PAGO',      '2026-10-20 08:15', '2026-10-20 08:15'),
    (102, 'Cliente B',     80.50, '80,50',  NULL,        '2026-10-20 09:40', '2026-10-20 09:40'),
    (103, 'cliente c',     45.00, '45,00',  'cancelado', '2026-10-20 18:05', '2026-10-20 19:00'),
    (104, 'Cliente D',    310.90, '310,90', 'pago',      '2026-10-20 21:30', '2026-10-20 21:30'),
    (105, NULL,            12.00, '12,00',  'pago',      '2026-10-21 00:10', '2026-10-21 00:10'),
    (106, 'Cliente E',     99.90, '99,90',  'pago',      '2026-10-21 10:00', '2026-10-21 10:00'),
    (107, 'cliente f ',    15.00, '15,00',  'pendente',  '2026-10-21 11:30', '2026-10-21 11:30'),
    (108, 'Cliente G',    200.00, '200,00', 'pago',      '2026-10-22 07:45', '2026-10-22 07:45'),
    (109, 'Cliente H',     60.00, '60,00',  ' Pago ',    '2026-10-22 13:20', '2026-10-22 13:20'),
    (110, '',              33.30, '33,30',  'pago',      '2026-10-22 23:30', '2026-10-22 23:30');

GRANT CONNECT ON DATABASE erp TO replica_leitura;
GRANT USAGE ON SCHEMA public TO replica_leitura;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replica_leitura;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname dw -v replica_pw="$REPLICA_DB_PASSWORD" <<'EOSQL'
CREATE EXTENSION postgres_fdw;
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
CREATE FOREIGN TABLE replica.pedidos (
    id            integer,
    cliente       text,
    valor         numeric(12, 2),
    valor_texto   text,
    status        text,
    criado_em     timestamp without time zone,
    atualizado_em timestamp without time zone
) SERVER replica_erp OPTIONS (schema_name 'public', table_name 'pedidos');

-- Raw copy, no key on purpose: bronze keeps what came, plus load metadata.
CREATE TABLE bronze.pedidos (
    id              integer,
    cliente         text,
    valor           numeric(12, 2),
    valor_texto     text,
    status          text,
    criado_em       timestamp without time zone,
    atualizado_em   timestamp without time zone,
    _dia_referencia date NOT NULL,
    _carregado_em   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE silver.pedidos (
    id            integer NOT NULL,
    cliente       text NOT NULL,
    valor         numeric(12, 2) NOT NULL,
    status        text NOT NULL,
    criado_em_utc timestamptz NOT NULL,
    dia_local     date NOT NULL
);

CREATE TABLE gold.vendas_por_dia (
    dia           date PRIMARY KEY,
    pedidos       integer NOT NULL,
    pedidos_pagos integer NOT NULL,
    receita_paga  numeric(14, 2) NOT NULL
);

CREATE TABLE controle.carga (
    id             bigserial PRIMARY KEY,
    executor       text NOT NULL,
    dia_referencia date NOT NULL,
    linhas_bronze  integer NOT NULL,
    linhas_silver  integer NOT NULL,
    receita_paga   numeric(14, 2),
    registrado_em  timestamptz NOT NULL DEFAULT now()
);
EOSQL
