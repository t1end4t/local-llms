# Pi Coding Agent — Local Qwen3.6 35B Configuration

## 1. Fix Port Mismatch

Your `run-model-llama-cpp.sh` starts llama-server on **port 8080**, but your current `~/.pi/agent/models.json` points to port **8001**. Fix the `baseUrl`.

## 2. Update `~/.pi/agent/models.json`

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
          "name": "Qwen3.6 35B A3B (llama.cpp local)",
          "reasoning": true,
          "input": ["text"],
          "contextWindow": 65536,
          "maxTokens": 32768,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 },
          "compat": {
            "thinkingFormat": "qwen-chat-template"
          }
        }
      ]
    }
  }
}
```

### Key changes explained

| Field | Value | Why |
|-------|-------|-----|
| `baseUrl` | `http://localhost:8080/v1` | Matches your `run-model-llama-cpp.sh` `--port 8080` |
| `contextWindow` | `65536` | Matches your `-c 65536` llama-server flag |
| `maxTokens` | `32768` | Matches your `-n 32768` llama-server flag |
| `thinkingFormat` | `qwen-chat-template` | Tells Pi to send `chat_template_kwargs.enable_thinking`, which your llama-server reads via `--chat-template-kwargs '{"preserve_thinking": true}'` |
| `supportsDeveloperRole` | `false` | llama.cpp does not understand the `developer` role; Pi falls back to `system` |
| `supportsReasoningEffort` | `false` | llama.cpp does not support OpenAI-style `reasoning_effort` |

## 3. Update `~/.pi/agent/settings.json`

Replace the entire file with:

```json
{
  "lastChangelogVersion": "0.70.0",
  "defaultProvider": "llama-cpp",
  "defaultModel": "qwen3.6-35b-a3b",
  "defaultThinkingLevel": "medium"
}
```

## 4. Running

```bash
# Terminal 1 — start llama-server
scripts/run-model-llama-cpp.sh Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf

# Terminal 2 — start Pi (from any project directory)
pi
```

Inside Pi:
- `/model` — verify it sees your local model
- `/provider` — verify provider is `llama-cpp`
- Just start chatting

## 5. Troubleshooting

| Problem | Fix |
|---------|-----|
| Pi says "no such file or directory" for sessions | `mkdir -p ~/.pi/agent/sessions` |
| Pi can't connect to model | Verify llama-server is running on port 8080: `curl http://localhost:8080/v1/models` |
| Thinking blocks not shown | Ensure `reasoning: true` is set in models.json and `thinkingFormat: "qwen-chat-template"` is present |
| Read-only filesystem error | Pi's session dir may be on a read-only mount. Set `sessionDir` in settings.json to a writable path, e.g. `"sessionDir": "~/.local/share/pi-sessions"` |
