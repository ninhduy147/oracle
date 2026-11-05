#!/usr/bin/env bash
# tunnel: Cloudflare Tunnel chia sẻ API localhost:8000 cho nhóm.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
load_env

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "[!] Chưa có cloudflared. Cài: brew install cloudflare/cloudflare/cloudflared" >&2
  exit 1
fi

PORT="${API_PORT:-8000}"
echo "==> cloudflared tunnel --url http://localhost:${PORT}"
echo "    Sau khi có URL public, cập nhật VITE_API_URL và CORS_ORIGINS trong .env"
exec cloudflared tunnel --url "http://localhost:${PORT}"
