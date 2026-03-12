# Context & RoPE Scaling Section Explanation

The **Context & RoPE Scaling** section covers parameters for extending context length and positional encoding.

## Parameters

| Flag                                | Description              | Default        |
|-------------------------------------|--------------------------|----------------|
| `--rope-scaling {none,linear,yarn}` | RoPE scaling             | linear         |
| `--rope-scale N`                    | Scale factor             | -              |
| `--rope-freq-base N`                | RoPE base frequency      | Model default  |
| `--yarn-orig-ctx N`                 | YaRN original context    | Model default  |

## Key Concepts

**RoPE** (Rotary Position Embedding): How the model understands token positions. Scaling extends context beyond what model was trained on.

**Linear scaling**: Simple extension - doubles context by halving position frequencies.

**YaRN** (Yet another RoPE extension): Better quality extension, more accurate but slower.

## When to Use Each Parameter

### RoPE Scaling
```bash
# Double context size (e.g., 4096 -> 8192)
llama-cli -m model.gguf -c 8192 --rope-scaling linear --rope-scale 2.0

# Use YaRN for better quality at extended context
llama-cli -m model.gguf -c 16384 --rope-scaling yarn --rope-scale 4.0

# No scaling (use model's original context)
llama-cli -m model.gguf --rope-scaling none
```

### RoPE Frequency Base
```bash
# Set custom base frequency (usually for fine-tuning)
llama-cli -m model.gguf --rope-freq-base 10000.0
```

### YaRN Original Context
```bash
# Tell model original training context for YaRN
llama-cli -m model.gguf -c 32768 --rope-scaling yarn --yarn-orig-ctx 4096
```