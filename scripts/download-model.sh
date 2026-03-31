#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODELS_DIR="$REPO_ROOT/models"
mkdir -p "$MODELS_DIR"

# GLM-4.7-Flash UD-Q4_K_XL from Unsloth
# 30B MoE (~3.6B active params) — official recommended quant per unsloth docs
REPO="unsloth/GLM-4.7-Flash-GGUF"
FILE="GLM-4.7-Flash-UD-Q4_K_XL.gguf"
DEST="$MODELS_DIR/$FILE"

HF_URL="https://huggingface.co/$REPO/resolve/main/$FILE"

if [[ -f "$DEST" ]]; then
  echo "Already exists: $DEST"
  exit 0
fi

echo "Downloading $FILE -> $DEST"

if command -v huggingface-cli &>/dev/null; then
  huggingface-cli download "$REPO" "$FILE" --local-dir "$MODELS_DIR"
elif command -v wget &>/dev/null; then
  wget --continue --show-progress -O "$DEST" "$HF_URL"
elif command -v curl &>/dev/null; then
  curl -L --continue-at - --progress-bar -o "$DEST" "$HF_URL"
else
  echo "Error: need huggingface-cli, wget, or curl" >&2
  exit 1
fi

echo "Done: $DEST"
