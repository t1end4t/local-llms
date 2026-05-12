#!/usr/bin/env bash
set -euo pipefail

# Hardware target: RTX 3060 12 GB VRAM + 32 GB RAM
# Strategy: Qwen3.6-35B-A3B as main daily-driver model.
# Balanced for coding-agent workloads: decent context, stable VRAM use,
# and faster response than dense 27B models.

MODELS_DIR="${MODELS_DIR:-$HOME/LOCAL-AI-MODELS}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <alias|model.gguf> [extra llama-server args...]" >&2
  echo "Aliases: coding, vision" >&2
  echo "" >&2
  echo "Available models:" >&2
  ls "$MODELS_DIR"/*.gguf 2>/dev/null | xargs -I{} basename {} >&2
  exit 1
fi

declare -A ALIAS_MAP=(
  [coding]=Qwen3.6-35B-A3B-UD-Q4_K_M.gguf
  [vision]=Qwen3-VL-30B-A3B-Thinking-UD-Q4_K_XL.gguf
)

if [[ -n "${ALIAS_MAP[$1]:-}" ]]; then
  MODEL_FILE="${ALIAS_MAP[$1]}"
  shift
else
  MODEL_FILE="$1"
  shift
fi

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
CTX=32768
NMAX=8192
EXTRA_ARGS=()

case "$MODEL_FILE" in
  Qwen3.6-35B-A3B*)
    # RTX 3060 12 GB balanced profile (48k context for long prompts)
    # If VRAM OOMs: lower NGL to 14 or CTX to 32768.
    # If stable and you want more speed: try NGL=18 with CTX=32768.
    NGL=16
    CTX=49152
    NMAX=8192
    MMPROJ_PATH="$MODELS_DIR/mmproj-Qwen3.6-35B-A3B-F16.gguf"
    if [[ ! -f "$MMPROJ_PATH" ]]; then
      echo "Error: vision projector not found at $MMPROJ_PATH" >&2
      echo "Download it with: hf download unsloth/Qwen3.6-35B-A3B-GGUF mmproj-F16.gguf --local-dir \"$MODELS_DIR\" && mv \"$MODELS_DIR/mmproj-F16.gguf\" \"$MMPROJ_PATH\"" >&2
      exit 1
    fi
    EXTRA_ARGS=(--mmproj "$MMPROJ_PATH" --chat-template-kwargs '{"preserve_thinking": true}')
    ;;

  # Qwen3.6-27B*)
  #   # Dense 27B quality profile for RTX 3060 12 GB + 32 GB RAM.
  #   # Q4_K_XL is ~17.6 GB, so keep GPU offload modest and context large.
  #   # If VRAM OOMs: lower NGL to 8 or CTX to 32768.
  #   # If stable and you want more speed: try NGL=14.
  #   NGL=10
  #   CTX=49152
  #   NMAX=8192
  #   EXTRA_ARGS=(--chat-template-kwargs '{"preserve_thinking": true}')
  #   ;;

  gemma-4-26B-A4B*)
    NGL=16
    CTX=49152
    NMAX=8192
    ;;

  Qwen3-VL-30B-A3B-Thinking*)
    NGL=16
    CTX=32768
    NMAX=8192
    MMPROJ_PATH="$MODELS_DIR/mmproj-Qwen3-VL-30B-A3B-Thinking-F16.gguf"
    if [[ ! -f "$MMPROJ_PATH" ]]; then
      echo "Error: vision projector not found at $MMPROJ_PATH" >&2
      echo "Download it with: hf download unsloth/Qwen3-VL-30B-A3B-Thinking-GGUF mmproj-F16.gguf --local-dir \"$MODELS_DIR\" && mv \"$MODELS_DIR/mmproj-F16.gguf\" \"$MMPROJ_PATH\"" >&2
      exit 1
    fi
    EXTRA_ARGS=(--mmproj "$MMPROJ_PATH")
    ;;

  *)
    echo "Warning: no tuned profile for $MODEL_FILE — using conservative defaults" >&2
    NGL=0
    CTX=32768
    NMAX=8192
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
