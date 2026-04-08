# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Scripts and config for running local GGUF models via two backends: **llama.cpp** (`llama-server`) and **Ollama**. Models are stored outside this repo at `~/codebases/LOCAL-AI-MODELS/LLM/` and `~/codebases/LOCAL-AI-MODELS/VLM/`.

## Model management

`models.conf` is the source of truth. Format: `HF_REPO::FILENAME` (comments with `#`, blank lines ignored).

```bash
# Download all listed models (skip if already present)
scripts/download-models.sh

# Also remove files not in models.conf
scripts/download-models.sh --prune
```

Prefers `huggingface-cli`, falls back to `wget` or `curl`.

## Running models

**llama-server** (OpenAI-compatible endpoint at `http://127.0.0.1:8080`):
```bash
scripts/run-model-llama-cpp.sh <model-filename.gguf>
```
Auto-detects MoE models (adds `--no-mmap --n-cpu-moe`) and VLMs (finds and attaches mmproj). Flags: `-c 65536 -fa on -ctk q4_0 -ctv q4_0 --parallel 2`.

**Ollama-backed AI clients** (all resolve model from `models.conf` if no arg given):
```bash
scripts/run-ollama-claude.sh [model.gguf]    # → Claude Code via Ollama
scripts/run-ollama-codex.sh [model.gguf]     # → codex --oss via Ollama
scripts/run-ollama-opencode.sh [model.gguf]  # → opencode via Ollama
```
These auto-import the GGUF into Ollama on first run (sets ctx 65536), then launch the client.

**Smoke test** (GPU layer/VRAM verification):
```bash
scripts/run-smoke-test.sh
```

## Shared Ollama library

`scripts/_ollama-lib.sh` is sourced by all `run-ollama-*.sh` scripts. It provides:
- `ollama_resolve_model [filename]` — sets `$OLLAMA_MODEL`, `$MODEL_FILE`, `$MODEL_PATH`
- `ollama_ensure_running` — starts `ollama serve` in background if not running
- `ollama_import` — imports model into Ollama (no-op if already present)

Ollama model names are derived from GGUF filenames automatically, e.g. `Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf` → `qwen2.5-coder-14b-instruct:q4km`.
