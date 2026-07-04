#!/usr/bin/env bash
# Launch pi against whatever inference hardware this machine has:
#   - NVIDIA GPU present  -> SGLang + gpt-oss-120b (docker compose, profile "gpu")
#   - otherwise (Mac etc) -> llama.cpp + gpt-oss-20b on the host (scripts/serve-local.sh)
set -euo pipefail

if command -v nvidia-smi >/dev/null 2>&1; then
  SGLANG_PORT="${SGLANG_PORT:-30000}"
  docker compose --profile gpu up -d sglang
  echo "Waiting for SGLang at :${SGLANG_PORT} (first start downloads ~63GB of weights)..."
  until curl -sf "http://localhost:${SGLANG_PORT}/health" >/dev/null 2>&1; do sleep 5; done
  exec pi --provider sglang --model "openai/gpt-oss-120b" "$@"
else
  LLAMA_PORT="${LLAMA_PORT:-8080}"
  if ! curl -sf "http://localhost:${LLAMA_PORT}/health" >/dev/null 2>&1; then
    echo "llama-server is not running. Start it first:" >&2
    echo "  scripts/serve-local.sh" >&2
    exit 1
  fi
  exec pi --provider local-llamacpp --model gpt-oss-20b "$@"
fi
