#!/usr/bin/env bash
# sql-sys: mở sqlplus SYSDBA vào PDB FREEPDB1 (mặc định) hoặc CDB nếu truyền --cdb.
# Cách dùng:
#   ./scripts/mac/sql-sys.sh              # interactive FREEPDB1
#   ./scripts/mac/sql-sys.sh --cdb        # interactive CDB FREE
#   ./scripts/mac/sql-sys.sh file.sql     # chạy một file SQL trong FREEPDB1
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
load_env
require_docker

PWD_VAL="$(ORACLE_PWD_VALUE)"
TARGET="FREEPDB1"
SQL_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cdb) TARGET="FREE"; shift ;;
    --pdb) TARGET="FREEPDB1"; shift ;;
    *) SQL_FILE="$1"; shift ;;
  esac
done

# NLS_LANG để tiếng Việt không thành ???
export NLS_LANG="${NLS_LANG:-.AL32UTF8}"

if [[ -n "${SQL_FILE}" ]]; then
  # File trên máy host — mount sẵn /db hoặc /admin; nếu đường dẫn tuyệt đối thì cat vào sqlplus
  if [[ ! -f "${SQL_FILE}" ]]; then
    echo "[!] Không thấy file: ${SQL_FILE}" >&2
    exit 1
  fi
  echo "==> Chạy ${SQL_FILE} với SYS@${TARGET} AS SYSDBA"
  docker compose exec -T -e NLS_LANG=.AL32UTF8 db \
    bash -c "sqlplus -s sys/${PWD_VAL}@${TARGET} as sysdba" < "${SQL_FILE}"
else
  echo "==> sqlplus SYS@${TARGET} AS SYSDBA (thoát: exit)"
  docker compose exec -e NLS_LANG=.AL32UTF8 db \
    sqlplus "sys/${PWD_VAL}@${TARGET} as sysdba"
fi
