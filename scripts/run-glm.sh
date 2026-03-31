#!/usr/bin/env bash
# Run GLM-4.7-Flash via llama-server (OpenAI-compatible API)
# Docs: https://unsloth.ai/docs/models/glm-4.7-flash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODEL="$REPO_ROOT/models/GLM-4.7-Flash-UD-Q4_K_XL.gguf"
HOST="127.0.0.1"
PORT="8001"
CTX=16384

if [[ ! -f "$MODEL" ]]; then
  echo "Model not found: $MODEL"
  echo "Run: ./scripts/download-model.sh"
  exit 1
fi

llama-server \
  --model "$MODEL" \
  --alias "unsloth/GLM-4.7-Flash" \
  --host "$HOST" \
  --port "$PORT" \
  --ctx-size "$CTX" \
  --gpu-layers -1 \
  --flash-attn on \
  --no-mmap \
  --seed 3407 \
  --temp 1.0 \
  --top-p 0.95 \
  --min-p 0.01 \
  --repeat-penalty 1.0
