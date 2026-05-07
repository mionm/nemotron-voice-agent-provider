#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERR] docker is required in this shell." >&2
  echo "      If using WSL/Git Bash, enable Docker Desktop WSL integration first." >&2
  exit 1
fi

COMPOSE_CMD=()
if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD=(docker-compose)
else
  echo "[ERR] docker compose is required (docker compose plugin or docker-compose)." >&2
  exit 1
fi

echo "[nemotron-voice-agent] Stopping docker compose stack..."
"${COMPOSE_CMD[@]}" down
echo "[nemotron-voice-agent] Stopped."

