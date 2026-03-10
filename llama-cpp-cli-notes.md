# llama.cpp CLI Tools Overview

| Binary | Purpose |
|--------|---------|
| **llama-cli** | Main tool - interactive chat & text completion |
| **llama-server** | HTTP API server (OpenAI-compatible) |
| **llama-bench** | Benchmark model performance (speed/throughput) |
| **llama-perplexity** | Measure model quality (lower = better) |
| **llama-quantize** | Convert FP16 models to quantized GGUF |
| **llama-tokenize** | Tokenize text using model's tokenizer |
| **llama-imatrix** | Generate importance matrix for quantization |
| **llama-gguf-split** | Split/merge large GGUF files |
| **llama-cvector-generator** | Generate control vectors |
| **llama-export-lora** | Export/adjust LoRA adapters |
| **llama-mtmd-cli** | Multi-token multimodal decoder (vision) |
| **llama-tts** | Text-to-speech generation |
| **llama-fit-params** | Find optimal parameters for hardware |

---

## llama-cli (Interactive/Completion)

### Model Loading
| Flag | Description | Default |
|------|-------------|---------|
| `-m, --model FNAME` | Path to model file | Required |
| `-mu, --model-url URL` | Download model from URL | - |
| `-hf, --hf-repo <user>/<model>[:quant]` | HuggingFace repo | - |
| `--lora FNAME` | LoRA adapter path | - |
| `--lora-scaled FNAME:SCALE` | LoRA with scaling | - |
| `--mmproj FILE` | Multimodal projector | - |

### Generation
| Flag | Description | Default |
|------|-------------|---------|
| `-c, --ctx-size N` | Context size (tokens) | Model default |
| `-n, --predict N` | Max tokens to generate | -1 (infinity) |
| `-t, --threads N` | CPU threads | -1 (auto) |
| `-tb, --threads-batch N` | Batch processing threads | Same as -t |
| `-b, --batch-size N` | Logical batch size | 2048 |
| `-ub, --ubatch-size N` | Physical batch size | 512 |
| `--keep N` | Tokens to keep from prompt | 0 (all) |

### GPU Acceleration
| Flag | Description | Default |
|------|-------------|---------|
| `-ngl, --n-gpu-layers N` | Layers offload to GPU | auto |
| `--gpu-layers all` | Offload all layers | - |
| `--split-mode {none,layer,row}` | Multi-GPU strategy | layer |
| `-ts, --tensor-split N0,N1,...` | GPU memory split | - |
| `-mg, --main-gpu INDEX` | Primary GPU | 0 |
| `--list-devices` | List available GPUs | - |

### Memory
| Flag | Description | Default |
|------|-------------|---------|
| `--mlock` | Lock model in RAM | - |
| `--mmap` | Memory-map model | enabled |
| `--no-mmap` | Disable memory-mapping | - |
| `--numa TYPE` | NUMA optimization | - |

### Sampling (Generation Quality)
| Flag | Description | Default |
|------|-------------|---------|
| `--temp N` | Temperature | 0.80 |
| `--top-k N` | Top-k sampling | 40 |
| `--top-p N` | Top-p (nucleus) sampling | 0.95 |
| `--min-p N` | Min-p sampling | 0.05 |
| `--typical N` | Locally typical p | 1.00 |
| `--repeat-last-n N` | Repetition penalty window | 64 |
| `--repeat-penalty N` | Repeat penalty | 1.00 |
| `--presence-penalty N` | Presence penalty | 0.00 |
| `--frequency-penalty N` | Frequency penalty | 0.00 |
| `--mirostat N` | Mirostat (0/1/2) | 0 |
| `-l, --logit-bias TOKEN_ID(+/-)BIAS` | Token bias | - |

### Context & RoPE Scaling
| Flag | Description | Default |
|------|-------------|---------|
| `--rope-scaling {none,linear,yarn}` | RoPE scaling | linear |
| `--rope-scale N` | Scale factor | - |
| `--rope-freq-base N` | RoPE base frequency | Model default |
| `--yarn-orig-ctx N` | YaRN original context | Model default |

### Chat/Conversation
| Flag | Description | Default |
|------|-------------|---------|
| `-sys, --system-prompt PROMPT` | System message | - |
| `--chat-template TEMPLATE` | Chat template | Model default |
| `--reasoning-format FORMAT` | Reasoning output | auto |
| `--reasoning-budget N` | Thinking budget | -1 |
| `-cnv, --conversation` | Conversation mode | auto |
| `-sp, --special` | Enable special tokens | false |

### Input/Output
| Flag | Description | Default |
|------|-------------|---------|
| `-p, --prompt PROMPT` | Input prompt | - |
| `-f, --file FNAME` | Prompt from file | - |
| `-e, --escape` | Process escape sequences | true |
| `--color` | Colorize output | auto |
| `--verbose-prompt` | Print verbose prompt | false |

### Other
| Flag | Description | Default |
|------|-------------|---------|
| `-h, --help` | Show help | - |
| `--version` | Show version | - |
| `--perf` | Show performance metrics | false |
| `--show-timings` | Show timing info | true |
| `--log-file FNAME` | Log to file | - |

---

## llama-server (API Server)

Run as HTTP API server (OpenAI-compatible):

```bash
llama-server -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf -c 4096 -ngl 99 --port 8080
```

### Key Server Options
| Flag | Description | Default |
|------|-------------|---------|
| `--port N` | Server port | 8080 |
| `--host ADDRESS` | Bind address | 127.0.0.1 |
| `-c, --ctx-size N` | Context size | Model default |
| `-ngl N` | GPU layers | auto |
| `-fa, --flash-attn` | Flash Attention | auto |

### API Endpoints
- `POST /v1/chat/completions` - Chat completions
- `POST /v1/completions` - Text completions
- `GET /v1/models` - List models
- `GET /health` - Health check

---

## Common Usage Examples

### Interactive Chat (GPU)
```bash
llama-cli -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf -ngl 99 -c 4096 -t 8
```

### Interactive Chat (CPU only)
```bash
llama-cli -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf -t 8
```

### Server Mode (GPU)
```bash
llama-server -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf -ngl 99 -c 4096 --port 8080
```

### With Custom System Prompt
```bash
llama-cli -m model.gguf -sys "You are a helpful coding assistant." -cnv
```

### Lower Temperature (more deterministic)
```bash
llama-cli -m model.gguf --temp 0.1 --top-p 0.9
```

### Higher Creativity
```bash
llama-cli -m model.gguf --temp 1.2 --top-p 0.95
```

---

## Notes

- **Quantization**: Q5_K_M is good balance of size/quality
- **GPU Layers**: Use `all` or high number for full GPU acceleration
- **Threads**: Set to physical CPU cores for best performance
- **Context Size**: Higher = more memory, longer conversations
- **NUMA**: Use `--numa distribute` on multi-socket systems

---

# llama.cpp Tools & Utilities

## llama-server
API server with OpenAI-compatible endpoints (see above)

## llama-cli / llama-completion
Interactive chat or completion mode. Use `llama-completion` for simple completion without chat template.

## llama-bench
Benchmark model performance (throughput, latency).

```bash
llama-bench -m model.gguf -ngl 99 -o md
```

Key options:
| Flag | Description |
|------|-------------|
| `-m` | Model path |
| `-ngl` | GPU layers |
| `-n-prompt` | Prompt tokens |
| `-n-gen` | Generation tokens |
| `-t` | Threads |
| `-o` | Output format (csv|json|jsonl|md|sql) |

## llama-batched-bench
Similar to llama-bench but for batched inference.

## llama-perplexity
Calculate model perplexity on a text file (measures model quality).

```bash
llama-perplexity -m model.gguf -f textfile.txt
```

## llama-quantize
Quantize FP16 model to smaller GGUF format.

```bash
llama-quantize model-f16.gguf model-q4_0.gguf q4_0
```

Quantization types (best to worst quality):
- `q4_0`, `q4_1` - 4-bit
- `q5_0`, `q5_1` - 5-bit  
- `q8_0` - 8-bit
- `f16` - Half precision

Better quantizations (recommended):
- `q4_k_m` - 4-bit with medium quality
- `q5_k_s`, `q5_k_m` - 5-bit
- `q8_0` - 8-bit

Options:
| Flag | Description |
|------|-------------|
| `--allow-requantize` | Re-quantize already quantized |
| `--pure` | Same type for all tensors |
| `--imatrix FILE` | Use importance matrix |
| `--dry-run` | Preview without writing |

## llama-tokenize
Tokenize text with a model's tokenizer.

```bash
llama-tokenize -m model.gguf -p "Hello world"
llama-tokenize -m model.gguf -f input.txt --ids
```

Options:
| Flag | Description |
|------|-------------|
| `-m` | Model path |
| `-p` | Prompt string |
| `-f` | Input file |
| `--ids` | Output token IDs only |
| `--no-bos` | Skip BOS token |
| `--show-count` | Show token count |

## llama-imatrix
Generate importance matrix for better quantization.

```bash
llama-imatrix -m model.gguf -f training_data.txt -o imatrix.dat
```

Used with `llama-quantize --imatrix imatrix.dat` for higher quality quantization.

## llama-gguf-split
Split/merge large GGUF files.

```bash
# Split into chunks
llama-gguf-split --split --split-max-size 2G model.gguf split_

# Merge multiple files
llama-gguf-split --merge file1.gguf file2.gguf output.gguf
```

## llama-cvector-generator
Generate control vectors for style conditioning.

## llama-export-lora
Export/adjust LoRA adapters.

## llama-mtmd-cli
Multi-token multimodal decoder (for vision models).

## llama-tts
Text-to-speech using llama.cpp (requires TTS model).

## llama-fit-params
Interactive tool to find optimal parameters for your hardware.

```bash
llama-fit-params -m model.gguf
```
