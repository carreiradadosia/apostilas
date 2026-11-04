#!/usr/bin/env bash
# SQL Server phases. Failures are part of the evidence, so the script goes on when a command fails.
# Nothing here selects a duration, CPU or reads column: the Developer terms restrict disclosing
# benchmark results, so what SQL Server costs comes from the documentation.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

fase() { S="saidas/$1.txt"; : > "$S"; }
c() { ./capturar.sh "$S" "$(cat)"; }

# ---------------------------------------------------------------------------------------------
fase mssql_00_ambiente
c <<'CMD'
docker compose exec -T mssql bash -c '/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -b -v APP_PW="$MSSQL_APP_PASSWORD" -v MON_PW="$MSSQL_MONITOR_PASSWORD" -I -i /scripts/00_cenario.sql > /dev/null && echo cenario criado'
CMD
c <<'CMD'
bin/ms sa -i /scripts/01_ambiente.sql
CMD
c <<'CMD'
bin/ms sa -i /scripts/13_xe_descricoes.sql
CMD

# ---------------------------------------------------------------------------------------------
fase mssql_01_extended_events
c <<'CMD'
bin/ms sa -i /scripts/10_xe_criar.sql
CMD
c <<'CMD'
# The filtered application, then another application and another login that must stay out.
docker compose --profile app run --rm -T --no-deps app padrao
docker compose --profile app run --rm -T --no-deps app faturamento_cifrado >/dev/null
docker compose --profile app run --rm -T --no-deps app faturamento_dinamico >/dev/null
docker compose --profile app run --rm -T --no-deps app --app bi_outro padrao >/dev/null
bin/ms sa -d rede -Q "SELECT COUNT(*) AS ruido_do_administrador FROM relatorios.vw_faturamento_itens;"
CMD
c <<'CMD'
bin/ms sa -i /scripts/11_xe_ler_arquivo.sql
CMD
c <<'CMD'
bin/ms sa -i /scripts/12_xe_ler_ring.sql
CMD

# ---------------------------------------------------------------------------------------------
fase mssql_02_cache_de_plano
c <<'CMD'
docker compose --profile app run --rm -T --no-deps app faturamento_recompila >/dev/null
bin/ms sa -i /scripts/20_dmv_stats.sql
CMD
c <<'CMD'
# The plan cache can be emptied by a person or by memory pressure: the rows go with it.
bin/ms sa -Q "DBCC FREEPROCCACHE WITH NO_INFOMSGS;"
bin/ms sa -i /scripts/20_dmv_stats.sql
CMD

# ---------------------------------------------------------------------------------------------
fase mssql_03_requests
c <<'CMD'
docker compose --profile app run --rm -T --no-deps app faturamento_lento >/dev/null &
timeout 20 bash -c 'until bin/ms sa -h -1 -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.dm_exec_sessions WHERE program_name = N'"'"'erp_relatorios'"'"' AND status = N'"'"'running'"'"';" | grep -q "^1"; do sleep 0.3; done'
bin/ms sa -i /scripts/21_dmv_requests.sql
bin/ms leitor_monitor -i /scripts/21_dmv_requests.sql
wait
CMD
c <<'CMD'
# After it ends there is nothing left in this view.
bin/ms sa -i /scripts/21_dmv_requests.sql
CMD

# ---------------------------------------------------------------------------------------------
fase mssql_04_query_store
c <<'CMD'
# Default capture mode on this database. The whole report ran above; what did it keep?
bin/ms sa -i /scripts/30_qs_ler.sql
CMD
c <<'CMD'
# Capture everything for the investigation, run the report once, read again.
bin/ms sa -Q "ALTER DATABASE rede SET QUERY_STORE (QUERY_CAPTURE_MODE = ALL);"
docker compose --profile app run --rm -T --no-deps app padrao >/dev/null
docker compose --profile app run --rm -T --no-deps app faturamento_cifrado >/dev/null
docker compose --profile app run --rm -T --no-deps app faturamento_dinamico >/dev/null
docker compose --profile app run --rm -T --no-deps app faturamento_recompila >/dev/null
bin/ms sa -i /scripts/30_qs_ler.sql
CMD
c <<'CMD'
bin/ms sa -i /scripts/31_qs_planos.sql
CMD

# ---------------------------------------------------------------------------------------------
fase mssql_05_catalogo
c <<'CMD'
bin/ms sa -i /scripts/40_catalogo.sql
CMD

# ---------------------------------------------------------------------------------------------
fase mssql_06_permissoes
c <<'CMD'
# No permission beyond connecting to the database.
bin/ms leitor_monitor -d rede -i /scripts/50_perm_matriz.sql
CMD
c <<'CMD'
bin/ms leitor_monitor -h -1 -Q "SET NOCOUNT ON; SELECT COUNT(*) AS eventos_lidos FROM sys.fn_xe_file_target_read_file(N'/var/opt/mssql/log/relatorio_lab*.xel', NULL, NULL, NULL);"
CMD
c <<'CMD'
bin/ms sa -d rede -Q "GRANT VIEW DATABASE PERFORMANCE STATE TO leitor_monitor;"
bin/ms leitor_monitor -d rede -i /scripts/50_perm_matriz.sql
CMD
c <<'CMD'
bin/ms sa -Q "GRANT VIEW SERVER PERFORMANCE STATE TO leitor_monitor;"
bin/ms leitor_monitor -d rede -i /scripts/50_perm_matriz.sql
CMD
c <<'CMD'
bin/ms sa -d rede -Q "GRANT VIEW DEFINITION ON SCHEMA::relatorios TO leitor_monitor;"
bin/ms leitor_monitor -d rede -i /scripts/50_perm_matriz.sql
CMD
c <<'CMD'
bin/ms sa -d rede -Q "GRANT VIEW DEFINITION TO leitor_monitor; GRANT SELECT ON sys.sql_expression_dependencies TO leitor_monitor;"
bin/ms leitor_monitor -d rede -i /scripts/50_perm_matriz.sql
CMD
c <<'CMD'
# Extended Events with no event permission, then with the granular ones of SQL Server 2022.
bin/ms leitor_monitor -i /scripts/51_perm_xe.sql
bin/ms sa -Q "GRANT CREATE ANY EVENT SESSION, ALTER ANY EVENT SESSION ENABLE, ALTER ANY EVENT SESSION DISABLE, DROP ANY EVENT SESSION TO leitor_monitor;"
bin/ms leitor_monitor -i /scripts/51_perm_xe.sql
CMD
c <<'CMD'
bin/ms leitor_monitor -h -1 -Q "SET NOCOUNT ON; SELECT COUNT(*) AS eventos_lidos FROM sys.fn_xe_file_target_read_file(N'/var/opt/mssql/log/relatorio_lab*.xel', NULL, NULL, NULL);"
CMD

# ---------------------------------------------------------------------------------------------
fase mssql_07_reinicio
c <<'CMD'
# Stop the session: the file stays, the ring buffer goes.
bin/ms sa -i /scripts/12_xe_ler_ring.sql
bin/ms sa -Q "ALTER EVENT SESSION relatorio_lab ON SERVER STATE = STOP;"
bin/ms sa -i /scripts/12_xe_ler_ring.sql
bin/ms sa -h -1 -Q "SET NOCOUNT ON; SELECT COUNT(*) AS eventos_no_arquivo FROM sys.fn_xe_file_target_read_file(N'/var/opt/mssql/log/relatorio_lab*.xel', NULL, NULL, NULL);"
CMD
c <<'CMD'
# Clean stop through T-SQL: the cache is gone, Query Store keeps text, plan and counters, the session does not come back.
docker compose --profile app run --rm -T --no-deps app padrao >/dev/null
bin/ms sa -Q "ALTER EVENT SESSION relatorio_lab ON SERVER STATE = START;"
bin/ms sa -i /scripts/32_qs_contagem.sql
bin/ms-parar
bin/ms-online
echo "--- cache de plano"; bin/ms sa -i /scripts/20_dmv_stats.sql
echo "--- query store"; bin/ms sa -i /scripts/32_qs_contagem.sql
echo "--- sessao"; bin/ms sa -i /scripts/12_xe_ler_ring.sql
CMD
c <<'CMD'
# Hard stop before the flush interval: the text survives, the counters of the interval do not.
bin/ms sa -d rede -Q "SELECT 'marcador_antes_da_queda' AS marcador, COUNT(*) AS itens FROM relatorios.vw_faturamento_itens;"
docker compose --profile app run --rm -T --no-deps app padrao >/dev/null
bin/ms sa -i /scripts/32_qs_contagem.sql
docker compose kill -s SIGKILL mssql 2>&1 | grep -E 'Killed|rror' || true
bin/ms-online
bin/ms sa -i /scripts/32_qs_contagem.sql
CMD
c <<'CMD'
# Same hard stop, after asking for a flush.
docker compose --profile app run --rm -T --no-deps app padrao >/dev/null
bin/ms sa -i /scripts/32_qs_contagem.sql
bin/ms sa -d rede -Q "EXEC sp_query_store_flush_db;"
docker compose kill -s SIGKILL mssql 2>&1 | grep -E 'Killed|rror' || true
bin/ms-online
bin/ms sa -i /scripts/32_qs_contagem.sql
CMD
c <<'CMD'
# docker compose stop in this image: same effect as the hard stop, not as SHUTDOWN.
# Process 1 is a bash script, and the signal does not reach the engine before the deadline.
docker compose exec -T mssql cat /proc/1/cmdline | tr '\0' ' '; echo
docker compose --profile app run --rm -T --no-deps app padrao >/dev/null
bin/ms sa -i /scripts/32_qs_contagem.sql
docker compose stop -t 15 mssql 2>&1 | grep -E 'Stopped|rror' || true
bin/ms-online
bin/ms sa -i /scripts/32_qs_contagem.sql
CMD
