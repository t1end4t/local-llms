#!/usr/bin/env bash
# scripts/start-proxy.sh — launch llama-server for Claude Code
#
# Usage:
#   scripts/start-proxy.sh                  # auto-detect model from models.conf
#   scripts/start-proxy.sh <model.gguf>     # explicit model file
#
# Then in another terminal:
#   source proxy/activate.sh
#   claude --model local

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODELS_DIR="$REPO_ROOT/models"

# ── Resolve model ─────────────────────────────────────────────────────────────

MODEL_FILE="${1:-}"

if [[ -z "$MODEL_FILE" ]]; then
  MODEL_FILE="$(
    grep -v '^\s*#' "$REPO_ROOT/models.conf" | grep -v '^\s*$' \
    | head -1 | awk -F'::' '{print $2}'
  )"
  [[ -z "$MODEL_FILE" ]] && { echo "Error: no active model in models.conf" >&2; exit 1; }
fi

MODEL_PATH="$MODELS_DIR/$MODEL_FILE"
[[ -f "$MODEL_PATH" ]] || { echo "Error: not found: $MODEL_PATH" >&2; exit 1; }

command -v llama-server &>/dev/null || { echo "Error: llama-server not found" >&2; exit 1; }

# ── Extra flags ───────────────────────────────────────────────────────────────

EXTRA_FLAGS=()

if [[ "$MODEL_FILE" =~ (A3B|MoE|moe) ]]; then
  echo "Detected MoE model — enabling --no-mmap + --n-cpu-moe"
  EXTRA_FLAGS+=(--no-mmap --n-cpu-moe 1)
fi

MMPROJ_PATH="$MODELS_DIR/mmproj-BF16.gguf"
if [[ -f "$MMPROJ_PATH" ]]; then
  echo "Vision projector found — enabling multimodal"
  EXTRA_FLAGS+=(--mmproj "$MMPROJ_PATH")
fi

# ── Launch ────────────────────────────────────────────────────────────────────

echo "Starting llama-server: $MODEL_FILE"
echo "Endpoint: http://127.0.0.1:8080"
echo ""
echo "  To use with Claude Code (in another terminal):"
echo "    source proxy/activate.sh"
echo "    claude --model local"
echo ""

exec llama-server \
  -m "$MODEL_PATH" \
  --fit on \
  "${EXTRA_FLAGS[@]}" \
  -c 65536 \
  -fa on \
  -ctk q8_0 \
  -ctv q8_0 \
  --parallel 2 \
  --host 127.0.0.1 \
  --port 8080 \
