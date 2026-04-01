# Loading a 17.5GB Model on RTX 3060 (12GB VRAM)

## The Problem

A 17.5GB model file cannot fit entirely in 12GB VRAM. Example: **Gemma 3 27B Q4_K_M** is ~17GB.

## The Technique: Partial GPU Offload (Layer Splitting)

llama.cpp splits the model layer-by-layer across two memory pools:

```
[GPU VRAM 12GB] ← as many transformer layers as fit
[System RAM    ] ← remaining layers spill here
```

The CPU handles inference for the RAM-resident layers, then hands results back to the GPU for the VRAM-resident layers. This happens automatically every forward pass.

### How to enable it

**Option A — Auto-fit (recommended):**
```bash
llama-server -m model.gguf --fit on
```
llama.cpp measures free VRAM and calculates the maximum layers that fit, then assigns the rest to CPU.

**Option B — Manual layer count:**
```bash
# Offload 35 layers to GPU, rest go to CPU/RAM
llama-server -m model.gguf -ngl 35
```
Use `--verbose` to see how many layers the model has, then tune `-ngl` to stay under 12GB.

---

## Reclaiming Extra VRAM (Fit More Layers on GPU)

Every layer on GPU = faster inference. Use these flags to squeeze more layers onto VRAM:

| Flag | Effect | VRAM saved |
|---|---|---|
| `-fa on` | Flash attention — reduces KV cache peak usage | ~1–2GB |
| `-ctk q8_0` | Quantize KV cache keys | ~20–30% of KV size |
| `-ctv q8_0` | Quantize KV cache values | ~20–30% of KV size |
| `-c 8192` | Smaller context = smaller KV cache | scales with context size |

Combining all of them can recover 2–4GB, pushing more layers onto GPU.

---

## Full Example: Gemma 3 27B Q4_K_M (~17GB) on RTX 3060

```bash
llama-server \
  -m Gemma-3-27B-Q4_K_M.gguf \
  --fit on \          # auto-split layers across VRAM + RAM
  -fa on \            # flash attention saves KV VRAM
  -ctk q8_0 \         # quantize KV keys
  -ctv q8_0 \         # quantize KV values
  -c 8192 \           # modest context to save VRAM
  --host 127.0.0.1 \
  --port 8080
```

Expected result: ~12 layers on CPU, rest on GPU. Speed ~3–7 t/s (CPU bottleneck on RAM-resident layers).

---

## MoE Models: A Special Case

MoE models (GLM-4.7-Flash, Qwen3-30B-A3B) are different — only a fraction of parameters are **active** per token. This means a 23B-parameter MoE model behaves like a 3B model at inference time.

For MoE models that are slightly over VRAM, use `--n-cpu-moe` to route **expert layers** through CPU while keeping **attention layers** on GPU:

```bash
llama-server \
  -m Qwen3-30B-A3B-Q4_K_M.gguf \
  --n-cpu-moe 1 \     # offload MoE expert routing to CPU
  --no-mmap \         # avoids page faults on expert weights
  -fa on
```

This is more efficient than generic partial offload for MoE models because the hot path (attention) stays fully on GPU.

---

## Speed Expectations

| Scenario | Speed |
|---|---|
| Model fully fits in VRAM | 15–55 t/s |
| Partial offload (some layers in RAM) | 3–10 t/s |
| MoE with `--n-cpu-moe` | 10–25 t/s |
| Full CPU (no GPU) | 1–3 t/s |

Partial offload is slow because every token generation requires PCIe transfers between GPU and system RAM for the CPU-resident layers. The fewer layers on CPU, the faster it runs.

---

## Rule of Thumb

```
If model_size > 12GB:
  headroom = model_size - 10GB  (leave ~2GB for KV cache + OS)
  → that headroom must spill to RAM
  → expect speed proportional to how much stays on GPU
```
