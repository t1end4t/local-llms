#!/usr/bin/env bash
set -euo pipefail

MODELS_DIR="${MODELS_DIR:-$HOME/codebases/LOCAL-AI-MODELS}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <model.gguf> [extra llama-server args...]" >&2
  exit 1
fi

MODEL_FILE="$1"
shift
MODEL_PATH="$MODELS_DIR/$MODEL_FILE"

if [[ ! -f "$MODEL_PATH" ]]; then
  echo "Error: model not found at $MODEL_PATH" >&2
  echo "Run scripts/download-models.sh first." >&2
  exit 1
fi

ALIAS="${MODEL_FILE%.gguf}"

exec llama-server \
  --model "$MODEL_PATH" \
  --port 8080 \
  --alias "$ALIAS" \
  -c 65536 \
  -n 32768 \
  --no-context-shift \
  --temp 0.6 \
  --top-p 0.95 \
  --top-k 20 \
  --repeat-penalty 1.00 \
  --presence-penalty 0.00 \
  -fit on \
  -fa on \
  -ctk q8_0 -ctv q8_0 \
  --chat-template-kwargs '{"preserve_thinking": true}' \
  "$@"
