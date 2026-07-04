#!/usr/bin/env bash
# Serve gpt-oss-20b locally on Apple Silicon (Metal) via llama.cpp.
# OpenAI-compatible API at http://localhost:${LLAMA_PORT:-8080}/v1
set -euo pipefail

PORT="${LLAMA_PORT:-8080}"
CTX="${LLAMA_CTX:-0}" # 0 = full 131k context (~15GB total for 20b MXFP4)

if ! command -v llama-server >/dev/null 2>&1; then
  echo "llama-server not found — installing llama.cpp via Homebrew..."
  brew install llama.cpp
fi

# --jinja is required for gpt-oss harmony chat template + tool calling.
# Sampling guidance from OpenAI: temperature 1.0, top_p 1.0, no repetition penalties.
exec llama-server \
  -hf ggml-org/gpt-oss-20b-GGUF \
  --ctx-size "$CTX" \
  --jinja \
  -ub 2048 -b 2048 \
  --host 127.0.0.1 \
  --port "$PORT"
