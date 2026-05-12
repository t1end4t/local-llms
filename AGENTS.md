# Repository Instructions

This repo manages local AI model inventory, metadata, commands, and lightweight tooling.

## Critical Safety Rules

- Never run model/data downloads: `huggingface-cli download`, `hf download`, `wget`, or similar.
- Never run commands likely to take minutes or hours.
- Use only fast inspection commands such as `ls`, `rg`, `sed`, `head`, or quick metadata checks.
- If a download is needed, show the exact command for the user to run manually.
- Do not edit files outside this repository unless the user explicitly asks.

## Project Scope

- Include all local AI assets: LLMs, VLMs, diffusion models, diffusion LLMs, embeddings, rerankers, and related tools.
- Do not assume this repo is only for text-generation LLMs.
- Treat this repo as the source of truth for model inventory and local usage commands.
- There is no external thinking-space or second-brain dependency for this repo.

## Local Model Path

- Default model root: `$HOME/LOCAL-AI-MODELS`.
- Do not assume models live under `$HOME/codebases`.
- Prefer configurable paths via `MODELS_DIR`; keep `$HOME/LOCAL-AI-MODELS` as the fallback default.

## Model Metadata Standards

When adding or updating model entries, keep available metadata accurate:

- Model name
- Model type or task
- Format and quantization
- File size
- Source URL or Hugging Face repo
- Local path
- Intended use
- Required runtime or command

## Workflow

- Inspect before editing.
- Make surgical changes only.
- Match existing style.
- Avoid speculative features or abstractions.
- Remove only unused code introduced by your own changes.
- If something is unclear, state the assumption or ask before changing files.

## Completion Summary

After completing work, summarize:

- Changed files
- Important assumptions
- Verification performed
- Manual commands the user should run, especially downloads
