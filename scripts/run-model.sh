#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODELS_DIR="$REPO_ROOT/models"

# === Usage ===
usage() {
  echo "Usage: $0 <model-filename>" >&2
  echo "  e.g. $0 GLM-4.7-Flash-UD-Q4_K_XL.gguf" >&2
  echo "" >&2
  echo "Available models:" >&2
  for f in "$MODELS_DIR"/*.gguf; do
    echo "  $(basename "$f")" >&2
  done
  exit 1
}

[[ $# -lt 1 ]] && usage

MODEL_FILE="$1"
MODEL_PATH="$MODELS_DIR/$MODEL_FILE"

if [[ ! -f "$MODEL_PATH" ]]; then
  echo "Error: model not found: $MODEL_PATH" >&2
  echo "Run scripts/download-model.sh first." >&2
  exit 1
fi

# === Detect MoE model (A3B, MoE in filename) ===
# MoE models benefit from --no-mmap (avoids page faults on expert weights)
# and --n-cpu-moe when too large to fully fit in VRAM (keeps attention on GPU,
# routes experts through CPU RAM instead).
EXTRA_FLAGS=()
if [[ "$MODEL_FILE" =~ (A3B|MoE|moe) ]]; then
  echo "Detected MoE model — enabling --no-mmap + --n-cpu-moe fallback"
  EXTRA_FLAGS+=(--no-mmap)
  # Route MoE experts to CPU if they don't fit in VRAM.
  # Attention layers stay on GPU for speed.
  EXTRA_FLAGS+=(--n-cpu-moe 1)
fi

echo "Starting llama-server with: $MODEL_FILE"
echo "Endpoint: http://127.0.0.1:8080"
echo "(layers auto-fit to available VRAM; overflow spills to RAM)"

# --fit on: auto-offload as many layers as VRAM allows; remainder runs on CPU RAM.
exec llama-server \
  -m "$MODEL_PATH" \
  --fit on \
  "${EXTRA_FLAGS[@]}" \
  -c 32768 \
  -fa on \
  -ctk q8_0 \
  -ctv q8_0 \
  --parallel 2 \
  --host 127.0.0.1 \
  --port 8080
