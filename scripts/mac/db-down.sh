#!/usr/bin/env bash
# db-down: dừng container (giữ volume dữ liệu).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
require_docker

echo "==> docker compose stop db"
docker compose stop db
echo "==> Đã dừng. Volume zoo_oradata vẫn giữ dữ liệu."
echo "    Xóa sạch dữ liệu: docker compose down -v"
