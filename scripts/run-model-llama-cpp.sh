#!/usr/bin/env bash
set -euo pipefail

# Hardware target: RTX 3060 12 GB VRAM + 32 GB RAM
# Strategy: Qwen3.6-35B-A3B as main daily-driver model.
# Balanced for coding-agent workloads: decent context, stable VRAM use,
# and faster response than dense 27B models.

MODELS_DIR="${MODELS_DIR:-$HOME/codebases/LOCAL-AI-MODELS}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <model.gguf> [extra llama-server args...]" >&2
  echo "" >&2
  echo "Available models:" >&2
  ls "$MODELS_DIR"/*.gguf 2>/dev/null | xargs -I{} basename {} >&2
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

LLAMA_VERSION="$(llama-server --version 2>&1 | sed -n 's/^version: \([0-9][0-9]*\).*/\1/p' | head -1)"

if [[ "$MODEL_FILE" == gemma-4-* ]] && [[ -n "$LLAMA_VERSION" ]] && (( LLAMA_VERSION < 8660 )); then
  echo "Error: $MODEL_FILE uses GGUF architecture 'gemma4', but llama-server version $LLAMA_VERSION is too old." >&2
  echo "Upgrade llama.cpp/llama-server to a newer build, then retry this command." >&2
  exit 1
fi

# ── Per-model profiles ──────────────────────────────────────────────
# ngl  = layers offloaded to GPU
# ctx  = context length
# nmax = max generation length

NGL=0
CTX=8192
NMAX=4096
EXTRA_ARGS=()

case "$MODEL_FILE" in
  Qwen3.6-35B-A3B*)
    # RTX 3060 12 GB balanced profile
    # If VRAM OOMs: lower NGL to 14 or CTX to 16384.
    # If stable and you want more speed: try NGL=18 with CTX=16384.
    NGL=16
    CTX=24576
    NMAX=8192
    EXTRA_ARGS=(--chat-template-kwargs '{"preserve_thinking": true}')
    ;;

  gemma-4-26B-A4B*)
    NGL=16
    CTX=24576
    NMAX=8192
    ;;

  *)
    echo "Warning: no tuned profile for $MODEL_FILE — using conservative defaults" >&2
    NGL=0
    CTX=8192
    NMAX=4096
    ;;
esac

echo "── Profile ────────────────────────────────────────"
echo "  Model      : $MODEL_FILE"
echo "  GPU layers : $NGL"
echo "  Context    : $CTX tokens"
echo "  Max gen    : $NMAX tokens"
echo "──────────────────────────────────────────────────"

exec llama-server \
  --model "$MODEL_PATH" \
  --port 8080 \
  --alias "$ALIAS" \
  -ngl "$NGL" \
  -c "$CTX" \
  -n "$NMAX" \
  --temp 0.6 \
  --top-p 0.95 \
  --top-k 20 \
  --min-p 0.00 \
  --repeat-penalty 1.00 \
  --presence-penalty 0.00 \
  -fa on \
  -ctk q8_0 -ctv q8_0 \
  "${EXTRA_ARGS[@]}" \
  "$@"
