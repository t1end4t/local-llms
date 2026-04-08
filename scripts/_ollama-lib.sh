#!/usr/bin/env bash
# _ollama-lib.sh — shared helpers for Ollama-based launch scripts
# Source this file; do not execute directly.
#
#   source "$(dirname "$0")/_ollama-lib.sh"
#   ollama_resolve_model [filename]   → sets OLLAMA_MODEL, MODEL_FILE, MODEL_PATH
#   ollama_ensure_running
#   ollama_import                     → imports MODEL_PATH as OLLAMA_MODEL (skips if present)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_BASE="$HOME/codebases/LOCAL-AI-MODELS"
LLM_DIR="$MODELS_BASE/LLM"
MODELS_CONF="$REPO_ROOT/models.conf"

# Derives a clean Ollama model name from a GGUF filename.
# e.g. Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf → qwen2.5-coder-14b-instruct:q4km
_ollama_model_name() {
  local file="${1%.gguf}"
  local quant name
  quant=$(echo "$file" | grep -oE 'Q[0-9][^-]*$' | tr '[:upper:]' '[:lower:]' | tr -d '_' || true)
  name=$(echo "$file" | sed -E 's/-?Q[0-9][^-]*$//' | tr '[:upper:]' '[:lower:]')
  if [[ -n "$quant" ]]; then
    echo "${name}:${quant}"
  else
    echo "${name}:local"
  fi
}

# Sets MODEL_FILE, MODEL_PATH, OLLAMA_MODEL.
# Uses $1 if provided, else first active entry in models.conf.
ollama_resolve_model() {
  if [[ -n "${1:-}" ]]; then
    MODEL_FILE="$1"
  else
    MODEL_FILE=$(grep -v '^\s*#' "$MODELS_CONF" | grep -v '^\s*$' | head -1 | awk -F'::' '{print $2}')
  fi

  if [[ -z "$MODEL_FILE" ]]; then
    echo "Error: no model found in models.conf" >&2; exit 1
  fi

  MODEL_PATH="$LLM_DIR/$MODEL_FILE"
  if [[ ! -f "$MODEL_PATH" ]]; then
    echo "Error: model not found at $MODEL_PATH" >&2
    echo "Run scripts/download-models.sh first." >&2
    exit 1
  fi

  OLLAMA_MODEL="$(_ollama_model_name "$MODEL_FILE")"

  echo "Model file  : $MODEL_FILE"
  echo "Ollama name : $OLLAMA_MODEL"
  echo ""
}

# Starts ollama serve in the background if not already running.
ollama_ensure_running() {
  if ! pgrep -x ollama &>/dev/null; then
    echo "Starting Ollama in background..."
    ollama serve &>/tmp/ollama.log &
    sleep 2
  fi
}

# Imports MODEL_PATH into Ollama as OLLAMA_MODEL (no-op if already present).
ollama_import() {
  if ollama show "$OLLAMA_MODEL" &>/dev/null 2>&1; then
    echo "Model already in Ollama, skipping import."
  else
    echo "Importing model into Ollama (this runs once)..."
    local modelfile
    modelfile=$(mktemp)
    trap "rm -f $modelfile" RETURN
    cat > "$modelfile" <<EOF
FROM $MODEL_PATH
PARAMETER num_ctx 65536
EOF
    ollama create "$OLLAMA_MODEL" -f "$modelfile"
    echo "Import done."
  fi
}
