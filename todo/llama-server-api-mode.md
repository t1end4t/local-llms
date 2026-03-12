# llama-server API Mode Guide

## Overview

`llama-server` runs llama.cpp as an HTTP API server with:
- **OpenAI-compatible API** - Drop-in replacement for OpenAI endpoints
- **Web UI** - Built-in chat interface
- **Multi-model support** - Load and switch between models
- **GPU acceleration** - Full CUDA/Metal support

---

## Quick Start

### Basic Server (Your Setup)

```bash
llama-server -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf -ngl 99 -c 4096 --port 8080
```

### Server with All Features

```bash
llama-server \
  -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf \
  -ngl 99 \
  -c 8192 \
  --port 8080 \
  --host 0.0.0.0 \
  -fa \
  --slots \
  --log-file server.log
```

---

## Server Options

### Model Loading

| Flag | Description | Default |
|------|-------------|---------|
| `-m, --model FILE` | Path to GGUF model file | Required |
| `--model-alias ALIAS:FILE` | Load model with custom name | - |
| `--lora FILE` | LoRA adapter path | - |
| `--lora-scaled FILE:SCALE` | LoRA with scaling factor | - |
| `--mmproj FILE` | Multimodal projector (vision) | - |

### GPU Acceleration

| Flag | Description | Default |
|------|-------------|---------|
| `-ngl, --n-gpu-layers N` | Layers to offload to GPU | 0 |
| `--gpu-layers all` | Offload all layers | - |
| `--split-mode {none,layer,row}` | Multi-GPU strategy | layer |
| `-ts, --tensor-split N0,N1` | GPU VRAM split ratio | auto |
| `--main-gpu INDEX` | Primary GPU index | 0 |

### Context & Memory

| Flag | Description | Default |
|------|-------------|---------|
| `-c, --ctx-size N` | Context window size | Model default |
| `-b, --batch-size N` | Logical batch size | 2048 |
| `-ub, --ubatch-size N` | Physical batch size | 512 |
| `--flash-attn` | Enable Flash Attention | auto |
| `--mlock` | Lock model in RAM | - |
| `--mmap` | Memory-map model | enabled |

### Server Configuration

| Flag | Description | Default |
|------|-------------|---------|
| `--port N` | HTTP server port | 8080 |
| `--host ADDRESS` | Bind address | 127.0.0.1 |
| `--api-keys KEY1,KEY2` | API authentication keys | none |
| `--ssl-key-file FILE` | SSL private key | - |
| `--ssl-cert-file FILE` | SSL certificate | - |
| `--slots` | Enable slot-based parallelism | - |
| `--log-file FILE` | Log to file | - |

### Generation Parameters

| Flag | Description | Default |
|------|-------------|---------|
| `--temp N` | Temperature | 0.8 |
| `--top-p N` | Top-p sampling | 0.95 |
| `--top-k N` | Top-k sampling | 40 |
| `--repeat-penalty N` | Repetition penalty | 1.0 |
| `--presence-penalty N` | Presence penalty | 0.0 |
| `--frequency-penalty N` | Frequency penalty | 0.0 |
| `--system-prompt PROMPT` | Default system prompt | - |

---

## API Endpoints

### OpenAI-Compatible Endpoints

#### POST /v1/chat/completions

Chat completion endpoint (most commonly used):

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Hello!"}
    ],
    "temperature": 0.7,
    "max_tokens": 512
  }'
```

**Response:**
```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "qwen3.5",
  "choices": [{
    "index": 0,
    "message": {
      "role": "assistant",
      "content": "Hello! How can I help you?"
    },
    "finish_reason": "stop"
  }],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 10,
    "total_tokens": 35
  }
}
```

#### POST /v1/completions

Legacy text completion endpoint:

```bash
curl http://localhost:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5",
    "prompt": "Once upon a time",
    "max_tokens": 100
  }'
```

#### GET /v1/models

List available models:

```bash
curl http://localhost:8080/v1/models
```

**Response:**
```json
{
  "object": "list",
  "data": [
    {
      "id": "qwen3.5",
      "object": "model",
      "created": 1234567890,
      "owned_by": "llama.cpp"
    }
  ]
}
```

#### POST /v1/embeddings

Generate embeddings (if model supports it):

```bash
curl http://localhost:8080/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3.5",
    "input": "Hello world"
  }'
```

### Server-Specific Endpoints

#### GET /health

Health check endpoint:

```bash
curl http://localhost:8080/health
```

**Response:**
```json
{"status": "ok"}
```

#### GET /metrics

Prometheus-style metrics:

```bash
curl http://localhost:8080/metrics
```

#### GET /

Web UI (browser interface):

Open `http://localhost:8080` in your browser for a chat interface.

---

## Usage Examples

### Example 1: Basic Chat Server

```bash
llama-server -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf -ngl 99 -c 4096 --port 8080
```

### Example 2: Multi-User Server (Slot-Based)

```bash
llama-server \
  -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf \
  -ngl 99 \
  -c 4096 \
  --port 8080 \
  --slots \
  --parallel 4
```

Allows 4 concurrent users with separate context slots.

### Example 3: API with Authentication

```bash
llama-server \
  -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf \
  -ngl 99 \
  -c 4096 \
  --port 8080 \
  --api-keys sk-my-secret-key
```

Clients must include: `Authorization: Bearer sk-my-secret-key`

### Example 4: LAN Access

```bash
llama-server \
  -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf \
  -ngl 99 \
  -c 4096 \
  --port 8080 \
  --host 0.0.0.0
```

Accessible from other devices: `http://YOUR_IP:8080`

### Example 5: Multiple Models

```bash
llama-server \
  --model-alias qwen:models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf \
  --model-alias llama:models/Llama-3.2-3B-Q4_K_M.gguf \
  -ngl 99 \
  -c 4096 \
  --port 8080
```

Switch models via API: `"model": "qwen"` or `"model": "llama"`

### Example 6: Production Server

```bash
llama-server \
  -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf \
  -ngl 99 \
  -c 8192 \
  --port 8080 \
  --host 0.0.0.0 \
  --api-keys sk-prod-key-123 \
  --slots \
  --parallel 8 \
  --flash-attn \
  --log-file /var/log/llama-server.log
```

---

## Python Client Example

### Using OpenAI SDK (Compatible)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed"  # Not required unless --api-keys is set
)

response = client.chat.completions.create(
    model="qwen3.5",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Explain quantum computing."}
    ],
    temperature=0.7,
    max_tokens=512
)

print(response.choices[0].message.content)
```

### Using requests Library

```python
import requests

response = requests.post(
    "http://localhost:8080/v1/chat/completions",
    json={
        "model": "qwen3.5",
        "messages": [
            {"role": "user", "content": "Hello!"}
        ],
        "temperature": 0.7
    }
)

print(response.json()["choices"][0]["message"]["content"])
```

### Streaming Response

```python
import requests
import json

response = requests.post(
    "http://localhost:8080/v1/chat/completions",
    json={
        "model": "qwen3.5",
        "messages": [{"role": "user", "content": "Tell me a story"}],
        "stream": True
    },
    stream=True
)

for line in response.iter_lines():
    if line:
        data = line.decode('utf-8')[6:]  # Remove "data: " prefix
        if data != "[DONE]":
            chunk = json.loads(data)
            content = chunk["choices"][0]["delta"].get("content", "")
            print(content, end="", flush=True)
```

---

## JavaScript/Node.js Example

```javascript
const response = await fetch("http://localhost:8080/v1/chat/completions", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    model: "qwen3.5",
    messages: [{ role: "user", content: "Hello!" }],
    temperature: 0.7
  })
});

const data = await response.json();
console.log(data.choices[0].message.content);
```

---

## Performance Tuning

### For Your RTX 3060 (12GB)

| Model Size | GPU Layers | Context | Parallel Slots |
|------------|------------|---------|----------------|
| 0.5-3B     | 99         | 8192    | 8-16           |
| 7-8B       | 99         | 4096    | 4-8            |
| 14B        | 99         | 4096    | 2-4            |
| 32B+       | 35-50      | 2048    | 1-2            |

### Optimization Tips

1. **Enable Flash Attention**: `-fa` (faster, less memory)
2. **Use Slots for Multi-User**: `--slots --parallel N`
3. **Increase Batch Size**: `-b 4096` (if VRAM allows)
4. **Set Threads**: `-t 8` (match your CPU cores)

---

## Common Issues

### "CUDA out of memory"

**Solution**: Reduce context size or GPU layers:
```bash
llama-server -m model.gguf -ngl 50 -c 2048
```

### "Connection refused"

**Solution**: Check server is running and port is correct:
```bash
curl http://localhost:8080/health
```

### Slow Response Times

**Solution**: Ensure GPU offload is enabled:
```bash
# Check in server logs for "offloaded X/Y layers to GPU"
```

### API Key Authentication Failing

**Solution**: Include Bearer token:
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer sk-your-key" \
  -H "Content-Type: application/json" \
  -d '{...}'
```

---

## Best Practices

1. **Use `-ngl 99`** for full GPU offload (when VRAM allows)
2. **Set appropriate context** - Don't waste VRAM on unused context
3. **Enable Flash Attention** - `-fa` for better performance
4. **Use API keys** - `--api-keys` for production
5. **Log to file** - `--log-file` for debugging
6. **Monitor VRAM** - Use `nvidia-smi` to track usage
7. **Use slots for concurrency** - `--slots --parallel N`

---

## Quick Reference

```bash
# Start server (your model)
llama-server -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf -ngl 99 -c 4096 --port 8080

# Test with curl
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello!"}]}'

# Web UI
# Open: http://localhost:8080

# Python (OpenAI SDK)
# from openai import OpenAI
# client = OpenAI(base_url="http://localhost:8080/v1")
```

---

## Resources

- [llama.cpp Server Documentation](https://github.com/ggerganov/llama.cpp/tree/master/tools/server)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [llama.cpp Examples](https://github.com/ggerganov/llama.cpp/blob/master/examples/)
