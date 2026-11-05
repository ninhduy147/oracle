#!/usr/bin/env bash
# admin-run <số>: chạy script quản trị admin/0N_*.sql (Giai đoạn 3).
# Ví dụ: ./scripts/mac/admin-run.sh 02
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
load_env
require_docker

NUM="${1:-}"
if [[ -z "${NUM}" ]]; then
  echo "Cách dùng: ./scripts/mac/admin-run.sh <số>" >&2
  echo "  01 = instance, 02 = tablespace, 04 = users, ..." >&2
  exit 1
fi

# Chuẩn hóa: 1 -> 01, 2 -> 02
NUM="$(printf '%02d' "$((10#${NUM}))" 2>/dev/null || echo "${NUM}")"

FILE="$(ls "${ROOT_DIR}/admin/${NUM}"_*.sql 2>/dev/null | head -n 1 || true)"
if [[ -z "${FILE}" ]]; then
  echo "[!] Không tìm thấy admin/${NUM}_*.sql" >&2
  exit 1
fi

echo "==> Chạy ${FILE}"
echo "    Lưu ý: một số lệnh (SHUTDOWN/ARCHIVELOG) cần chạy tay theo ADMIN_RUNBOOK.md"
"${SCRIPT_DIR}/sql-sys.sh" "${FILE}"
