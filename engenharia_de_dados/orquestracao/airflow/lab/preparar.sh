#!/usr/bin/env bash
# Creates the local .env with the host user id and random lab secrets.
set -euo pipefail
cd "$(dirname "$0")"

if [[ -f .env ]]; then
  echo ".env já existe, nada a fazer."
  exit 0
fi

rand() { head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n'; }

mkdir -p dags logs
{
  echo "AIRFLOW_UID=$(id -u)"
  for nome in AIRFLOW_DB_PASSWORD LOJA_DB_PASSWORD ERP_DB_PASSWORD REPLICA_DB_PASSWORD DW_DB_PASSWORD JWT_SECRET; do
    echo "${nome}=$(rand)"
  done
} > .env
chmod 600 .env
echo ".env criado com AIRFLOW_UID=$(id -u) e segredos aleatórios."
