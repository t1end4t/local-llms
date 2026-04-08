#!/usr/bin/env bash
# run-ollama-claude.sh — import a local GGUF into Ollama and launch Claude Code
# Usage:
#   ./scripts/run-ollama-claude.sh                   # uses first active model in models.conf
#   ./scripts/run-ollama-claude.sh <model-filename>  # e.g. Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf
set -euo pipefail

# shellcheck source=_ollama-lib.sh
source "$(dirname "$0")/_ollama-lib.sh"

ollama_resolve_model "${1:-}"
ollama_ensure_running
ollama_import

echo ""
echo "Launching: claude --model $OLLAMA_MODEL"
echo ""

export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_API_KEY=ollama
export ANTHROPIC_BASE_URL=http://localhost:11434

exec claude --model "$OLLAMA_MODEL" "${@:2}"
