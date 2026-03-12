# GGUF Model Format and Quantization Guide

## What is GGUF?

**GGUF** (GPT-Generated Unified Format) is a binary file format designed for storing large language models. It's the successor to GGML format and is optimized for:

- **Fast loading** - Memory-mapped file access
- **Self-contained** - Model weights, tokenizer, and metadata in one file
- **Cross-platform** - Works on CPU, GPU, and various operating systems
- **Efficient storage** - Supports quantization for smaller file sizes

---

## GGUF File Structure

```
┌─────────────────────────────────────┐
│           Header                    │
│  - Magic number ("GGUF")            │
│  - Version                          │
│  - Tensor count                     │
│  - Metadata KV count                │
├─────────────────────────────────────┤
│         Metadata KV Data            │
│  - Model name, architecture         │
│  - Hyperparameters                  │
│  - Tokenizer data                   │
├─────────────────────────────────────┤
│        Tensor Info                  │
│  - Tensor names, types, shapes      │
│  - Offset mappings                  │
├─────────────────────────────────────┤
│          Tensor Data                │
│  - Actual model weights             │
│  - Quantized or full precision      │
└─────────────────────────────────────┘
```

---

## Quantization Explained

### Why Quantize?

Quantization reduces model size and memory requirements by using lower-precision numbers:

| Precision | Bits per Weight | Size (7B Model) | RAM Required |
|-----------|-----------------|-----------------|--------------|
| FP32      | 32-bit          | ~28 GB          | ~30+ GB      |
| FP16      | 16-bit          | ~14 GB          | ~16 GB       |
| Q8_0      | 8-bit           | ~7 GB           | ~8 GB        |
| Q5_K_M    | 5.5-bit         | ~5 GB           | ~6 GB        |
| Q4_K_M    | 4.5-bit         | ~4 GB           | ~5 GB        |
| Q2_K      | 2.5-bit         | ~2.5 GB         | ~3.5 GB      |

**Trade-off**: Smaller size = faster inference, but potentially lower quality output.

---

## Quantization Types

### Standard Quantization Labels

| Label    | Bits | Description                              | Quality     |
|----------|------|------------------------------------------|-------------|
| `F32`    | 32   | Full precision (rarely used)             | Best        |
| `F16`    | 16   | Half precision                           | Excellent   |
| `Q4_0`   | 4    | Basic 4-bit quantization                 | Good        |
| `Q4_1`   | 4    | 4-bit with improved scaling              | Better      |
| `Q5_0`   | 5    | Basic 5-bit quantization                 | Good        |
| `Q5_1`   | 5    | 5-bit with improved scaling              | Better      |
| `Q8_0`   | 8    | 8-bit quantization                       | Very Good   |

### K-Quant (Recommended)

K-quant uses mixed precision for different tensor groups:

| Label      | Avg Bits | Description                              | Use Case          |
|------------|----------|------------------------------------------|-------------------|
| `Q2_K`     | 2.5      | Smallest, uses Q4/Q6 mixed               | Very limited RAM  |
| `Q3_K_S`   | 3.25     | Smallest 3-bit variant                   | Low RAM           |
| `Q3_K_M`   | 3.5      | Medium 3-bit variant                     | Low RAM           |
| `Q3_K_L`   | 3.75     | Largest 3-bit variant                    | Low RAM           |
| `Q4_K_S`   | 4.25     | Smallest 4-bit, good quality/size        | Balanced          |
| `Q4_K_M`   | 4.5      | **Recommended** - best 4-bit balance     | **Best value**    |
| `Q5_K_S`   | 5.25     | Smallest 5-bit                           | High quality      |
| `Q5_K_M`   | 5.5      | **Recommended** - excellent quality      | **Best quality**  |
| `Q6_K`     | 6.5      | Near-lossless                            | Maximum quality   |
| `Q8_0`     | 8        | Virtually lossless                       | Reference         |

### Naming Convention

- **Q** = Quantized
- **Number** = Approximate bits per weight
- **K** = K-quant (mixed precision)
- **S/M/L** = Small/Medium/Large (within same bit level)

---

## Quality Comparison

### Recommended Quantizations by Priority

| Priority | Quant Type | Size Ratio | Quality Loss | Best For                    |
|----------|------------|------------|--------------|-----------------------------|
| 1        | `Q5_K_M`   | ~40%       | Minimal      | Best quality/size balance   |
| 2        | `Q4_K_M`   | ~32%       | Small        | Best overall value          |
| 3        | `Q6_K`     | ~50%       | Negligible | Near-FP16 quality           |
| 4        | `Q3_K_M`   | ~25%       | Noticeable | Very limited RAM            |
| 5        | `Q8_0`     | ~55%       | None       | When size doesn't matter    |

### Quality Guidelines

- **Q5_K_M or higher**: Indistinguishable from FP16 for most tasks
- **Q4_K_M**: Excellent for general use, minor quality loss
- **Q3_K_M**: Acceptable for simple tasks, noticeable degradation
- **Q2_K**: Last resort, significant quality loss

---

## Inspecting GGUF Files

### Using `gguf-info` (llama.cpp)

```bash
# Basic info
python3 -m llama_cpp.gguf_info model.gguf

# Or use the C++ tool
./gguf-info model.gguf
```

### Using Python (llama-cpp-python)

```python
from llama_cpp import Llama

llm = Llama(model_path="model.gguf", verbose=False)
print(llm.model_metadata())
```

### Using `file` command

```bash
file model.gguf
# Output: model.gguf: GGUF data, version 3, ...
```

---

## Quantizing Models

### Basic Quantization

```bash
# Convert FP16 to Q4_K_M
llama-quantize model-f16.gguf model-q4_k_m.gguf Q4_K_M

# Convert with dry-run (preview only)
llama-quantize model-f16.gguf model-q4_k_m.gguf Q4_K_M --dry-run
```

### Advanced Quantization with Importance Matrix

For better quality, use an importance matrix:

```bash
# Step 1: Generate importance matrix
llama-imatrix -m model-f16.gguf -f calibration-text.txt -o imatrix.dat

# Step 2: Quantize using the matrix
llama-quantize model-f16.gguf model-q4_k_m.gguf Q4_K_M --imatrix imatrix.dat
```

### Re-quantizing

```bash
# Re-quantize an already quantized model (not recommended)
llama-quantize model-q8.gguf model-q4.gguf Q4_K_M --allow-requantize
```

---

## Choosing the Right Quantization

### By Available RAM

| RAM Available | Recommended Quant | Example (7B Model) |
|---------------|-------------------|---------------------|
| 4 GB          | Q3_K_S / Q2_K     | ~2.5-3 GB           |
| 6 GB          | Q4_K_M            | ~4 GB               |
| 8 GB          | Q5_K_M / Q6_K     | ~5-6 GB             |
| 12+ GB        | Q8_0 / F16        | ~7-14 GB            |

### By Use Case

| Use Case              | Recommended | Reason                          |
|-----------------------|-------------|---------------------------------|
| General chat          | Q4_K_M      | Good balance                    |
| Creative writing      | Q5_K_M+     | Higher quality output           |
| Code generation       | Q5_K_M+     | Precision matters               |
| Embeddings            | Q8_0 / F16  | Accuracy critical               |
| Mobile/Edge           | Q3_K_M      | Size constrained                |
| Production API        | Q5_K_M      | Quality + performance           |

---

## Model Loading Parameters

### llama-cli Examples

```bash
# Load Q4_K_M model with full GPU offload
llama-cli -m model-q4_k_m.gguf -ngl 99 -c 4096 -t 8

# Load Q5_K_M with partial GPU offload
llama-cli -m model-q5_k_m.gguf -ngl 35 -c 8192

# CPU-only with Q3_K_M (low RAM)
llama-cli -m model-q3_k_m.gguf -t 8 --mlock
```

### llama-server Examples

```bash
# API server with Q4_K_M
llama-server -m model-q4_k_m.gguf -ngl 99 --port 8080

# Multi-GPU with Q5_K_M
llama-server -m model-q5_k_m.gguf --split-mode layer -ts 16,16 --port 8080
```

---

## Performance Comparison

### Inference Speed (tokens/sec, approximate)

| Quant    | CPU (8 threads) | GPU (RTX 3090) | Memory Bandwidth |
|----------|-----------------|----------------|------------------|
| F16      | ~5 t/s          | ~80 t/s        | 2x               |
| Q8_0     | ~8 t/s          | ~100 t/s       | 1.5x             |
| Q5_K_M   | ~10 t/s         | ~120 t/s       | 1.2x             |
| Q4_K_M   | ~12 t/s         | ~140 t/s       | 1x (baseline)    |
| Q3_K_M   | ~15 t/s         | ~160 t/s       | 0.8x             |
| Q2_K     | ~18 t/s         | ~180 t/s       | 0.6x             |

*Note: Speed varies by hardware and model architecture*

---

## Common Issues

### "Model too large for RAM"

**Solution**: Use lower quantization or enable memory mapping:
```bash
llama-cli -m model.gguf --mmap --mlock
```

### "CUDA out of memory"

**Solution**: Reduce GPU layers:
```bash
llama-cli -m model.gguf -ngl 20  # Instead of 99
```

### Quality degradation after quantization

**Solution**: Use higher quantization or importance matrix:
```bash
# Use Q5_K_M instead of Q4_K_M
# Or generate imatrix for better quantization
llama-imatrix -m model.gguf -f data.txt -o imatrix.dat
llama-quantize model.gguf out.gguf Q4_K_M --imatrix imatrix.dat
```

---

## Best Practices

1. **Start with Q4_K_M** - Best balance for most use cases
2. **Use Q5_K_M for quality-critical tasks** - Code, reasoning, creative work
3. **Avoid Q2_K unless necessary** - Significant quality loss
4. **Test multiple quantizations** - Compare output quality for your use case
5. **Use importance matrix for custom quantization** - Better results
6. **Keep FP16 original for re-quantization** - Don't re-quantize quantized models

---

## Resources

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
- [GGUF Format Specification](https://github.com/ggerganov/llama.cpp/blob/master/docs/gguf.md)
- [HuggingFace GGUF Models](https://huggingface.co/models?library=gguf)
- [Quantization Comparison](https://github.com/ggerganov/llama.cpp#quantization)

---

## Quick Reference

```
Best Overall:     Q4_K_M (balance) / Q5_K_M (quality)
Smallest Usable:  Q3_K_M
Largest Quality:  Q6_K / Q8_0
Avoid:            Q2_K (unless absolutely necessary)

Rule of Thumb: 
- 4GB RAM  → Q3_K_M
- 6GB RAM  → Q4_K_M  
- 8GB RAM  → Q5_K_M
- 12GB+    → Q6_K / Q8_0
```
