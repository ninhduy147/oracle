#!/usr/bin/env bash
# Hàm dùng chung cho script macOS — load .env, xác định thư mục gốc repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${ROOT_DIR}"

load_env() {
  if [[ ! -f "${ROOT_DIR}/.env" ]]; then
    echo "[!] Chưa có .env — chạy ./scripts/mac/setup.sh trước." >&2
    exit 1
  fi
  # shellcheck disable=SC1091
  set -a
  source "${ROOT_DIR}/.env"
  set +a
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "[!] Không tìm thấy Docker. Cài Docker Desktop rồi thử lại." >&2
    exit 1
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "[!] Docker daemon chưa chạy. Mở Docker Desktop." >&2
    exit 1
  fi
}

ORACLE_PWD_VALUE() {
  echo "${ORACLE_PWD:-${ORACLE_PASSWORD:-ZooOracle_Demo1}}"
}
