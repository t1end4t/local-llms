#!/usr/bin/env bash
# proxy/activate.sh — redirect Claude Code to local llama-server
# Usage: source proxy/activate.sh

export ANTHROPIC_BASE_URL=http://127.0.0.1:8080
export ANTHROPIC_API_KEY="sk-no-key-required"

echo "[local] Claude Code → llama-server (http://127.0.0.1:8080)"
echo "[local] Deactivate with: source proxy/deactivate.sh"
