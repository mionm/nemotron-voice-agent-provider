#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERR] docker is required in this shell." >&2
  echo "      If using WSL/Git Bash, enable Docker Desktop WSL integration first." >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "[ERR] Docker daemon is not reachable from this shell." >&2
  echo "      Open Docker Desktop and enable WSL integration for your distro." >&2
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

if [[ ! -f ".env" ]]; then
  echo "[ERR] .env not found. Run ./setup.sh first." >&2
  exit 1
fi

# Fallback: load keys from .env when shell env is missing (PowerShell -> bash common case).
if [[ -z "${NVIDIA_API_KEY:-}" ]]; then
  env_nvidia_key="$(grep -E '^NVIDIA_API_KEY=' .env | head -n1 | cut -d'=' -f2- || true)"
  if [[ -n "${env_nvidia_key}" ]]; then
    export NVIDIA_API_KEY="${env_nvidia_key}"
  fi
fi
if [[ -z "${NGC_API_KEY:-}" ]]; then
  env_ngc_key="$(grep -E '^NGC_API_KEY=' .env | head -n1 | cut -d'=' -f2- || true)"
  if [[ -n "${env_ngc_key}" ]]; then
    export NGC_API_KEY="${env_ngc_key}"
  fi
fi

if [[ -z "${NVIDIA_API_KEY:-}" && -z "${NGC_API_KEY:-}" ]]; then
  echo "[ERR] Missing NVIDIA_API_KEY/NGC_API_KEY in shell env." >&2
  echo "      Example: export NVIDIA_API_KEY=<your-key>" >&2
  echo "      Or set NVIDIA_API_KEY=... and NGC_API_KEY=... in .env" >&2
  exit 1
fi

if [[ -z "${NVIDIA_API_KEY:-}" && -n "${NGC_API_KEY:-}" ]]; then
  export NVIDIA_API_KEY="${NGC_API_KEY}"
fi
if [[ -z "${NGC_API_KEY:-}" && -n "${NVIDIA_API_KEY:-}" ]]; then
  export NGC_API_KEY="${NVIDIA_API_KEY}"
fi

echo "[nemotron-voice-agent] Logging in to nvcr.io..."
if command -v timeout >/dev/null 2>&1; then
  if ! timeout 45s bash -lc 'echo "$0" | docker login nvcr.io --username '"'"'$oauthtoken'"'"' --password-stdin >/dev/null' "${NGC_API_KEY}"; then
    echo "[ERR] docker login to nvcr.io failed or timed out." >&2
    exit 1
  fi
else
  echo "${NGC_API_KEY}" | docker login nvcr.io --username '$oauthtoken' --password-stdin >/dev/null || {
    echo "[ERR] docker login to nvcr.io failed." >&2
    exit 1
  }
fi

if ! grep -Eq "^ASR_SERVER_URL=grpc.nvcf.nvidia.com:443" .env; then
  echo "[WARN] ASR_SERVER_URL is not cloud default in .env"
fi
if ! grep -Eq "^TTS_SERVER_URL=grpc.nvcf.nvidia.com:443" .env; then
  echo "[WARN] TTS_SERVER_URL is not cloud default in .env"
fi
if ! grep -Eq "^NVIDIA_LLM_URL=https://integrate.api.nvidia.com/v1" .env; then
  echo "[WARN] NVIDIA_LLM_URL is not cloud default in .env"
fi

echo "[nemotron-voice-agent] Starting in API mode (skip local ASR/TTS/LLM containers)..."
"${COMPOSE_CMD[@]}" up -d --build --no-deps python-app ui-app

echo
echo "[nemotron-voice-agent] Started."
echo "[nemotron-voice-agent] UI: http://127.0.0.1:9000"
echo "[nemotron-voice-agent] Logs: ${COMPOSE_CMD[*]} logs -f python-app ui-app"

