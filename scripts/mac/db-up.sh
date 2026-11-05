#!/usr/bin/env bash
# db-up: khởi động container Oracle, in log chờ DATABASE IS READY.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
load_env
require_docker

echo "==> Image: ${ORACLE_IMAGE:-container-registry.oracle.com/database/free:latest}"
echo "==> docker compose up -d db"
docker compose up -d db

echo ""
echo "==> Đợi Oracle sẵn sàng (lần đầu có thể 5–15 phút)..."
echo "    Theo dõi log: docker compose logs -f db"
echo "    Báo hiệu: DATABASE IS READY TO USE"
echo ""

# Poll health / log tối đa ~20 phút
READY=0
for i in $(seq 1 120); do
  if docker compose logs db 2>/dev/null | grep -q "DATABASE IS READY TO USE"; then
    READY=1
    break
  fi
  # healthcheck healthy cũng đủ
  STATUS="$(docker inspect --format='{{.State.Health.Status}}' zoo-oracle 2>/dev/null || echo starting)"
  if [[ "${STATUS}" == "healthy" ]]; then
    READY=1
    break
  fi
  printf "\r    [%3d/120] trạng thái=%s ..." "${i}" "${STATUS}"
  sleep 10
done
echo ""

if [[ "${READY}" -eq 1 ]]; then
  echo "==> Oracle đã sẵn sàng. Thử: ./scripts/mac/sql-sys.sh"
else
  echo "[!] Hết thời gian chờ. Kiểm tra: docker compose logs db" >&2
  exit 1
fi
