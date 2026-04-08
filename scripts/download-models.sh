#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODELS_DIR="${MODELS_DIR:-$HOME/codebases/LOCAL-AI-MODELS/LLM}"
MODELS_CONF="$REPO_ROOT/models.conf"

# === Load model list from models.conf ===
if [[ ! -f "$MODELS_CONF" ]]; then
  echo "Error: models.conf not found at $MODELS_CONF" >&2
  exit 1
fi

MODELS=()
while IFS= read -r line; do
  # strip leading/trailing whitespace
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  # skip comments and empty lines
  [[ -z "$line" || "$line" == \#* ]] && continue
  MODELS+=("$line")
done < "$MODELS_CONF"

# === Args ===
PRUNE=false
for arg in "$@"; do
  case "$arg" in
    --prune) PRUNE=true ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

# === Ensure models directory ===
if [[ ! -d "$MODELS_DIR" ]]; then
  echo "Creating models directory: $MODELS_DIR"
  mkdir -p "$MODELS_DIR"
fi

# === Build expected file set ===
declare -A EXPECTED
for entry in "${MODELS[@]}"; do
  file="${entry##*::}"
  EXPECTED["$file"]=1
done

# === Check for orphaned models ===
shopt -s nullglob
orphans=()
for f in "$MODELS_DIR"/*.gguf; do
  fname="$(basename "$f")"
  if [[ -z "${EXPECTED[$fname]:-}" ]]; then
    orphans+=("$f")
  fi
done
shopt -u nullglob

if [[ ${#orphans[@]} -gt 0 ]]; then
  echo "=== Orphaned models (not in list) ==="
  for f in "${orphans[@]}"; do
    echo "  $(basename "$f")"
  done
  if $PRUNE; then
    echo "Pruning orphaned models..."
    for f in "${orphans[@]}"; do
      echo "  [remove] $(basename "$f")"
      rm -f "$f"
    done
  else
    echo "  Run with --prune to delete them."
  fi
fi

# === Download function ===
_download() {
  local repo="$1" file="$2"
  local dest="$MODELS_DIR/$file"
  local hf_url="https://huggingface.co/$repo/resolve/main/$file"

  if [[ -f "$dest" ]]; then
    echo "  [skip] $file (already exists)"
    return 0
  fi

  echo "  [download] $file"
  if command -v huggingface-cli &>/dev/null; then
    huggingface-cli download "$repo" "$file" --local-dir "$MODELS_DIR"
  elif command -v wget &>/dev/null; then
    wget --continue --show-progress -O "$dest" "$hf_url"
  elif command -v curl &>/dev/null; then
    curl -L --continue-at - --progress-bar -o "$dest" "$hf_url"
  else
    echo "Error: need huggingface-cli, wget, or curl" >&2
    exit 1
  fi
  echo "  [done] $dest"
}

# === Download all listed models ===
echo "=== Syncing models ==="
for entry in "${MODELS[@]}"; do
  repo="${entry%%::*}"
  file="${entry##*::}"
  _download "$repo" "$file"
done

echo "=== Done ==="
