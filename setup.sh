#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

echo "[nemotron-voice-agent] Setup started..."

if ! command -v git >/dev/null 2>&1; then
  echo "[ERR] git is required." >&2
  exit 1
fi

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

if [[ -f ".gitmodules" ]]; then
  echo "[nemotron-voice-agent] Initializing git submodules..."
  git submodule update --init --recursive
fi

if [[ ! -f ".env" ]]; then
  if [[ -f "config/env.example" ]]; then
    cp "config/env.example" ".env"
    echo "[nemotron-voice-agent] Created .env from config/env.example"
  else
    echo "[ERR] Missing config/env.example" >&2
    exit 1
  fi
fi

ensure_env_key() {
  local key="$1"
  local value="$2"
  if grep -Eq "^${key}=" .env; then
    return 0
  fi
  printf "%s=%s\n" "${key}" "${value}" >> .env
}

# API-mode defaults (cloud endpoints).
ensure_env_key "ASR_SERVER_URL" "grpc.nvcf.nvidia.com:443"
ensure_env_key "TTS_SERVER_URL" "grpc.nvcf.nvidia.com:443"
ensure_env_key "NVIDIA_LLM_URL" "https://integrate.api.nvidia.com/v1"

echo "[nemotron-voice-agent] API-mode defaults ensured in .env (ASR/TTS/LLM URLs)."
echo
echo "[nemotron-voice-agent] Setup done."
echo "[nemotron-voice-agent] Next:"
echo "  1) Set keys in shell or .env: NVIDIA_API_KEY / NGC_API_KEY"
echo "  2) Run: ./start.sh"

