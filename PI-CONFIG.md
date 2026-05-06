# Pi Coding Agent — Local Model Configuration

## Hardware

RTX 3060 12 GB VRAM · 32 GB RAM · Ryzen 5 5500

Strategy: **partial GPU offload** — don't load all layers to VRAM.
Keeps RAM free for KV cache + OS. Better for coding-agent workloads
where you want steady token generation, not batch throughput.

## Available Models

| Model | Type | Size | GPU layers | Context | Max gen | Notes |
|-------|------|------|------------|---------|---------|-------|
| Qwen3.6-35B-A3B Q4_K_M | MoE (3B active) | 21 GB | 18/40 | 40K | 32K | **Best fit** — fast, large context |
| Qwen3.6-27B Q4_K_M | Dense | 16 GB | 36/64 | 16K | 8K | Slower, reduced context needed |
| gemma-4-26B-A4B Q4_K_M | MoE (4B active) | 16 GB | 18/30 | 32K | 16K | Good alternative MoE |

## 1. Update `~/.pi/agent/models.json`

Replace the entire file with:

```json
{
  "providers": {
    "llama-cpp": {
      "baseUrl": "http://localhost:8080/v1",
      "api": "openai-completions",
      "apiKey": "none",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        {
          "id": "qwen3.6-35b-a3b",
          "name": "Qwen3.6 35B A3B (local)",
          "reasoning": true,
          "input": ["text"],
          "contextWindow": 40960,
          "maxTokens": 32768,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
          "compat": {
            "thinkingFormat": "qwen-chat-template"
          }
        },
        {
          "id": "qwen3.6-27b",
          "name": "Qwen3.6 27B (local)",
          "reasoning": true,
          "input": ["text"],
          "contextWindow": 16384,
          "maxTokens": 8192,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
          "compat": {
            "thinkingFormat": "qwen-chat-template"
          }
        },
        {
          "id": "gemma-4-26b-a4b",
          "name": "Gemma 4 26B A4B (local)",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 32768,
          "maxTokens": 16384,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      ]
    }
  }
}
```

## 2. Update `~/.pi/agent/settings.json`

```json
{
  "lastChangelogVersion": "0.70.0",
  "defaultProvider": "llama-cpp",
  "defaultModel": "qwen3.6-35b-a3b",
  "defaultThinkingLevel": "medium"
}
```

## 3. Running

```bash
# Terminal 1 — start llama-server (pick one)
scripts/run-model-llama-cpp.sh Qwen3.6-35B-A3B-UD-Q4_K_M.gguf   # recommended
scripts/run-model-llama-cpp.sh Qwen3.6-27B-Q4_K_M.gguf
scripts/run-model-llama-cpp.sh gemma-4-26B-A4B-it-UD-Q4_K_M.gguf

# Terminal 2 — start Pi (from any project directory)
pi
```

Inside Pi: use `/model` to switch between models (restart llama-server with the matching .gguf first).

## 4. Troubleshooting

| Problem | Fix |
|---------|-----|
| Pi can't connect | Verify llama-server is running: `curl http://localhost:8080/v1/models` |
| `unknown model architecture: 'gemma4'` | Upgrade `llama.cpp` / `llama-server`; old builds cannot load Gemma 4 GGUF files |
| OOM / crash | Lower `-ngl` by 2-4 layers, or reduce context with `-c <value>` via extra args |
| Thinking blocks not shown | Ensure `reasoning: true` + `thinkingFormat` in models.json |
| Slow generation | MoE models (A3B/A4B) are much faster — prefer those over dense 27B |
| Session dir error | `mkdir -p ~/.pi/agent/sessions` |
