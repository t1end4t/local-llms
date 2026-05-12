#!/usr/bin/env bash
set -euo pipefail

MODELS_DIR="${MODELS_DIR:-$HOME/LOCAL-AI-MODELS}"
CONF="$(dirname "$0")/../models.conf"

if [[ ! -f "$CONF" ]]; then
  echo "Error: models.conf not found at $CONF" >&2
  exit 1
fi

mkdir -p "$MODELS_DIR"

while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue

  repo="${line%%::*}"
  remainder="${line#*::}"
  if [[ "$remainder" == *"::"* ]]; then
    hf_file="${remainder%%::*}"
    local_name="${remainder##*::}"
  else
    hf_file="$remainder"
    local_name="$remainder"
  fi

  echo "Downloading $hf_file from $repo ..."
  hf download "$repo" "$hf_file" --local-dir "$MODELS_DIR"
  if [[ "$hf_file" != "$local_name" ]]; then
    mv "$MODELS_DIR/$hf_file" "$MODELS_DIR/$local_name"
  fi
  echo "Done: $local_name"
done < "$CONF"

echo "All models downloaded to $MODELS_DIR"
