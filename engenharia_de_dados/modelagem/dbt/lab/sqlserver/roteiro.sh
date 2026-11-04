#!/usr/bin/env bash
# Usage: ACCEPT_EULA=Y ./roteiro.sh <2022|2025>
# Runs the whole script from an empty volume, captures every step and takes the project down at the end.
set -uo pipefail
cd "$(dirname "$0")" || exit 1

versao="${1:?usage: ACCEPT_EULA=Y ./roteiro.sh 2022 or 2025}"
case "$versao" in
  2022) export MSSQL_TAG=2022-CU27-GDR1-ubuntu-22.04 MSSQL_PID=Developer ;;
  2025) export MSSQL_TAG=2025-CU10-ubuntu-24.04 MSSQL_PID="${MSSQL_PID:-EnterpriseDeveloper}" ;;
  *) echo "unknown version: $versao" >&2; exit 2 ;;
esac

./preparar.sh
saida="${SAIDA:-saidas/$versao}"
mkdir -p "$saida"
for lab in lab0_ambiente lab1_silver_a_mao lab2_fuso_e_datas lab3_gold_estrela_e_fan_out lab4_preco_update_e_scd2 \
           lab5_conferencia_postgres lab6_texto_e_collation lab7_datas_em_texto lab8_nulos lab9_dedup \
           lab10_merge_e_recarga lab11_chave_substituta lab12_versoes lab13_sintaxe_do_postgres \
           lab14_erro_na_recarga lab15_datas_com_tab; do
  : > "$saida/$lab.txt"
done

cap() { local arquivo="$1"; shift; ./capturar.sh "$saida/$arquivo.txt" "$*"; }

docker compose up -d --quiet-pull
# shellcheck disable=SC2016  # expanded by the inner bash
timeout 180 bash -c 'until [ "$(docker inspect -f "{{.State.Health.Status}}" mssql-tsql-mssql-1)" = healthy ]; do sleep 2; done' \
  || { echo "SQL Server did not become healthy" >&2; docker logs --tail 30 mssql-tsql-mssql-1; exit 1; }

cap lab0_ambiente "env -u ACCEPT_EULA docker compose config --quiet"
cap lab0_ambiente "docker image inspect -f '{{index .RepoDigests 0}}' \$(docker inspect -f '{{.Config.Image}}' mssql-tsql-mssql-1)"
cap lab0_ambiente "docker port mssql-tsql-mssql-1 | wc -l"
cap lab0_ambiente "docker inspect -f 'memoria_limite_bytes={{.HostConfig.Memory}}' mssql-tsql-mssql-1"
cap lab0_ambiente "docker exec mssql-tsql-mssql-1 ls /opt/mssql-tools18/bin"
cap lab0_ambiente "docker exec mssql-tsql-mssql-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -Q 'SELECT 1 AS sem_flag_de_certificado'"
cap lab0_ambiente "docker exec mssql-tsql-mssql-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -W -h -1 -Q \"SET NOCOUNT ON; SELECT @@VERSION; SELECT SERVERPROPERTY('Edition'); SELECT SERVERPROPERTY('Collation')\""
cap lab0_ambiente "docker exec mssql-tsql-mssql-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -W -i /sql/01_utf8.sql"
cap lab0_ambiente "docker exec mssql-tsql-mssql-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -W -f 65001 -i /sql/01_utf8.sql"
cap lab0_ambiente "./sq.sh master 00_erp_e_dw.sql -b"
cap lab0_ambiente "docker exec mssql-tsql-mssql-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -C -W -h -1 -Q \"SET NOCOUNT ON; SELECT name, collation_name, compatibility_level FROM sys.databases WHERE name IN ('erp', 'dw') ORDER BY name\""

cap lab1_silver_a_mao "./sq.sh dw 10_bronze_carga.sql -b"
cap lab1_silver_a_mao "./sq.sh dw 11_bronze_foto_precos.sql -b -v dia=2026-10-20"
cap lab1_silver_a_mao "./sq.sh dw 20_silver.sql -b"
cap lab1_silver_a_mao "./sq.sh dw 21_silver_antes_depois.sql"

cap lab2_fuso_e_datas "./sq.sh dw 22_fuso.sql"

cap lab3_gold_estrela_e_fan_out "./sq.sh dw 30_gold.sql -b"
cap lab3_gold_estrela_e_fan_out "./sq.sh dw 31_fan_out.sql"

cap lab4_preco_update_e_scd2 "./sq.sh erp erp_noite_21.sql -b"
cap lab4_preco_update_e_scd2 "./sq.sh dw 11_bronze_foto_precos.sql -b -v dia=2026-10-21"
cap lab4_preco_update_e_scd2 "./sq.sh erp erp_noite_22.sql -b"
cap lab4_preco_update_e_scd2 "./sq.sh dw 11_bronze_foto_precos.sql -b -v dia=2026-10-22"
cap lab4_preco_update_e_scd2 "./sq.sh dw 20_silver.sql -b"
cap lab4_preco_update_e_scd2 "./sq.sh dw 30_gold.sql -b"
cap lab4_preco_update_e_scd2 "./sq.sh dw 40_preco_update_apaga.sql"

cap lab5_conferencia_postgres "./sq.sh dw 70_conferencia_postgres.sql"

cap lab6_texto_e_collation "./sq.sh dw 60_texto_e_collation.sql"
cap lab7_datas_em_texto "./sq.sh dw 61_datas_em_texto.sql"
cap lab8_nulos "./sq.sh dw 62_nulos.sql"
cap lab9_dedup "./sq.sh dw 63_dedup.sql"

cap lab10_merge_e_recarga "./sq.sh dw 64a_merge_chave_repetida.sql"
for tentativa in "64c_recarga_sem_xact_abort.sql" "64c_recarga_sem_xact_abort.sql -b" "64d_recarga_com_xact_abort.sql" "64d_recarga_com_xact_abort.sql -b"; do
  cap lab10_merge_e_recarga "./sq.sh dw 64b_recarga_preparar.sql -b"
  cap lab10_merge_e_recarga "./sq.sh dw $tentativa"
  cap lab10_merge_e_recarga "./sq.sh dw 64e_recarga_estado.sql"
done
cap lab10_merge_e_recarga "./sq.sh dw 64f_ddl_em_transacao.sql -b"
cap lab10_merge_e_recarga "./sq.sh dw 64g_ddl_estado.sql"

cap lab11_chave_substituta "./sq.sh dw 65_chave_substituta.sql"
cap lab11_chave_substituta "python3 -c \"import hashlib; print('md5 de 1 em ascii:', hashlib.md5(b'1').hexdigest().upper())\""

cap lab12_versoes "./sq.sh dw 66_versoes.sql"

cap lab13_sintaxe_do_postgres "./sq.sh dw 67_sintaxe_do_postgres.sql"

for tentativa in "68a_recarga_raiserror.sql -b" "68b_recarga_throw.sql -b" "68c_recarga_try_catch.sql -b" "68d_recarga_varios_lotes.sql"; do
  cap lab14_erro_na_recarga "./sq.sh dw 64b_recarga_preparar.sql -b"
  cap lab14_erro_na_recarga "./sq.sh dw $tentativa"
  cap lab14_erro_na_recarga "./sq.sh dw 64e_recarga_estado.sql"
done

cap lab15_datas_com_tab "./sq.sh dw 69_datas_com_tab.sql"

if [[ "${MANTER_DE_PE:-}" != "1" ]]; then
  docker compose down -v
fi
