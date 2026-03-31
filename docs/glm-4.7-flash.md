# GLM-4.7-Flash — Setup & Reference

> Source: https://unsloth.ai/docs/models/glm-4.7-flash  
> Architecture: 30B MoE, ~3.6B active params, 200K context window

---

## Model Files

| Quant | Use Case | Notes |
|---|---|---|
| `UD-Q4_K_XL` | **Recommended** | Best quality/size tradeoff per Unsloth |
| `Q4_K_M` | Alternative | ~18.3GB, slightly lower quality |
| `Q2_K_XL` | VRAM constrained | Smaller but quality degrades |

Download repo: `unsloth/GLM-4.7-Flash-GGUF`

```bash
./scripts/download-model.sh
```

---

## Running with llama-server

```bash
./scripts/run-glm.sh
```

API available at `http://127.0.0.1:8001/v1` (OpenAI-compatible).

### Manual flags reference

```bash
llama-server \
  --model models/GLM-4.7-Flash-UD-Q4_K_XL.gguf \
  --alias "unsloth/GLM-4.7-Flash" \
  --ctx-size 16384 \
  --gpu-layers -1 \
  --flash-attn on \
  --no-mmap \
  --seed 3407 \
  --temp 1.0 \
  --top-p 0.95 \
  --min-p 0.01 \
  --repeat-penalty 1.0       # CRITICAL: must disable repeat penalty
```

### RTX 3060 12GB: expert offload (model > 12GB)

If model doesn't fully fit in VRAM, offload MoE experts to CPU RAM:

```bash
llama-server \
  --model models/GLM-4.7-Flash-UD-Q4_K_XL.gguf \
  --gpu-layers -1 \
  --n-cpu-moe 35 \
  --no-mmap \
  --flash-attn on \
  --repeat-penalty 1.0
```

---

## Sampling Parameters

| Use Case | temp | top-p | min-p | repeat-penalty |
|---|---|---|---|---|
| General chat | 1.0 | 0.95 | 0.01 | **1.0 (disabled)** |
| Tool calling | 0.7 | 1.0 | 0.01 | **1.0 (disabled)** |

**Do NOT use Ollama** — chat template compatibility issues reported.

---

## Tool Calling

The model supports OpenAI-compatible function calling out of the box.
Pass tools as JSON in the API request — the model parses and calls them automatically.

Example Python client:

```python
from openai import OpenAI

client = OpenAI(base_url="http://127.0.0.1:8001/v1", api_key="none")

tools = [{
    "type": "function",
    "function": {
        "name": "add",
        "description": "Add two numbers",
        "parameters": {
            "type": "object",
            "properties": {
                "a": {"type": "number"},
                "b": {"type": "number"}
            },
            "required": ["a", "b"]
        }
    }
}]

response = client.chat.completions.create(
    model="unsloth/GLM-4.7-Flash",
    messages=[{"role": "user", "content": "What is 3 + 5?"}],
    tools=tools,
    temperature=0.7,
    extra_body={"repeat_penalty": 1.0, "min_p": 0.01}
)
```

---

## Fine-tuning (Future)

- Requires **Transformers v5**
- ~60GB VRAM for 16-bit LoRA (H100/A100 80GB recommended)
- **Do not fine-tune the router layer** (disabled by default in Unsloth notebook)
- Dataset composition: **≥75% reasoning + ≤25% non-reasoning** examples
- Unsloth provides a GLM-4.7-Flash SFT LoRA Colab notebook

---

## Known Issues / Tips

- **Jan 21 fix**: GGUF files were reuploaded after a `scoring_func` bug (`softmax` → `sigmoid`) caused looping outputs. If you have old GGUFs, redownload.
- **repeat-penalty**: Must be `1.0` (disabled). Non-1.0 values cause degenerate output.
- **Context**: 200K max, but use 16K–32K for RTX 3060 to manage VRAM.
- **--no-mmap**: Required for MoE models to avoid slow random access.
