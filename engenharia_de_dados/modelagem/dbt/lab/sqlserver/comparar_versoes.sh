#!/usr/bin/env bash
# Usage: ./comparar_versoes.sh
# Diffs the 2022 and 2025 captures after removing what changes on every run:
# timestamps in the capture line, the container id in error messages, and generated constraint names.
set -uo pipefail
export LC_ALL=C
cd "$(dirname "$0")" || exit 1
saida=saidas/diferencas_2022_2025.txt
normalizar() {
  sed -E -e 's/^\[exit ([0-9]+), .*\]$/[exit \1]/' \
         -e 's/Server [0-9a-f]{12}/Server <conteiner>/' \
         -e 's/PK__[A-Za-z0-9_]+__[0-9A-F]+/PK__<gerado>/g' "$1"
}
{
  echo "Comparação das capturas de saidas/2022 e saidas/2025, sem data da captura, id do contêiner e nome gerado de restrição."
  for arquivo in saidas/2022/lab*.txt; do
    nome=$(basename "$arquivo")
    [[ -f "saidas/2025/$nome" ]] || continue
    if diff -q <(normalizar "saidas/2022/$nome") <(normalizar "saidas/2025/$nome") > /dev/null; then
      printf '\n=== %s: igual\n' "$nome"
    else
      printf '\n=== %s: diferente\n' "$nome"
      diff -U0 --label 2022 --label 2025 <(normalizar "saidas/2022/$nome") <(normalizar "saidas/2025/$nome") | grep -v -E '^@@'
    fi
  done
} > "$saida"
cat "$saida"
