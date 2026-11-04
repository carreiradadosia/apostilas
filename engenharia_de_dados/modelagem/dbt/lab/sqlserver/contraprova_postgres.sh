#!/usr/bin/env bash
# Usage: ./contraprova_postgres.sh
# Starts a throwaway Postgres, runs the text checks and removes the container.
# No published port and trust auth inside the container, so there is no password to keep.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
saida=saidas/postgres_contraprova.txt
: > "$saida"
docker run -d --rm --name tsql-pg -e POSTGRES_HOST_AUTH_METHOD=trust postgres:16.15-alpine > /dev/null || exit 1
# TCP check on purpose: the temporary init server listens only on the socket.
if timeout 60 bash -c 'until docker exec tsql-pg pg_isready -h 127.0.0.1 -U postgres -q; do sleep 1; done'; then
  ./capturar.sh "$saida" "docker exec -i tsql-pg psql -U postgres -X -v ON_ERROR_STOP=1 < sql/postgres_contraprova.sql"
else
  echo "Postgres did not become ready" >&2
fi
docker stop tsql-pg > /dev/null
