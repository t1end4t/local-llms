#!/usr/bin/env bash

llama-cli \
  --model models/Qwen3.5-0.8B-Q5_K_M.gguf \
  --gpu-layers 128 \
  -v \
  -p "Hello" 2>&1 | grep -iE "layer|gpu|vram|n_gpu"
