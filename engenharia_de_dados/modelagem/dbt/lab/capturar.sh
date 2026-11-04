#!/usr/bin/env bash
# Usage: ./capturar.sh saidas/arquivo.txt 'command'
# Appends the command, its real output, exit code and date to the capture file.
# The stamp has no time of day and no duration: published outputs carry the date only.
# The local user name and the lab path are replaced, so the capture can be published.
set -uo pipefail
export LC_ALL=C
cd "$(dirname "$0")" || exit 1
arquivo="$1"; shift
comando="$*"
pasta_lab="$(pwd)"
usuario="$(id -un)"
{
  printf '\n$ %s\n' "$comando"
  bash -c "$comando" 2>&1
  codigo=$?
  printf '[exit %s, %s]\n' "$codigo" "$(date +%Y-%m-%d)"
} | sed -u -e 's/\x1b\[[0-9;]*m//g' -e "s#${pasta_lab}#<lab>#g" -e "s#${HOME}#<home>#g" -e "s#${usuario}#<usuario>#g" | tee -a "$arquivo"
