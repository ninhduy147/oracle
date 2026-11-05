#!/usr/bin/env bash
# api-dev: chạy FastAPI ở chế độ dev (Giai đoạn 4).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
load_env

if [[ ! -f "${ROOT_DIR}/zoo-api/requirements.txt" ]]; then
  echo "[!] Chưa có zoo-api — chờ Giai đoạn 4." >&2
  exit 1
fi

cd "${ROOT_DIR}/zoo-api"
PY=python3.12
command -v "$PY" >/dev/null || PY=python3
if [[ ! -d .venv ]]; then
  "$PY" -m venv .venv
fi
# shellcheck disable=SC1091
source .venv/bin/activate
pip install -r requirements.txt
exec uvicorn app.main:app --reload --host "${API_HOST:-0.0.0.0}" --port "${API_PORT:-8000}"
