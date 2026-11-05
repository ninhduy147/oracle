#!/usr/bin/env bash
# db-init: tạo tablespace + user ZOO, nạp run_all.sql (Giai đoạn 1).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
load_env
require_docker

if [[ ! -f "${ROOT_DIR}/db/00_create_tablespace_user.sql" ]]; then
  echo "[!] Chưa có db/00_create_tablespace_user.sql — chờ Giai đoạn 1." >&2
  exit 1
fi

PWD_VAL="$(ORACLE_PWD_VALUE)"
echo "==> [1/2] Tạo tablespace + user (SYS@FREEPDB1)"
docker compose exec -T -e NLS_LANG=.AL32UTF8 db \
  bash -c "sqlplus -s sys/${PWD_VAL}@FREEPDB1 as sysdba @/db/00_create_tablespace_user.sql"

echo "==> [2/2] Nạp schema ZOO (run_all.sql)"
docker compose exec -T -e NLS_LANG=.AL32UTF8 db \
  bash -c "sqlplus -s ${ORACLE_USER:-ZOO}/${ORACLE_PASSWORD_ZOO:-ZooApp_Demo1}@FREEPDB1 @/db/run_all.sql"

echo "==> db-init xong."
