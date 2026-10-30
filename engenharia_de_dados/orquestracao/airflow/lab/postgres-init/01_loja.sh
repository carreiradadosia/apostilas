#!/bin/sh
# Creates the "loja" database read by the registro_de_carga Dag: a small source table that gets new orders.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
CREATE USER loja WITH PASSWORD '${LOJA_DB_PASSWORD}';
CREATE DATABASE loja OWNER loja;
EOSQL

psql -v ON_ERROR_STOP=1 --username loja --dbname loja <<'EOSQL'
-- Raw data as the source system stores it: local time without zone, padded text, nulls.
CREATE TABLE pedidos_origem (
    id          integer PRIMARY KEY,
    cliente     text,
    valor       numeric(12, 2),
    status      text,
    criado_em   timestamp without time zone
);

INSERT INTO pedidos_origem (id, cliente, valor, status, criado_em) VALUES
    (1, '  Cliente A ', 120.00, 'pago',     '2026-10-28 08:15:00'),
    (2, 'Cliente B',     80.50, NULL,       '2026-10-28 09:40:00'),
    (3, 'cliente c',     45.00, 'cancelado','2026-10-28 18:05:00'),
    (4, 'Cliente D',    310.90, 'pago',     '2026-10-28 23:30:00'),
    (5, NULL,            12.00, 'pago',     '2026-10-29 00:10:00');
EOSQL
