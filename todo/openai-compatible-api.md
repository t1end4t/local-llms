# Setting Up OpenAI-Compatible API with llama.cpp

This guide shows how to run llama.cpp as an OpenAI-compatible API server, enabling integration with existing tools and applications.

## Overview

llama.cpp includes a built-in server that mimics the OpenAI API format, allowing you to:
- Use local models with OpenAI client libraries
- Integrate with tools like LangChain, LlamaIndex, AutoGen
- Switch between local and cloud models seamlessly

## Starting the Server

### Basic Server Setup

```bash
# Start the server with default settings
./llama-server -m ./models/your-model.gguf
```

Default configuration:
- **Host**: `127.0.0.1` (localhost only)
- **Port**: `8080`
- **Context**: Model default (usually 512-2048)

### Production-Ready Configuration

```bash
./llama-server \
  -m ./models/Llama-3.2-7B-Instruct-Q4_K_M.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  -c 8192 \
  -ngl 99 \
  --threads 8 \
  --batch-size 512 \
  --ubatch-size 64 \
  --temp 0.7 \
  --top-p 0.9 \
  --repeat-penalty 1.1 \
  --ctx-size 8192 \
  --n-predict 2048
```

### GPU Acceleration

```bash
# Full GPU offload (recommended)
./llama-server -m model.gguf -ngl 99

# Partial GPU offload (leave some layers on CPU)
./llama-server -m model.gguf -ngl 50

# Split across multiple GPUs
./llama-server -m model.gguf -ngl 99 --split-mode layer
```

### Environment Variables

```bash
# Set API key (optional, for compatibility)
export LLAMA_API_KEY="your-api-key"

# Or pass as argument
./llama-server -m model.gguf --api-key "your-api-key"
```

## API Endpoints

### Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/chat/completions` | POST | Chat completions (main endpoint) |
| `/v1/completions` | POST | Legacy completions |
| `/v1/models` | GET | List available models |
| `/v1/models/{id}` | GET | Get model info |
| `/health` | GET | Health check |

### Chat Completions Endpoint

**Request:**
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-api-key" \
  -d '{
    "model": "local-model",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "Hello, how are you?"}
    ],
    "temperature": 0.7,
    "max_tokens": 512,
    "stream": false
  }'
```

**Response:**
```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "local-model",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "I'm doing well, thank you for asking!"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 12,
    "total_tokens": 37
  }
}
```

### Streaming Responses

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "local-model",
    "messages": [{"role": "user", "content": "Tell me a story"}],
    "stream": true
  }'
```

Streaming returns Server-Sent Events (SSE):
```
data: {"choices":[{"delta":{"content":"Once"}}]}

data: {"choices":[{"delta":{"content":" upon"}}]}

data: {"choices":[{"delta":{"content":" a time"}}]}

data: [DONE]
```

## Using with OpenAI SDK

### Python

```python
from openai import OpenAI

# Configure for local server
client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed"  # Or your API key
)

# Chat completion
response = client.chat.completions.create(
    model="local-model",  # Model name doesn't matter for local
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Explain quantum computing in one sentence."}
    ],
    temperature=0.7,
    max_tokens=100
)

print(response.choices[0].message.content)

# Streaming
stream = client.chat.completions.create(
    model="local-model",
    messages=[{"role": "user", "content": "Write a poem"}],
    stream=True
)

for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

### Node.js

```javascript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'http://localhost:8080/v1',
  apiKey: 'not-needed'
});

const response = await client.chat.completions.create({
  model: 'local-model',
  messages: [
    { role: 'user', content: 'Hello!' }
  ]
});

console.log(response.choices[0].message.content);
```

## Integration with Popular Tools

### LangChain

```python
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

# Configure for local server
llm = ChatOpenAI(
    base_url="http://localhost:8080/v1",
    api_key="not-needed",
    model="local-model",
    temperature=0.7
)

# Use like any other LangChain LLM
response = llm.invoke([HumanMessage(content="What is AI?")])
print(response.content)

# With chains
from langchain_core.prompts import ChatPromptTemplate

prompt = ChatPromptTemplate.from_messages([
    ("system", "You are a {topic} expert."),
    ("human", "Explain {concept}")
])

chain = prompt | llm
response = chain.invoke({"topic": "physics", "concept": "relativity"})
```

### LlamaIndex

```python
from llama_index.llms.openai_like import OpenAILike
from llama_index.core import Settings, SimpleDirectoryReader, VectorStoreIndex

# Configure local LLM
llm = OpenAILike(
    api_base="http://localhost:8080/v1",
    api_key="not-needed",
    model="local-model",
    temperature=0.7,
    context_window=8192
)

Settings.llm = llm

# Build index
documents = SimpleDirectoryReader("./data").load_data()
index = VectorStoreIndex.from_documents(documents)

# Query
query_engine = index.as_query_engine()
response = query_engine.query("What are the main points?")
print(response)
```

### AutoGen

```python
from autogen import AssistantAgent, UserProxyAgent

# Configure for local server
config_list = [
    {
        "model": "local-model",
        "base_url": "http://localhost:8080/v1",
        "api_key": "not-needed",
    }
]

assistant = AssistantAgent(
    name="assistant",
    llm_config={"config_list": config_list}
)

user_proxy = UserProxyAgent(
    name="user_proxy",
    human_input_mode="NEVER",
    max_consecutive_auto_reply=10
)

user_proxy.initiate_chat(assistant, message="Write a Python function to sort a list")
```

## Advanced Server Configuration

### Multiple Models

Run multiple server instances on different ports:

```bash
# Server 1: 7B model for fast responses
./llama-server -m ./models/Llama-3.2-7B.gguf --port 8080

# Server 2: 70B model for quality (in another terminal)
./llama-server -m ./models/Llama-3.1-70B.gguf --port 8081
```

Switch between them by changing `base_url`.

### Docker Deployment

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    cuda-toolkit \
    git

WORKDIR /app
RUN git clone https://github.com/ggerganov/llama.cpp.git .
RUN make LLAMA_CUDA=1

COPY models/ ./models/

EXPOSE 8080

CMD ["./llama-server", "-m", "./models/model.gguf", "--host", "0.0.0.0", "-ngl", "99"]
```

```bash
# Build and run
docker build -t local-llm .
docker run --gpus all -p 8080:8080 local-llm
```

### Systemd Service

Create `/etc/systemd/system/llama-server.service`:

```ini
[Unit]
Description=LLaMA.cpp Server
After=network.target

[Service]
Type=simple
User=youruser
WorkingDirectory=/home/youruser/codebases/local-llms
ExecStart=/home/youruser/codebases/local-llms/llama-server \
    -m /home/youruser/codebases/local-llms/models/model.gguf \
    --host 0.0.0.0 \
    --port 8080 \
    -ngl 99
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable llama-server
sudo systemctl start llama-server

# Check status
sudo systemctl status llama-server
```

### Load Balancing

Use nginx for load balancing multiple instances:

```nginx
upstream llama_backend {
    server localhost:8080;
    server localhost:8081;
    server localhost:8082;
}

server {
    listen 80;
    
    location /v1/ {
        proxy_pass http://llama_backend/v1/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Performance Tuning

### Optimal Settings for RTX 3060 12GB

```bash
./llama-server \
  -m model.gguf \
  -ngl 99 \              # Full GPU offload
  -c 8192 \              # Context size
  --batch-size 512 \     # Batch processing
  --ubatch-size 64 \     # Physical batch
  --threads 6 \          # Leave 2 cores for system
  --temp 0.7 \
  --top-p 0.9
```

### Monitoring

```bash
# Check server health
curl http://localhost:8080/health

# Monitor with watch
watch -n 1 'curl -s http://localhost:8080/health | jq'
```

### Benchmarking

```python
import time
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8080/v1", api_key="x")

# Measure tokens per second
start = time.time()
response = client.chat.completions.create(
    model="test",
    messages=[{"role": "user", "content": "x" * 1000}],
    max_tokens=500
)
elapsed = time.time() - start

print(f"Tokens/sec: {response.usage.completion_tokens / elapsed}")
print(f"Total time: {elapsed:.2f}s")
```

## Troubleshooting

### Connection Refused

```bash
# Check if server is running
curl http://localhost:8080/health

# Check if port is in use
lsof -i :8080

# Ensure host is accessible
./llama-server --host 0.0.0.0  # Listen on all interfaces
```

### Slow Responses

1. Verify GPU offload: Look for `offloading 99 layers to GPU`
2. Reduce context size: `-c 4096` instead of `-c 8192`
3. Check VRAM: `nvidia-smi` to ensure model fits in VRAM
4. Lower batch size if OOM

### API Compatibility Issues

Some tools expect specific model names:

```bash
# Use --alias to set model name
./llama-server -m model.gguf --alias "gpt-4"
```

## Security Considerations

### For Local Development
- Default settings are fine
- Bind to localhost only: `--host 127.0.0.1`

### For Network Access
```bash
# Set API key
./llama-server -m model.gguf --api-key "your-secret-key"

# Use with client
client = OpenAI(base_url="http://your-server:8080/v1", api_key="your-secret-key")
```

### For Production
- Put behind reverse proxy (nginx, traefik)
- Enable HTTPS/TLS
- Use authentication
- Rate limiting
- Monitor and log requests

## Next Steps

- [Benchmarking Guide](./6-benchmarking-performance.md) - Measure performance
- [Alternative Backends](./7-alternative-backends.md) - Explore other options
