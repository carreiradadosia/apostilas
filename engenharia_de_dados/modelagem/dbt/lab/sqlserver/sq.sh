#!/usr/bin/env bash
# Usage: ./sq.sh <database> <script under sql/> [extra sqlcmd options, such as -b or -v name=value]
# The password comes from SQLCMDPASSWORD inside the container, never from the command line.
set -uo pipefail
banco="$1"; script="$2"; shift 2
exec docker exec -i mssql-tsql-mssql-1 /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -C -I -f 65001 -W -s '|' -d "$banco" -i "/sql/$script" "$@"
