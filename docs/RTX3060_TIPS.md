# RTX 3060 Local LLM Tips (Community Research)

> Sourced from r/LocalLLaMA threads, March 2026.  
> Hardware context: RTX 3060 12GB VRAM, 16–32GB RAM.

---

## Recommended Models

### Best All-Around (fits fully in 12GB VRAM)

| Model | Quant | VRAM Est. | Speed | Notes |
|---|---|---|---|---|
| **GLM-4.7-Flash** (MoE 23B A3B) | Q4_K_M | ~12GB | moderate | #1 on leaderboard, tool-call capable, fits in VRAM |
| **Qwen3-30B-A3B** | Q2_K_XL | ~11.8GB | 20–55 t/s | #5 on leaderboard, MoE magic, fully in VRAM |
| **Nemotron-3-Nano** (30B A3B) | Q2_K_XL | ~12GB | moderate | #4 on leaderboard, NVIDIA MoE |
| **GPT-OSS 20B** | Q4_K_M | ~14GB (partial) | ~15 t/s | #2 on leaderboard, partial offload to RAM |
| **Qwen3 14B** | IQ4_XS | ~8.5GB | ~15–20 t/s | Best dense reasoning that fully fits |
| **Qwen2.5-Coder 7B** | Q8_0 | ~8GB | fast | Coding fast lane, fits fully |
| **Codestral 22B** | Q4_K_M | ~14GB (partial) | ~10 t/s | #6 on leaderboard, code-focused |

### MoE Models (run larger, use partial offload)

| Model | Quant | VRAM | Speed | Notes |
|---|---|---|---|---|
| **GLM-4.7-Flash** (23B A3B) | Q4_K_M | ~12GB | moderate | #1 leaderboard, fits in VRAM, tool-call support |
| **Nemotron-3-Nano** (30B A3B) | Q2_K_XL | ~12GB | moderate | #4 leaderboard, NVIDIA MoE |
| **Qwen3-30B-A3B** | Q2_K_XL (11.8GB) | ~11.5GB | 20–55 t/s | Fits in VRAM! Only 3B active params |
| **Qwen3-30B-A3B** | Q4_K_M / Q6_K | ~14–16GB | 20+ t/s | Partial offload with `--n-cpu-moe` |

### Vision / Multimodal

| Model | Quant | Notes |
|---|---|---|
| **Qwen3-VL-8B** | IQ4_XS | Top pick VLM, ~71k ctx, multimodal, fast |
| **GLM-4.6V-Flash 9B** | Q4_XL | Multimodal, tool-call capable |
| **Llama 3.2 11B Vision** | Q4/Q5 | Good for image understanding |
| **Qwen2-VL-7B** | Q4/Q5 | Solid VLM, fits comfortably |

---

## Key Concepts

### Quantization Guide

```
Q8_0   → highest quality, ~1.0x model size in GB, max VRAM usage
Q5_K_M → great balance, ~0.63x, recommended for 7–9B models
Q4_K_M → standard 4-bit, ~0.53x, best quality/size tradeoff
IQ4_XS → imatrix 4-bit, slightly smaller than Q4_K_M, similar quality
Q3_K_M → 3-bit, smaller but quality degrades (especially on MoE)
Q2_K_XL → 2-bit, only use for MoE models (active param set is larger)
```

Rule of thumb: **context window uses 1–2GB VRAM** on top of model size.

### VRAM Budget Formula
```
Required VRAM = model_file_size + context_size_overhead (1–2GB)

Example: Qwen3 14B IQ4_XS (~8.5GB) + 2GB ctx = ~10.5GB → fits in 12GB
Example: Qwen3 14B Q8 (~14GB) + 2GB ctx = ~16GB → does NOT fit
```

### Partial GPU Offload (for models > 12GB)

Use `--n-gpu-layers` to control how many layers go to GPU. Remaining layers run on CPU using system RAM.

```bash
# Example: offload 35 layers to GPU, rest to CPU
llama-server -m model.gguf -ngl 35

# Or let llama.cpp auto-fit to available VRAM
llama-server -m model.gguf --fit
llama-server -m model.gguf -fitt 1  # keep 1GB VRAM free
```

### MoE-Specific: CPU Expert Offload

For MoE models (Qwen3-30B-A3B, GLM-4.7-Flash), experts can be offloaded to CPU while attention layers stay on GPU:

```bash
# Load attention on GPU, route MoE experts through CPU
llama-server -m qwen3-30b-a3b.gguf --n-cpu-moe 35 --no-mmap
```

This is why **Qwen3-30B-A3B at Q2_K_XL (11.8GB) can fully fit in 12GB VRAM** and still run at 20–55 t/s — only 3B params are active at any time.

---

## llama-server Optimized Settings

### General recommended flags

```bash
llama-server \
  -m model.gguf \
  -ngl -1 \              # offload all layers to GPU (if it fits)
  -c 8192 \              # context size (reduce to save VRAM)
  -fa on \               # flash attention (speeds up, saves KV cache VRAM)
  --no-mmap \            # recommended for MoE models
  -ctk q8_0 \            # quantize KV cache keys (saves VRAM)
  -ctv q8_0 \            # quantize KV cache values (saves VRAM)
  --parallel 2           # concurrent requests (for serving)
```

### Example: Qwen3-14B with 48k context

```bash
llama-server \
  -m Qwen3-14B-IQ4_XS.gguf \
  --no-mmap \
  -c 48000 \
  -ngl 41 \
  -ctk q8_0 -ctv q8_0 \
  -fa on \
  --parallel 2
```

### Example: Qwen3-VL-8B multimodal with 71k context

```bash
llama-server \
  -m Qwen3-VL-8B-Instruct-IQ4_XS.gguf \
  --no-mmap \
  --mmproj mmproj-Qwen3VL-8B-Instruct-F16.gguf \
  -c 71680 \
  -ctk q8_0 -ctv q8_0 \
  -fa on \
  --parallel 2
```

### Example: Qwen3-30B-A3B MoE (full VRAM fit)

```bash
llama-server \
  -m Qwen3-30B-A3B-Q2_K_XL.gguf \
  --no-mmap \
  -ngl -1 \
  -fa on
```

---

## Speed Benchmarks (Community Reported, RTX 3060 12GB)

| Model | Quant | Speed |
|---|---|---|
| Qwen3 4B | Q6_K / high | 100+ t/s |
| Qwen2.5-Coder 7B | Q8_0 | ~60–80 t/s |
| Qwen3-30B-A3B | Q2_K_XL | 20–55 t/s |
| Qwen3-30B-A3B | Q4_K_M (partial) | 50–55 t/s |
| GLM-4.7-Flash | Q4_K_M | moderate (community TBD) |
| GPT-OSS 20B | Q4_K_M (partial) | ~15 t/s |
| Mistral Small 24B | Q4 (partial) | ~10 t/s |

---

## Use Case Recommendations

### Coding
- **Qwen2.5-Coder 7B Q8_0** — fast, copy-paste ready, fits fully in VRAM
- **Codestral 22B Q4_K_M** — #6 leaderboard, code-focused, partial offload needed
- **GLM-4.7-Flash Q4_K_M** — #1 leaderboard, tool-call support, VSCode integration via roocode

### General Chat / Study / Tutor
- **GLM-4.7-Flash Q4_K_M** — #1 leaderboard, fits in 12GB
- **Qwen3-30B-A3B Q2_K_XL** — best quality, fits in VRAM via MoE
- **Qwen2.5 14B Q4_K_M** — best for knowledge/explanations (dense)

### Vision / Image Input
- **Qwen3-VL-8B IQ4_XS** — top VLM pick, huge 71k context, fast
- **GLM-4.6V-Flash 9B Q4_XL** — multimodal + tool-call capable
- Must use vision-capable models — regular text models are "blind"

### Reasoning / Thinking Tasks
- **Qwen3-30B-A3B Q2_K_XL** — fits in 12GB, MoE magic, 20+ t/s
- **Qwen3 14B** — strong dense reasoning

### RP / Creative Writing
- **Magnum-v4 9B Q5_K_M** — community favorite for RP/narration
- **MN-12B-Mag-Mell-R1 Q6_K** — good for RP

---

## Tools & Frontends

- **llama.cpp / llama-server** — most control, best performance tuning
- **Ollama** — easy setup, works with Open WebUI
- **LM Studio** — good GUI for beginners, shows VRAM usage
- **Open WebUI + Ollama** — best full stack for daily use
- **Roocode (VSCode extension)** — connect llama-server for coding assistance

---

## Hardware Tricks

### Add a second GPU (cheap VRAM expansion)
- **P102-100 (10GB, ~$40 on eBay)** — adds 10GB VRAM, works with LLMs only (not gaming/image gen)
- **P104-100 (8GB, ~$25)** — adds 8GB, same deal
- Combined with 3060 12GB = 20–22GB total VRAM → run Gemma 3 27B at 7–9 t/s
- Just plug in, no special setup needed for llama.cpp

### Context Size vs Speed
- Smaller context = faster prompt processing + less VRAM
- For most tasks, 8k–16k is plenty
- If context won't fit in VRAM → performance degrades significantly
- Use `-ctk q8_0 -ctv q8_0` to compress KV cache and reclaim VRAM

---

## Common Mistakes to Avoid

1. **Don't use `--chat-template` flag** — GGUF models have the template embedded; overriding it causes garbled output
2. **Don't use `-ngl 0` accidentally** — always set explicit value or `-ngl -1` for full GPU
3. **Boolean flags need explicit values** in some llama.cpp versions: `--flash-attn on` not just `--flash-attn`
4. **Don't run huge models on CPU only** — 21GB model on 8GB VRAM = 6–10 t/s is expected, not a bug
5. **Don't use ancient models** (Wizard-Vicuna 13B, Llama 2) — Gemma 3 / Qwen3 are dramatically better

---

## Quick Decision Guide

```
Need vision/images?         → Qwen3-VL-8B IQ4_XS  (top VLM, 71k ctx)
Best coding assistant?      → Qwen2.5-Coder 7B Q8_0  (fast)  |  Codestral 22B Q4_K_M (smart)
Best quality in 12GB?       → GLM-4.7-Flash Q4_K_M  (#1 leaderboard, MoE, fits)
Best speed workhorse?       → Qwen3 4B Q6_K  (100+ t/s)
General daily driver?       → GLM-4.7-Flash Q4_K_M  (or Qwen3-30B-A3B Q2_K_XL)
Want to go bigger?          → Add P102-100 GPU ($40) for +10GB VRAM
```
