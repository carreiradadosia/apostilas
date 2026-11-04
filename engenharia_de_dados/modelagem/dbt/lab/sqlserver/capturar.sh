#!/usr/bin/env bash
# Usage: ./capturar.sh saidas/arquivo.txt 'command'
# Appends the command, its real output and exit code to the capture file.
# The local user name, the lab path and the sa password are replaced, so the capture can be published.
# Date only, no time of day and no elapsed time, on purpose: the license terms require Microsoft's written
# approval to disclose benchmark results.
set -uo pipefail
export LC_ALL=C
cd "$(dirname "$0")" || exit 1
arquivo="$1"; shift
comando="$*"
pasta_lab="$(pwd)"
usuario="$(id -un)"
senha="$(grep -s '^MSSQL_SA_PASSWORD=' .env | cut -d= -f2-)"  # higiene:ignore, read from .env
{
  printf '\n$ %s\n' "$comando"
  bash -c "$comando" 2>&1
  codigo=$?
  printf '[exit %s, %s]\n' "$codigo" "$(date +%Y-%m-%d)"
} | sed -u -e 's/\x1b\[[0-9;]*m//g' -e "s#${senha:-__sem_senha__}#<senha>#g" -e "s#${pasta_lab}#<lab>#g" -e "s#${HOME}#<home>#g" -e "s#${usuario}#<usuario>#g" | tee -a "$arquivo"
