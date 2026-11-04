#!/usr/bin/env bash
# Usage: ./capturar.sh saidas/arquivo.txt 'command'
# Appends the command, its real output and exit code to the capture file.
# The local user name, the lab path and the lab secrets are replaced, so the capture can be published.
# No elapsed time here: the SQL Server terms restrict disclosing benchmark results, so captures
# carry the date only and the SQL Server scripts select no duration or CPU column.
# The second sed drops the time of day from the dbt prefix, the Postgres log prefix and the event session row.
set -uo pipefail
export LC_ALL=C
cd "$(dirname "$0")" || exit 1
arquivo="$1"; shift
comando="$*"
pasta_lab="$(pwd)"
usuario="$(id -un)"

segredos=()
while IFS='=' read -r nome valor; do
  case "$nome" in
    *PASSWORD) segredos+=(-e "s#${valor}#<segredo>#g") ;;
  esac
done < .env

{
  printf '\n$ %s\n' "$comando"
  bash -c "$comando" 2>&1
  codigo=$?
  printf '[exit %s, %s]\n' "$codigo" "$(date +%Y-%m-%d)"
} | sed -u -e 's/\x1b\[[0-9;]*m//g' -e "s#${pasta_lab}#<lab>#g" -e "s#${HOME}#<home>#g" -e "s#${usuario}#<usuario>#g" "${segredos[@]}" \
  | sed -uE -e 's/^[0-9]{2}:[0-9]{2}:[0-9]{2}  //' \
      -e 's/^([0-9]{4}-[0-9]{2}-[0-9]{2}) [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+ UTC /\1 UTC /' \
      -e 's/^(relatorio_lab\|[0-9]{4}-[0-9]{2}-[0-9]{2}) [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+$/\1/' \
  | tee -a "$arquivo"
