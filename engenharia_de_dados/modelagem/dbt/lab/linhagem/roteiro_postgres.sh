#!/usr/bin/env bash
# Postgres phases. Each block is captured with its command; failures are part of the evidence,
# so the script goes on when a command returns non-zero.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

fase() { S="saidas/$1.txt"; : > "$S"; }
c() { ./capturar.sh "$S" "$(cat)"; }

# ---------------------------------------------------------------------------------------------
fase pg_00_ambiente
c <<'CMD'
bin/pg postgres admin_lab lab -c "SELECT version();"
CMD
c <<'CMD'
bin/pg postgres admin_lab lab <<'SQL'
SELECT name, setting, context
FROM pg_settings
WHERE name IN ('shared_preload_libraries', 'compute_query_id', 'pg_stat_statements.track',
               'pg_stat_statements.max', 'pg_stat_statements.save',
               'log_min_duration_statement', 'log_statement', 'log_min_duration_sample',
               'log_statement_sample_rate', 'log_parameter_max_length', 'log_line_prefix',
               'track_activities', 'track_activity_query_size', 'session_preload_libraries')
ORDER BY name;
SQL
CMD

# ---------------------------------------------------------------------------------------------
fase pg_01_activity
c <<'CMD'
# While the report runs: the text carries the literal value, for whoever can see it.
bin/pg postgres app_relatorio erp_relatorios -q -c "SELECT pg_sleep(5), count(*) FROM relatorios.vw_faturamento_itens WHERE trim(cliente) = 'Cliente A';" >/dev/null &
bin/esperar-sessao postgres active
bin/pg postgres admin_lab lab -f /cenario/ver_activity.sql
bin/pg postgres monitor_lab lab -f /cenario/ver_activity.sql
wait
CMD
c <<'CMD'
# After the session closes there is nothing left to read.
bin/pg postgres admin_lab lab -f /cenario/ver_activity.sql
CMD
c <<'CMD'
# An idle session still shows its last statement.
{ echo "SELECT 'ultima consulta da sessao' AS marcador;"; sleep 4; } | bin/pg postgres app_relatorio erp_relatorios -q >/dev/null &
bin/esperar-sessao postgres idle
bin/pg postgres admin_lab lab -f /cenario/ver_activity.sql
wait
CMD
c <<'CMD'
# A statement longer than track_activity_query_size is cut.
{ printf "SELECT pg_sleep(4), '"; head -c 1500 /dev/zero | tr '\0' x; printf "' AS texto_longo;\n"; } | bin/pg postgres app_relatorio erp_relatorios -q >/dev/null &
bin/esperar-sessao postgres active
bin/pg postgres admin_lab lab -f /cenario/ver_activity.sql
wait
CMD

# ---------------------------------------------------------------------------------------------
fase pg_02_statements
c <<'CMD'
bin/pg postgres admin_lab lab -a <<'SQL'
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SELECT count(*) AS colunas, string_agg(attname, ', ' ORDER BY attnum) AS nomes
FROM pg_attribute
WHERE attrelid = 'pg_stat_statements'::regclass AND attnum > 0
  AND attname ~ '(user|role|app|host|client|plan$|param|literal|time$|stats_since)';
SELECT pg_stat_statements_reset() IS NOT NULL AS zerado;
SQL
CMD
c <<'CMD'
# The application runs the report twice, with different literals.
bin/pg postgres app_relatorio erp_relatorios -q -f /cenario/app_relatorio.sql
bin/pg postgres app_relatorio erp_relatorios -q -f /cenario/app_relatorio_2.sql
CMD
c <<'CMD'
bin/pg postgres admin_lab lab -f /cenario/ver_statements.sql
CMD
c <<'CMD'
# A role with no extra privilege sees the numbers, not the text.
bin/pg postgres monitor_lab lab -f /cenario/ver_statements.sql
CMD
c <<'CMD'
bin/pg postgres admin_lab lab -a -c "GRANT pg_read_all_stats TO monitor_lab;"
bin/pg postgres monitor_lab lab -f /cenario/ver_statements.sql
bin/pg postgres admin_lab lab -a -c "REVOKE pg_read_all_stats FROM monitor_lab;"
CMD
c <<'CMD'
# Default track = top: nothing inside the function. With track = all the inner statement appears.
bin/pg postgres admin_lab lab -a <<'SQL'
ALTER SYSTEM SET pg_stat_statements.track = 'all';
SELECT pg_reload_conf();
SELECT pg_sleep(1);
SELECT pg_stat_statements_reset() IS NOT NULL AS zerado;
SQL
bin/pg postgres app_relatorio erp_relatorios -q -f /cenario/app_relatorio.sql >/dev/null
bin/pg postgres admin_lab lab -f /cenario/ver_statements.sql
bin/pg postgres admin_lab lab -a <<'SQL'
ALTER SYSTEM RESET pg_stat_statements.track;
SELECT pg_reload_conf();
SQL
CMD

# ---------------------------------------------------------------------------------------------
fase pg_03_log
c <<'CMD'
# Threshold of 250 ms: the fast report does not reach the log, a slow one does, with its literal.
d=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
bin/pg postgres admin_lab lab -Atc "SHOW log_min_duration_statement;"
bin/pg postgres app_relatorio erp_relatorios -q -f /cenario/app_relatorio.sql >/dev/null
bin/pg postgres app_relatorio erp_relatorios -q -c "SELECT pg_sleep(0.4), count(*) FROM relatorios.vw_faturamento_itens WHERE trim(cliente) = 'Cliente A';" >/dev/null
sleep 1
bin/pglog postgres "$d" 'app=erp_relatorios'
CMD
c <<'CMD'
# Narrow capture: threshold zero for one role, applied to its new sessions, with no restart.
bin/pg postgres admin_lab lab -a -c "ALTER ROLE app_relatorio SET log_min_duration_statement = 0;"
d=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
bin/pg postgres app_relatorio erp_relatorios -q -f /cenario/app_relatorio.sql >/dev/null
bin/pg postgres monitor_lab outra_aplicacao -q -c "SELECT 1 AS de_outro_papel;" >/dev/null
sleep 1
bin/pglog postgres "$d" 'app=(erp_relatorios|outra_aplicacao)'
bin/pg postgres admin_lab lab -a -c "ALTER ROLE app_relatorio RESET log_min_duration_statement;"
CMD
c <<'CMD'
# Who may change it: an ordinary role is refused until it receives SET on that parameter.
bin/pg postgres monitor_lab lab -c "SET log_min_duration_statement = 0;"
bin/pg postgres admin_lab lab -a -c "GRANT SET ON PARAMETER log_min_duration_statement TO monitor_lab;"
bin/pg postgres monitor_lab lab -c "SET log_min_duration_statement = 0;"
bin/pg postgres admin_lab lab -a -c "REVOKE SET ON PARAMETER log_min_duration_statement FROM monitor_lab;"
CMD
c <<'CMD'
# Bind parameters are logged too, unless log_parameter_max_length says otherwise.
bin/pg postgres admin_lab lab -a <<'SQL'
ALTER ROLE app_relatorio SET log_statement = 'all';
SQL
d=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
bin/pg postgres app_relatorio erp_relatorios -q <<'SQL' >/dev/null
SELECT pedido_id, valor_item FROM relatorios.vw_faturamento_itens WHERE trim(cliente) = $1 \bind 'Cliente A' \g
SQL
sleep 1
bin/pglog postgres "$d" 'app=erp_relatorios'
bin/pg postgres admin_lab lab -a <<'SQL'
ALTER ROLE app_relatorio SET log_parameter_max_length = 0;
SQL
d=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
bin/pg postgres app_relatorio erp_relatorios -q <<'SQL' >/dev/null
SELECT pedido_id, valor_item FROM relatorios.vw_faturamento_itens WHERE trim(cliente) = $1 \bind 'Cliente A' \g
SQL
sleep 1
bin/pglog postgres "$d" 'app=erp_relatorios'
bin/pg postgres admin_lab lab -a <<'SQL'
ALTER ROLE app_relatorio RESET log_statement;
ALTER ROLE app_relatorio RESET log_parameter_max_length;
SQL
CMD
c <<'CMD'
# Sampling: 200 statements at a rate of 0.1. The count changes on each run.
bin/pg postgres admin_lab lab -a <<'SQL'
ALTER ROLE app_relatorio SET log_min_duration_sample = 0;
ALTER ROLE app_relatorio SET log_statement_sample_rate = 0.1;
SQL
d=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
seq 1 200 | sed 's/.*/SELECT count(*) FROM relatorios.vw_faturamento_itens WHERE pedido_id = &;/' | bin/pg postgres app_relatorio erp_relatorios -q >/dev/null
sleep 1
bin/pglog postgres "$d" 'app=erp_relatorios' | grep -c 'duration:'
bin/pg postgres admin_lab lab -a <<'SQL'
ALTER ROLE app_relatorio RESET log_min_duration_sample;
ALTER ROLE app_relatorio RESET log_statement_sample_rate;
SQL
CMD

# ---------------------------------------------------------------------------------------------
fase pg_04_auto_explain
c <<'CMD'
# One role, new sessions only: the plan of the statement inside the function, with no log_analyze.
bin/pg postgres admin_lab lab -a <<'SQL'
ALTER ROLE app_relatorio SET session_preload_libraries = 'auto_explain';
ALTER ROLE app_relatorio SET auto_explain.log_min_duration = 0;
ALTER ROLE app_relatorio SET auto_explain.log_nested_statements = on;
SQL
d=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
bin/pg postgres app_relatorio erp_relatorios -q -c "SELECT loja, faturamento FROM relatorios.faturamento_por_loja('2026-10-20', '2026-10-22');" >/dev/null
sleep 1
bin/pglog postgres "$d" 'Query Text|Scan on|Scan using|p_inicio' | cut -c1-150
bin/pg postgres admin_lab lab -a <<'SQL'
ALTER ROLE app_relatorio RESET session_preload_libraries;
ALTER ROLE app_relatorio RESET auto_explain.log_min_duration;
ALTER ROLE app_relatorio RESET auto_explain.log_nested_statements;
SQL
CMD

# ---------------------------------------------------------------------------------------------
fase pg_05_catalogo
c <<'CMD'
bin/pg postgres admin_lab lab -f /cenario/catalogo.sql
CMD
c <<'CMD'
# Same queries for a role that owns nothing and has no grant on the schemas.
bin/pg postgres monitor_lab lab -f /cenario/catalogo.sql
bin/pg postgres monitor_lab lab -c "SELECT count(*) FROM relatorios.vw_faturamento_itens;"
CMD

# ---------------------------------------------------------------------------------------------
fase pg_06_replica
c <<'CMD'
timeout 120 docker compose --profile replica up -d --wait --quiet-pull replica 2>&1 | grep -E 'Healthy|Error|error' || true
bin/pg postgres admin_lab lab -Atc "SELECT 'primario em recuperacao: ' || pg_is_in_recovery();"
bin/pg replica admin_lab lab -Atc "SELECT 'replica em recuperacao: ' || pg_is_in_recovery();"
bin/pg replica admin_lab lab -Atc "SHOW shared_preload_libraries;"
bin/pg replica admin_lab lab -Atc "SELECT pg_stat_statements_reset() IS NOT NULL AS zerado_na_replica;"
bin/pg postgres admin_lab lab -Atc "SELECT pg_stat_statements_reset() IS NOT NULL AS zerado_no_primario;"
CMD
c <<'CMD'
# The report runs on the primary. Who counted it?
bin/pg postgres app_relatorio erp_relatorios -q -f /cenario/app_relatorio.sql >/dev/null
echo "--- primario"; bin/pg postgres admin_lab lab -f /cenario/ver_statements.sql
echo "--- replica"; bin/pg replica admin_lab lab -f /cenario/ver_statements.sql
CMD
c <<'CMD'
# Now it runs on the replica: its entries show up there, the primary stays as it was.
bin/pg replica app_relatorio erp_relatorios -q -f /cenario/app_relatorio.sql >/dev/null
echo "--- primario"; bin/pg postgres admin_lab lab -f /cenario/ver_statements.sql
echo "--- replica"; bin/pg replica admin_lab lab -f /cenario/ver_statements.sql
CMD
c <<'CMD'
# pg_stat_activity is per server as well.
bin/pg replica app_relatorio erp_relatorios -q -c "SELECT pg_sleep(4), count(*) FROM relatorios.vw_faturamento_itens WHERE trim(cliente) = 'Cliente A';" >/dev/null &
bin/esperar-sessao replica active
echo "--- primario"; bin/pg postgres admin_lab lab -f /cenario/ver_activity.sql
echo "--- replica"; bin/pg replica admin_lab lab -f /cenario/ver_activity.sql
wait
CMD
c <<'CMD'
# Log configuration on the replica: ALTER SYSTEM and reload work, ALTER ROLE and CREATE EXTENSION do not.
bin/pg replica admin_lab lab -a <<'SQL'
ALTER ROLE app_relatorio SET log_min_duration_statement = 0;
CREATE EXTENSION IF NOT EXISTS pg_buffercache;
ALTER SYSTEM SET log_min_duration_statement = 0;
SELECT pg_reload_conf();
SELECT pg_sleep(1);
SQL
d=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
bin/pg replica app_relatorio erp_relatorios -q -f /cenario/app_relatorio.sql >/dev/null
sleep 1
echo "--- log da replica"; bin/pglog replica "$d" 'app=erp_relatorios' | cut -c1-200
echo "--- log do primario"; bin/pglog postgres "$d" 'app=erp_relatorios' | cut -c1-200
bin/pg replica admin_lab lab -a <<'SQL'
ALTER SYSTEM RESET log_min_duration_statement;
SELECT pg_reload_conf();
SQL
CMD
c <<'CMD'
# The catalog answers on the replica too, without touching the primary.
bin/pg replica monitor_lab lab -f /cenario/catalogo.sql | head -12
CMD
c <<'CMD'
# The replica loads its own libraries: without the preload there, the view fails on it.
REPLICA_PRELOAD= timeout 120 docker compose --profile replica up -d --wait --force-recreate --no-deps replica 2>&1 | grep -E 'Healthy|rror' || true
bin/pg replica admin_lab lab -c "SELECT count(*) FROM pg_stat_statements;"
bin/pg postgres admin_lab lab -Atc "SELECT 'primario segue contando: ' || count(*) FROM pg_stat_statements;"
CMD
c <<'CMD'
timeout 60 docker compose --profile replica stop replica 2>&1 | grep -E 'Stopped|rror' || true
CMD

# ---------------------------------------------------------------------------------------------
fase pg_07_reinicio
c <<'CMD'
# Clean restart: pg_stat_statements.save = on keeps the entries.
bin/pg postgres admin_lab lab -Atc "SELECT 'entradas antes: ' || count(*) FROM pg_stat_statements;"
docker compose restart postgres 2>&1 | grep -E 'Started|rror' || true
timeout 60 bash -c 'until docker compose exec -T postgres pg_isready -q -U admin_lab -d rede; do sleep 1; done'
bin/pg postgres admin_lab lab -Atc "SELECT 'entradas depois do reinicio limpo: ' || count(*) FROM pg_stat_statements;"
CMD
c <<'CMD'
# Crash: the statistics are not saved.
docker compose kill -s SIGKILL postgres 2>&1 | grep -E 'Killed|rror' || true
timeout 120 docker compose up -d --wait postgres 2>&1 | grep -E 'Healthy|rror' || true
bin/pg postgres admin_lab lab -Atc "SELECT 'entradas depois de queda: ' || count(*) FROM pg_stat_statements;"
CMD

# ---------------------------------------------------------------------------------------------
fase pg_08_custo_laboratorio
c <<'CMD'
bin/custo-pg
CMD
