#!/usr/bin/env bash
# sql-zoo: mở sqlplus user ZOO vào FREEPDB1.
# Cách dùng:
#   ./scripts/mac/sql-zoo.sh
#   ./scripts/mac/sql-zoo.sh file.sql
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
load_env
require_docker

ZOO_USER="${ORACLE_USER:-ZOO}"
ZOO_PWD="${ORACLE_PASSWORD_ZOO:-ZooApp_Demo1}"
SERVICE="${ORACLE_SERVICE:-FREEPDB1}"
SQL_FILE="${1:-}"

export NLS_LANG="${NLS_LANG:-.AL32UTF8}"

if [[ -n "${SQL_FILE}" ]]; then
  if [[ ! -f "${SQL_FILE}" ]]; then
    echo "[!] Không thấy file: ${SQL_FILE}" >&2
    exit 1
  fi
  echo "==> Chạy ${SQL_FILE} với ${ZOO_USER}@${SERVICE}"
  docker compose exec -T -e NLS_LANG=.AL32UTF8 db \
    bash -c "sqlplus -s ${ZOO_USER}/${ZOO_PWD}@${SERVICE}" < "${SQL_FILE}"
else
  echo "==> sqlplus ${ZOO_USER}@${SERVICE} (thoát: exit)"
  docker compose exec -e NLS_LANG=.AL32UTF8 db \
    sqlplus "${ZOO_USER}/${ZOO_PWD}@${SERVICE}"
fi
