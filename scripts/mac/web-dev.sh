#!/usr/bin/env bash
# web-dev: chạy Vue Vite (Giai đoạn 5).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
load_env

if [[ ! -f "${ROOT_DIR}/zoo-web/package.json" ]]; then
  echo "[!] Chưa có zoo-web — chờ Giai đoạn 5." >&2
  exit 1
fi

cd "${ROOT_DIR}/zoo-web"
if [[ ! -d node_modules ]]; then
  npm install
fi
exec npm run dev
