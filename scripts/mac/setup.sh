#!/usr/bin/env bash
# setup: kiểm tra Docker, tạo .env từ .env.example nếu chưa có.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"

echo "==> Kiểm tra Docker..."
require_docker
docker --version
docker compose version

echo "==> Kiến trúc máy: $(uname -m)"
echo "==> Hệ điều hành: $(uname -s)"

if [[ ! -f "${ROOT_DIR}/.env" ]]; then
  cp "${ROOT_DIR}/.env.example" "${ROOT_DIR}/.env"
  echo "==> Đã tạo .env từ .env.example — hãy xem lại mật khẩu nếu cần."
else
  echo "==> .env đã tồn tại, giữ nguyên."
fi

mkdir -p "${ROOT_DIR}/backup"
echo "==> Setup xong. Tiếp theo: ./scripts/mac/db-up.sh"
