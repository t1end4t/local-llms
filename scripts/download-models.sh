#!/usr/bin/env bash
set -euo pipefail

MODELS_DIR="${MODELS_DIR:-$HOME/codebases/LOCAL-AI-MODELS}"
CONF="$(dirname "$0")/../models.conf"

if [[ ! -f "$CONF" ]]; then
  echo "Error: models.conf not found at $CONF" >&2
  exit 1
fi

mkdir -p "$MODELS_DIR"

while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue

  repo="${line%%::*}"
  file="${line##*::}"

  echo "Downloading $file from $repo ..."
  huggingface-cli download "$repo" "$file" --local-dir "$MODELS_DIR"
  echo "Done: $file"
done < "$CONF"

echo "All models downloaded to $MODELS_DIR"
