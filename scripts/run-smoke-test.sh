#!/usr/bin/env bash
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

llama-cli \
  --model "$REPO_ROOT/models/Qwen3.5-0.8B-Q5_K_M.gguf" \
  --gpu-layers 128 \
  -v \
  -p "Hello" 2>&1 | grep -iE "layer|gpu|vram|n_gpu"
