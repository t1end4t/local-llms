# Model Selection and Trade-offs

This guide covers how to choose the right LLM for your local deployment, considering size, quantization, and performance trade-offs.

## Key Considerations

### 1. Model Size

Model size directly impacts:
- **VRAM/RAM requirements**: Larger models need more memory
- **Inference speed**: Smaller models generate tokens faster
- **Quality**: Larger models generally produce better outputs

#### Size Categories

| Category | Parameters | VRAM Required (FP16) | VRAM Required (Q4_K_M) | Use Case |
|----------|-----------|---------------------|----------------------|----------|
| Tiny | 1B - 3B | 2-6 GB | 1-2 GB | Edge devices, rapid prototyping |
| Small | 7B - 9B | 14-18 GB | 4-6 GB | General tasks, coding assistance |
| Medium | 13B - 20B | 26-40 GB | 8-12 GB | Complex reasoning, better quality |
| Large | 30B - 70B | 60-140 GB | 16-40 GB | High-quality outputs, research |

**For RTX 3060 12GB:**
- **Sweet spot**: 7B-13B models with Q4_K_M or Q5_K_M quantization
- **Maximum**: Up to 20B with aggressive quantization (Q3_K_M)

### 2. Quantization Types

Quantization reduces model precision to decrease size and memory usage.

#### GGUF Quantization Formats

| Format | Bits | Size Reduction | Quality Loss | Best For |
|--------|------|----------------|--------------|----------|
| Q2_K | ~2.5 | ~75% | Noticeable | Extremely limited VRAM |
| Q3_K_M | ~3.5 | ~65% | Moderate | Balance on 6-8GB cards |
| Q4_K_M | ~4.5 | ~55% | Minimal | **Recommended for most** |
| Q5_K_M | ~5.5 | ~45% | Very slight | Quality-focused |
| Q6_K | ~6.5 | ~35% | Negligible | Near-lossless |
| Q8_0 | ~8 | ~25% | None | Maximum quality |
| F16 | 16 | None | None | Reference/research |

#### Naming Convention
- `Q` = Quantized
- Number = Approximate bits per weight
- `K` = K-quants (newer, better quality)
- `M`/`S`/`L` = Medium/Small/Large (within same bit level)

### 3. Popular Model Families

#### Llama 3.x (Meta)
- **Llama-3.2-3B**: Excellent for constrained VRAM
- **Llama-3.2-7B**: Best balance for 12GB cards
- **Llama-3.1-8B**: Strong general-purpose model
- **Llama-3.1-70B**: Requires heavy quantization for consumer GPUs

#### Mistral/Mixtral
- **Mistral-7B**: Efficient, strong performance
- **Mixtral-8x7B**: MoE architecture, ~13B active params, needs ~20GB VRAM (Q4)

#### Phi-3 (Microsoft)
- **Phi-3-mini-3.8B**: Surprisingly capable for size
- **Phi-3-small-7B**: Good alternative to Llama
- **Phi-3-medium-14B**: Requires Q4_K_M for 12GB cards

#### Gemma 2 (Google)
- **Gemma-2-9B**: Strong competitor to Llama-3.1-8B
- **Gemma-2-27B**: Needs Q3_K_M for 12GB cards

## Practical Recommendations

### For RTX 3060 12GB

**Daily Driver:**
```
Model: Llama-3.2-7B-Instruct-GGUF
Quantization: Q4_K_M or Q5_K_M
VRAM Usage: ~5-6 GB
Context: Up to 8K-16K tokens
```

**Quality-Focused:**
```
Model: Llama-3.1-8B-Instruct-GGUF
Quantization: Q5_K_M or Q6_K
VRAM Usage: ~6-8 GB
Context: Up to 8K tokens
```

**Maximum Size:**
```
Model: Llama-3.1-70B-Instruct-GGUF
Quantization: Q3_K_M or Q2_K
VRAM Usage: ~12 GB (full)
Context: Limited (2K-4K)
Note: Will use system RAM + GPU offload, slower
```

## Where to Find Models

### Hugging Face Repositories

1. **TheBloke** (now merged into other uploaders)
   - Historically the most popular GGUF provider
   
2. **Bartowski**
   - Active uploader, wide variety of models
   
3. **MaziyarPanahi**
   - Quality GGUF conversions

4. **Official model authors**
   - Many now provide GGUF directly

### Search Tips
```
# Hugging Face search pattern
[model-name] GGUF
# Example: "Llama-3.2-7B-Instruct GGUF"

# Filter by file size
- Q4_K_M: ~4-5GB for 7B model
- Q5_K_M: ~5-6GB for 7B model
```

## Testing Strategy

1. **Start with Q4_K_M** - Best balance for most use cases
2. **Test Q5_K_M** - If you have VRAM headroom
3. **Try Q3_K_M** - If you need larger models or more context
4. **Benchmark your workload** - Quality is subjective

## Example Download Commands

```bash
# Using huggingface-cli
huggingface-cli download bartowski/Llama-3.2-7B-Instruct-GGUF \
  Llama-3.2-7B-Instruct-Q4_K_M.gguf \
  --local-dir ./models/Llama-3.2-7B-Instruct

# Using wget (direct from HF)
wget https://huggingface.co/bartowski/Llama-3.2-7B-Instruct-GGUF/resolve/main/Llama-3.2-7B-Instruct-Q4_K_M.gguf \
  -P ./models/
```

## Quick Reference: VRAM Calculator

Approximate VRAM needed:
```
VRAM (GB) = (Parameters in B × Bits per weight) / 8 + Context overhead

# Example: Llama-3.1-8B with Q4_K_M and 8K context
VRAM = (8 × 4.5) / 8 + 2 = 6.5 GB
```

Add 1-2 GB buffer for:
- KV cache (context)
- CUDA buffers
- System overhead

## Next Steps

- [Prompt Engineering Guide](./4-prompt-engineering-local-llms.md) - Learn to get better outputs
- [OpenAI API Setup](./5-openai-compatible-api.md) - Use with existing tools
