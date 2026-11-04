#!/usr/bin/env bash
# Usage: ACCEPT_EULA=Y ./edicoes_2025.sh
# Which edition each MSSQL_PID value starts on the 2025 image. Each attempt starts from an empty volume.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
./preparar.sh
export MSSQL_TAG=2025-CU10-ubuntu-24.04
saida=saidas/2025/lab0_edicoes.txt
: > "$saida"
consulta="SET NOCOUNT ON; SELECT SERVERPROPERTY('Edition') AS edicao, SERVERPROPERTY('EngineEdition') AS motor;"
for pid in Developer EnterpriseDeveloper StandardDeveloper; do
  export MSSQL_PID="$pid"
  ./capturar.sh "$saida" "echo MSSQL_PID=$pid"
  docker compose up -d --quiet-pull
  # shellcheck disable=SC2016  # expanded by the inner bash
  if timeout 180 bash -c 'until [ "$(docker inspect -f "{{.State.Health.Status}}" mssql-tsql-mssql-1)" = healthy ]; do sleep 2; done'; then
    ./capturar.sh "$saida" "docker exec mssql-tsql-mssql-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -W -h -1 -Q \"$consulta\""
  else
    ./capturar.sh "$saida" "docker logs --tail 8 mssql-tsql-mssql-1"
  fi
  docker compose down -v
done
