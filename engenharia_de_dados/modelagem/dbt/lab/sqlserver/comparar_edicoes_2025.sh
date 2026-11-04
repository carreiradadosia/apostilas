#!/usr/bin/env bash
# Usage: ./comparar_edicoes_2025.sh <folder with a full 2025 run under MSSQL_PID=StandardDeveloper>
# Diffs saidas/2025 (EnterpriseDeveloper) against that folder, after removing what changes on every run:
# the capture line, the container id in error messages, and generated constraint names.
set -uo pipefail
export LC_ALL=C
cd "$(dirname "$0")" || exit 1
outra="${1:?usage: ./comparar_edicoes_2025.sh <folder>}"
saida=saidas/diferencas_2025_enterprise_standard.txt
normalizar() {
  sed -E -e 's/^\[exit ([0-9]+), .*\]$/[exit \1]/' \
         -e 's/Server [0-9a-f]{12}/Server <conteiner>/' \
         -e 's/PK__[A-Za-z0-9_]+__[0-9A-F]+/PK__<gerado>/g' "$1"
}
{
  echo "Comparação da execução completa na 2025 com MSSQL_PID=EnterpriseDeveloper (saidas/2025) e com MSSQL_PID=StandardDeveloper, sem data da captura, id do contêiner e nome gerado de restrição."
  for arquivo in saidas/2025/lab*.txt; do
    nome=$(basename "$arquivo")
    [[ -f "$outra/$nome" ]] || continue
    if diff -q <(normalizar "$arquivo") <(normalizar "$outra/$nome") > /dev/null; then
      printf '=== %s: igual\n' "$nome"
    else
      printf '=== %s: diferente\n' "$nome"
      diff -U0 --label enterprise --label standard <(normalizar "$arquivo") <(normalizar "$outra/$nome") | grep -v -E '^@@'
    fi
  done
} > "$saida"
cat "$saida"
