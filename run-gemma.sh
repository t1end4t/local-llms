#!/usr/bin/env bash

MODEL="models/gemma-3-12b-it-Q4_K_M.gguf"
HOST="127.0.0.1"
PORT="8080"
CTX=8192
GPU_LAYERS=33  # ~10GB VRAM on RTX 3060 12GB

llama-server \
  --model "$MODEL" \
  --host "$HOST" \
  --port "$PORT" \
  --ctx-size "$CTX" \
  --gpu-layers "$GPU_LAYERS" \
  --flash-attn on
