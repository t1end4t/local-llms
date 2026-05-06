#!/usr/bin/env bash
set -euo pipefail

# Hardware target: RTX 3060 12 GB VRAM + 32 GB RAM
# Strategy: partial GPU offload — keep some layers on CPU so the OS
# and KV cache still fit in RAM.  Good for coding-agent workloads
# where latency-per-token matters more than batch throughput.
#
# VRAM budget: ~10.5 GB usable (desktop/display takes ~1-1.5 GB)

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
# ngl  = layers offloaded to GPU (not all → partial offload)
# ctx  = context length (tokens)
# nmax = max generation length
#
# VRAM sizing (~10.5 GB usable after desktop/display):
#   Qwen3.6-35B-A3B  — 40 layers, ~21 GB weights, MoE (3B active)
#     ~525 MB/layer → 18 layers ≈ 9.5 GB, safe with KV overhead
#   Qwen3.6-27B      — 64 layers, ~16 GB weights, dense
#     ~250 MB/layer → 36 layers ≈ 9 GB, safe with KV overhead
#   gemma-4-26B-A4B  — 30 layers, ~16 GB weights, MoE (4B active)
#     ~533 MB/layer → 18 layers ≈ 9.6 GB, safe with KV overhead

NGL=0
CTX=32768
NMAX=16384
EXTRA_ARGS=()

case "$MODEL_FILE" in
  Qwen3.6-35B-A3B*)
    NGL=18
    CTX=40960
    NMAX=32768
    EXTRA_ARGS=(--chat-template-kwargs '{"preserve_thinking": true}')
    ;;
  Qwen3.6-27B*)
    NGL=36
    CTX=16384
    NMAX=8192
    EXTRA_ARGS=(--chat-template-kwargs '{"preserve_thinking": true}')
    ;;
  gemma-4-26B-A4B*)
    NGL=18
    CTX=32768
    NMAX=16384
    ;;
  *)
    echo "Warning: no tuned profile for $MODEL_FILE — using conservative defaults" >&2
    NGL=0
    CTX=8192
    NMAX=4096
    ;;
esac

echo "── Profile ────────────────────────────────────────"
echo "  Model : $MODEL_FILE"
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
  --no-context-shift \
  --temp 0.6 \
  --top-p 0.95 \
  --top-k 20 \
  --repeat-penalty 1.00 \
  --presence-penalty 0.00 \
  -fa on \
  -ctk q8_0 -ctv q8_0 \
  "${EXTRA_ARGS[@]}" \
  "$@"
