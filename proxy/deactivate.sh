#!/usr/bin/env bash
# proxy/deactivate.sh — restore Claude Code to Anthropic API
# Usage: source proxy/deactivate.sh

export ANTHROPIC_BASE_URL=""
export ANTHROPIC_API_KEY=""

echo "[proxy] Claude Code → Anthropic API (restored)"
