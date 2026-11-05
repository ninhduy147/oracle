#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_common.sh"
load_env
require_docker
docker compose exec -T -e ORACLE_PWD="$(ORACLE_PWD_VALUE)" -e NLS_LANG=.AL32UTF8 db \
  bash /admin/05_datapump_import.sh
