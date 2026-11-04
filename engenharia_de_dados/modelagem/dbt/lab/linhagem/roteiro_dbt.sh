#!/usr/bin/env bash
# dbt phase: what the definition of the number looks like and what the graph does and does not see.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

fase() { S="saidas/$1.txt"; : > "$S"; }
c() { ./capturar.sh "$S" "$(cat)"; }

fase dbt_01_linhagem
c <<'CMD'
docker compose --profile dbt run --rm -T --no-deps dbt dbt --version 2>&1 | grep -E 'installed|postgres:|Update' || true
CMD
c <<'CMD'
docker compose --profile dbt run --rm -T --no-deps dbt dbt parse --no-partial-parse 2>&1 | tail -4
CMD
c <<'CMD'
docker compose --profile dbt run --rm -T --no-deps dbt dbt run 2>&1 | grep -E 'Completed|Done\.|ERROR|OK created' || true
CMD
c <<'CMD'
docker compose --profile dbt run --rm -T --no-deps dbt dbt docs generate 2>&1 | tail -2
ls dbt/target | grep -E '^(index\.html|manifest\.json|catalog\.json)$'
CMD
c <<'CMD'
docker compose --profile dbt run --rm -T --no-deps dbt python ler_manifesto.py
CMD
c <<'CMD'
# The exposure selects what feeds it, up to the sources.
docker compose --profile dbt run --rm -T --no-deps dbt dbt ls --select +exposure:relatorio_faturamento_diretoria --output name 2>&1 | grep -vE 'Running with|Registered adapter|Found ' || true
CMD
c <<'CMD'
# The number itself, against the report of the system.
bin/pg postgres admin_lab lab -c "SELECT loja, sum(faturamento) AS faturamento FROM dw.mart_faturamento_por_loja GROUP BY loja ORDER BY loja;"
bin/pg postgres admin_lab lab -c "SELECT loja, faturamento FROM relatorios.faturamento_por_loja('2026-10-20', '2026-10-22');"
CMD
c <<'CMD'
# The docs site is served by the same local tool, with no account.
docker compose --profile dbt run --rm -T --no-deps dbt sh -c '
  dbt docs serve --no-browser --port 8080 >/tmp/serve.log 2>&1 &
  python - <<PY
import time, urllib.request
for caminho in ("/", "/manifest.json", "/catalog.json"):
    for tentativa in range(40):
        try:
            with urllib.request.urlopen("http://localhost:8080" + caminho, timeout=2) as r:
                print(caminho, r.status, r.headers.get("Content-Type"))
            break
        except OSError:
            time.sleep(0.5)
PY
'
CMD
