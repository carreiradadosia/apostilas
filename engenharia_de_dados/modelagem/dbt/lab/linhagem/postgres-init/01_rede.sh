#!/bin/sh
# Roles and the store chain database. The logging settings go through ALTER SYSTEM so the lab can
# change them later with a reload, as a DBA would.
set -e

echo "host replication replicador all scram-sha-256" >> "$PGDATA/pg_hba.conf"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
  -v app_pw="$APP_DB_PASSWORD" -v mon_pw="$MONITOR_DB_PASSWORD" \
  -v dbt_pw="$DBT_DB_PASSWORD" -v rep_pw="$REPLICATOR_DB_PASSWORD" <<'EOSQL'
CREATE ROLE erp_dono NOLOGIN;
CREATE ROLE app_relatorio LOGIN PASSWORD :'app_pw';
CREATE ROLE monitor_lab LOGIN PASSWORD :'mon_pw';
CREATE ROLE transformador LOGIN PASSWORD :'dbt_pw';
CREATE ROLE replicador REPLICATION LOGIN PASSWORD :'rep_pw';
CREATE DATABASE rede OWNER erp_dono;
ALTER SYSTEM SET log_min_duration_statement = 250;
ALTER SYSTEM SET log_line_prefix = '%m [%p] app=%a user=%u db=%d ';
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname rede -f /cenario/00_cenario.sql
