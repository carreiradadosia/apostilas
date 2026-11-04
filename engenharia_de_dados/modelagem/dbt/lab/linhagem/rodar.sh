#!/usr/bin/env bash
# Runs the whole lab from zero and removes its containers and volumes at the end.
#   ./preparar.sh
#   ACCEPT_EULA=Y ./rodar.sh        (after reading the SQL Server Developer terms)
# Keeps the images. Needs 3 GB of free memory for SQL Server.
set -euo pipefail
cd "$(dirname "$0")"
: "${ACCEPT_EULA:?Leia os termos da edicao Developer em https://www.microsoft.com/content/dam/microsoft/usetm/documents/sql-server/sql-server-2022-developer-express-evaluation/retail-packaged/SQLServer2022_SQLServer2022DeveloperExpressEvaluation_English.pdf e so entao exporte ACCEPT_EULA=Y}"
export ACCEPT_EULA

./preparar.sh
chmod +x bin/* capturar.sh roteiro_*.sh postgres-init/*.sh

docker compose --profile app --profile dbt build --quiet
timeout 300 docker compose up -d --wait postgres mssql

./roteiro_postgres.sh
./roteiro_mssql.sh
./roteiro_dbt.sh

docker compose --profile replica --profile app --profile dbt down -v
