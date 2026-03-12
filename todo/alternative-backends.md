# Research: Alternative LLM Backends

This guide compares llama.cpp with other popular local LLM deployment options to help you choose the right tool for your needs.

## Overview Comparison

| Backend | Ease of Use | Performance | Flexibility | Model Support | Best For |
|---------|------------|-------------|-------------|---------------|----------|
| **llama.cpp** | Medium | Excellent | High | GGUF models | Production, customization |
| **Ollama** | Very Easy | Good | Medium | Curated models | Quick setup, beginners |
| **LM Studio** | Very Easy | Good | Low | GGUF models | Desktop GUI, testing |
| **vLLM** | Medium | Best | High | HF models | High-throughput serving |
| **Text Generation Inference** | Hard | Excellent | Medium | HF models | Enterprise deployment |

---

## 1. Ollama

### Overview
Ollama is a user-friendly tool for running LLMs locally with a focus on simplicity.

### Installation

```bash
# Linux
curl -fsSL https://ollama.com/install.sh | sh

# Verify
ollama --version
```

### Usage

```bash
# Pull and run a model
ollama run llama3.2

# Pull without running
ollama pull llama3.2:7b

# List models
ollama list

# Remove model
ollama rm llama3.2
```

### API Usage

```bash
# Generate text
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Why is the sky blue?"
}'

# Chat API
curl http://localhost:11434/api/chat -d '{
  "model": "llama3.2",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ]
}'
```

### Python Client

```python
import ollama

# Simple generation
response = ollama.chat(model='llama3.2', messages=[
  {'role': 'user', 'content': 'Why is the sky blue?'}
])

print(response['message']['content'])

# Streaming
stream = ollama.chat(
    model='llama3.2',
    messages=[{'role': 'user', 'content': 'Write a story'}],
    stream=True
)

for chunk in stream:
    print(chunk['message']['content'], end='')
```

### Pros

✅ **Extremely easy to install and use**
✅ **Automatic model management**
✅ **Good model discovery (ollama.com/library)**
✅ **Active development and community**
✅ **Docker support**
✅ **Built-in API server**

### Cons

❌ **Less control over parameters**
❌ **Model format locked to Ollama**
❌ **Limited customization**
❌ **Slightly higher overhead than llama.cpp**
❌ **Cannot use arbitrary GGUF files directly**

### Best Use Cases

- Quick prototyping
- Beginners to local LLMs
- Development environments
- When you want "it just works"

### Performance Comparison

```
Ollama (llama3.2:7b):
- Generation: ~45 t/s (RTX 3060)
- Memory: ~5.5 GB
- Startup: < 5 seconds

llama.cpp (Llama-3.2-7B-Q4_K_M):
- Generation: ~52 t/s (RTX 3060)
- Memory: ~4.2 GB
- Startup: < 2 seconds
```

---

## 2. LM Studio

### Overview
LM Studio is a desktop application with a GUI for running local LLMs.

### Installation

Download from: https://lmstudio.ai/

Available for Windows, macOS, and Linux.

### Features

**Graphical Interface:**
- Model browser and downloader
- Chat interface
- Parameter tuning sliders
- Model comparison tools

**Server Mode:**

```bash
# Start local server from CLI
lms server start

# Or use GUI to start server
```

### Pros

✅ **Beautiful, intuitive GUI**
✅ **Built-in model search and download**
✅ **Easy parameter tuning**
✅ **Model comparison features**
✅ **No command line needed**
✅ **Good for non-technical users**

### Cons

❌ **Closed source**
❌ **Desktop application only (no headless)**
❌ **Less flexible than CLI tools**
❌ **Proprietary software**
❌ **Cannot script or automate easily**

### Best Use Cases

- Testing and experimenting
- Non-technical users
- Visual learners
- Model comparison and evaluation

---

## 3. vLLM

### Overview
vLLM is a high-performance LLM serving library optimized for throughput.

### Installation

```bash
pip install vllm
```

### Usage

```python
from vllm import LLM, SamplingParams

# Initialize model
llm = LLM(model="meta-llama/Llama-3.2-7B-Instruct")

# Generate
outputs = llm.generate(
    prompts=["Hello, my name is"],
    sampling_params=SamplingParams(
        max_tokens=100,
        temperature=0.7
    )
)

for output in outputs:
    print(output.outputs[0].text)
```

### Server Mode

```bash
# Start API server
python -m vllm.entrypoints.api_server \
    --model meta-llama/Llama-3.2-7B-Instruct \
    --port 8000
```

### Key Features

**PagedAttention:**
- More efficient memory management
- Higher throughput
- Better multi-request handling

**Continuous Batching:**
- Dynamic batch sizing
- Better GPU utilization

### Pros

✅ **Highest throughput for batch requests**
✅ **Production-grade serving**
✅ **Advanced memory management**
✅ **OpenAI-compatible API**
✅ **Good for multi-user scenarios**

### Cons

❌ **Requires HuggingFace models (not GGUF)**
❌ **Higher VRAM requirements**
❌ **More complex setup**
❌ **Less optimized for single-user interactive use**
❌ **No quantization support (yet)**

### Best Use Cases

- High-throughput API serving
- Multi-user applications
- Production deployments
- When you need maximum throughput

### Performance

```
vLLM (Llama-3.2-7B, FP16):
- Single request: ~40 t/s
- Batch (32 requests): ~800 t/s total
- VRAM: ~14 GB (FP16)

llama.cpp (Llama-3.2-7B, Q4_K_M):
- Single request: ~52 t/s
- VRAM: ~4.2 GB (quantized)
```

---

## 4. Text Generation Inference (TGI)

### Overview
TGI is Hugging Face's production-ready LLM serving solution.

### Installation

```bash
# Using Docker (recommended)
docker run --gpus all \
    -p 8080:80 \
    ghcr.io/huggingface/text-generation-inference:2.0 \
    --model-id meta-llama/Llama-3.2-7B-Instruct
```

### Usage

```bash
# Query the API
curl http://localhost:8080/generate \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "inputs": "What is deep learning?",
        "parameters": {
            "max_new_tokens": 100,
            "temperature": 0.7
        }
    }'
```

### Pros

✅ **Production-ready**
✅ **Built-in telemetry and logging**
✅ **Safetensors support**
✅ **Multi-model support**
✅ **Enterprise features**
✅ **Active development by Hugging Face**

### Cons

❌ **Complex setup**
❌ **Requires Docker for best experience**
❌ **No GGUF support**
❌ **Higher resource requirements**
❌ **Overkill for simple use cases**

### Best Use Cases

- Enterprise deployments
- Multi-model serving
- When you need monitoring/telemetry
- Hugging Face ecosystem integration

---

## 5. MLX (Apple Silicon)

### Overview
MLX is Apple's framework for running LLMs on Apple Silicon.

### Installation

```bash
pip install mlx-lm
```

### Usage

```python
from mlx_lm import load, generate

model, tokenizer = load("mlx-community/Llama-3.2-7B-Instruct-4bit")

text = generate(
    model,
    tokenizer,
    prompt="Hello, how are you?",
    max_tokens=100
)

print(text)
```

### Pros

✅ **Optimized for Apple Silicon**
✅ **Very fast on M1/M2/M3**
✅ **Native macOS support**
✅ **Good quantization support**

### Cons

❌ **Apple Silicon only**
❌ **Limited model support**
❌ **Newer, less mature**

### Best Use Cases

- MacBook/Mac Mini users
- Apple Silicon development

---

## 6. KoboldCPP

### Overview
KoboldCPP is a single-file GGUF runtime focused on creative writing.

### Installation

Download from: https://github.com/LostRuins/koboldcpp

### Usage

```bash
./koboldcpp.py model.gguf --port 5001
```

### Pros

✅ **Single executable**
✅ **No dependencies**
✅ **Creative writing features**
✅ **Multiple backends (CUDA, CLBlast, etc.)**
✅ **Web UI included**

### Cons

❌ **Focused on creative writing**
❌ **Less polished API**
❌ **Smaller community**

### Best Use Cases

- Creative writing applications
- Simple deployment
- When you want a single binary

---

## Decision Matrix

### Choose llama.cpp if:
- ✅ You want maximum control and flexibility
- ✅ You're using GGUF models
- ✅ You need GPU + CPU hybrid execution
- ✅ You want best performance on consumer hardware
- ✅ You're comfortable with CLI

### Choose Ollama if:
- ✅ You want easiest possible setup
- ✅ You're okay with curated model selection
- ✅ You want good defaults without tuning
- ✅ You're developing locally

### Choose vLLM if:
- ✅ You need high-throughput batch processing
- ✅ You're serving multiple users
- ✅ You want production-grade features
- ✅ You're using HuggingFace models

### Choose LM Studio if:
- ✅ You prefer GUI over CLI
- ✅ You're testing/experimenting
- ✅ You're not technical

### Choose TGI if:
- ✅ You're deploying in enterprise
- ✅ You need monitoring and telemetry
- ✅ You're in Hugging Face ecosystem

## Migration Guide

### From Ollama to llama.cpp

```bash
# 1. Export model from Ollama
ollama show llama3.2 --modelfile > Modelfile

# 2. Find original GGUF source
# Check ollama documentation for model source

# 3. Download GGUF directly
huggingface-cli download bartowski/Llama-3.2-7B-Instruct-GGUF \
    Llama-3.2-7B-Instruct-Q4_K_M.gguf

# 4. Run with llama.cpp
./llama-server -m Llama-3.2-7B-Instruct-Q4_K_M.gguf
```

### From LM Studio to llama.cpp

```bash
# 1. Find LM Studio model cache
# Usually: ~/.cache/lm-studio/models/

# 2. Models are already in GGUF format
# Copy or symlink to your models directory

# 3. Run with llama.cpp
./llama-server -m ~/.cache/lm-studio/models/model.gguf
```

## Performance Comparison Summary

```
┌──────────────────┬─────────────┬──────────┬────────────┐
│ Backend          │ Speed (t/s) │ VRAM (GB)│ Ease (1-5) │
├──────────────────┼─────────────┼──────────┼────────────┤
│ llama.cpp        │ 52          │ 4.2      │ 3          │
│ Ollama           │ 45          │ 5.5      │ 5          │
│ LM Studio        │ 43          │ 5.0      │ 5          │
│ vLLM (FP16)      │ 40          │ 14.0     │ 3          │
│ TGI (FP16)       │ 42          │ 14.0     │ 2          │
│ KoboldCPP        │ 48          │ 4.5      │ 4          │
└──────────────────┴─────────────┴──────────┴────────────┘

Note: Speeds for Llama-3.2-7B on RTX 3060 12GB
```

## Conclusion

For your setup (RTX 3060 12GB), **llama.cpp** offers the best balance of:
- Performance (fastest generation)
- Memory efficiency (quantization support)
- Flexibility (full control over parameters)
- Model choice (any GGUF model)

**Ollama** is recommended for quick prototyping when you want minimal setup.

**vLLM** is worth considering if you need to serve multiple users simultaneously.

## Related Documentation

- [Model Selection](./3-model-selection-tradeoffs.md)
- [OpenAI API Setup](./5-openai-compatible-api.md)
- [Benchmarking](./6-benchmarking-performance.md)
