#!/usr/bin/env bash
# Creates the local .env with a random sa password.
# ACCEPT_EULA stays out of the file on purpose: whoever runs the lab accepts the terms on the command line.
set -euo pipefail
cd "$(dirname "$0")"

if [[ -f .env ]]; then
  echo ".env já existe, nada a fazer."
  exit 0
fi

umask 077
printf 'MSSQL_SA_PASSWORD=Aa1-%s\n' "$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')" > .env  # higiene:ignore, random value
chmod 600 .env
echo ".env criado com senha aleatória."
