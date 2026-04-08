#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODELS_BASE="$HOME/codebases/LOCAL-AI-MODELS"
LLM_DIR="$MODELS_BASE/LLM"
VLM_DIR="$MODELS_BASE/VLM"

# === Usage ===
usage() {
  echo "Usage: $0 <model-filename>" >&2
  echo "  e.g. $0 Qwen2.5-14B-Instruct-Q4_K_M.gguf" >&2
  echo "" >&2
  echo "Available LLM models:" >&2
  for f in "$LLM_DIR"/*.gguf; do
    [[ -f "$f" ]] && echo "  $(basename "$f")" >&2
  done
  echo "" >&2
  echo "Available VLM models:" >&2
  for f in "$VLM_DIR"/*.gguf; do
    [[ -f "$f" ]] && echo "  $(basename "$f")" >&2
  done
  exit 1
}

[[ $# -lt 1 || "$1" == "--help" || "$1" == "-h" ]] && usage

MODEL_FILE="$1"

# === Locate model (search LLM then VLM) ===
MODEL_PATH=""
CATEGORY=""

if [[ -f "$LLM_DIR/$MODEL_FILE" ]]; then
  MODEL_PATH="$LLM_DIR/$MODEL_FILE"
  CATEGORY="llm"
elif [[ -f "$VLM_DIR/$MODEL_FILE" ]]; then
  MODEL_PATH="$VLM_DIR/$MODEL_FILE"
  CATEGORY="vlm"
else
  echo "Error: model not found in LLM/ or VLM/: $MODEL_FILE" >&2
  echo "Run scripts/download-models.sh first." >&2
  exit 1
fi

# === Extra flags ===
EXTRA_FLAGS=()

# MoE models
if [[ "$MODEL_FILE" =~ (A3B|MoE|moe) ]]; then
  echo "Detected MoE model — enabling --no-mmap + --n-cpu-moe fallback"
  EXTRA_FLAGS+=(--no-mmap --n-cpu-moe 1)
fi

# VLM: find and attach mmproj
if [[ "$CATEGORY" == "vlm" ]]; then
  MMPROJ=$(find "$VLM_DIR" -name "mmproj*.gguf" | head -1)
  if [[ -z "$MMPROJ" ]]; then
    echo "Error: no mmproj file found in $VLM_DIR" >&2
    exit 1
  fi
  echo "Detected VLM — attaching mmproj: $(basename "$MMPROJ")"
  EXTRA_FLAGS+=(--mmproj "$MMPROJ")
fi

echo "Category : $CATEGORY"
echo "Model    : $MODEL_FILE"
echo "Endpoint : http://127.0.0.1:8080"

exec llama-server \
  -m "$MODEL_PATH" \
  --fit on \
  "${EXTRA_FLAGS[@]}" \
  -c 65536 \
  -fa on \
  -ctk q4_0 \
  -ctv q4_0 \
  --parallel 2 \
  --host 127.0.0.1 \
  --port 8080
