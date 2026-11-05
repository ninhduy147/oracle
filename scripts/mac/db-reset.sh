#!/usr/bin/env bash
# db-reset: xóa sạch đối tượng schema ZOO rồi nạp lại (Giai đoạn 1).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
load_env
require_docker

if [[ ! -f "${ROOT_DIR}/db/01_reset.sql" ]]; then
  echo "[!] Chưa có db/01_reset.sql — chờ Giai đoạn 1." >&2
  exit 1
fi

echo "==> Reset schema ZOO rồi nạp lại..."
docker compose exec -T -e NLS_LANG=.AL32UTF8 db \
  bash -c "sqlplus -s ${ORACLE_USER:-ZOO}/${ORACLE_PASSWORD_ZOO:-ZooApp_Demo1}@FREEPDB1 @/db/01_reset.sql"

"${SCRIPT_DIR}/db-init.sh"
