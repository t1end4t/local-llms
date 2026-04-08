#!/usr/bin/env bash
# run-ollama-codex.sh — import a local GGUF into Ollama and launch Codex
# Usage:
#   ./scripts/run-ollama-codex.sh                   # uses first active model in models.conf
#   ./scripts/run-ollama-codex.sh <model-filename>  # e.g. Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf
set -euo pipefail

# shellcheck source=_ollama-lib.sh
source "$(dirname "$0")/_ollama-lib.sh"

ollama_resolve_model "${1:-}"
ollama_ensure_running
ollama_import

echo ""
echo "Launching: codex --oss -m $OLLAMA_MODEL"
echo ""

exec codex --oss -m "$OLLAMA_MODEL" "${@:2}"
