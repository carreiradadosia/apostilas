#!/usr/bin/env bash
# Creates the local .env with the host user id and random lab secrets.
# ACCEPT_EULA stays out on purpose: whoever runs the lab reads the terms and exports it.
set -euo pipefail
cd "$(dirname "$0")"

if [[ -f .env ]]; then
  echo ".env já existe, nada a fazer."
  exit 0
fi

rand() { head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n'; }

{
  echo "DBT_UID=$(id -u)"
  echo "DBT_GID=$(id -g)"
  for nome in ADMIN_DB_PASSWORD APP_DB_PASSWORD MONITOR_DB_PASSWORD DBT_DB_PASSWORD REPLICATOR_DB_PASSWORD; do
    echo "${nome}=$(rand)"
  done
  # SQL Server password policy asks for three of four character sets.
  for nome in MSSQL_SA_PASSWORD MSSQL_APP_PASSWORD MSSQL_MONITOR_PASSWORD; do
    echo "${nome}=Lab-A9$(rand)"
  done
} > .env
chmod 600 .env
echo ".env criado com segredos aleatórios."
