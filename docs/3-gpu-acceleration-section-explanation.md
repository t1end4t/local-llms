# GPU Acceleration Section Explanation

The **GPU Acceleration** section covers parameters that control how the model runs on GPU.

## Parameters

| Flag                            | Description                   | Default       |
|---------------------------------|-------------------------------|---------------|
| `-ngl, --n-gpu-layers N`        | Layers offload to GPU         | auto          |
| `--gpu-layers all`              | Offload all layers            | -             |
| `--split-mode {none,layer,row}` | Multi-GPU strategy            | layer         |
| `-ts, --tensor-split N0,N1,...` | GPU memory split              | -             |
| `-mg, --main-gpu INDEX`         | Primary GPU                   | 0             |
| `--list-devices`                | List available GPUs           | -             |

## Key Concepts

**n-gpu-layers** controls how many model layers are loaded onto GPU. More layers = better performance but higher VRAM usage. Set to `all` to offload everything.

**split-mode** determines how the model is distributed across multiple GPUs:
- `none`: Single GPU only
- `layer`: Split layers across GPUs (most common)
- `row`: Split attention heads across GPUs (for very large models)

**tensor-split** allows fine-grained control over which GPU handles which portions of the model weights.

## When to Use Each Parameter

### n-gpu-layers
```bash
# Offload all layers to GPU (best performance)
llama-cli -m model.gguf -ngl all

# Offload 32 layers to GPU
llama-cli -m model.gguf -ngl 32

# CPU only (no GPU)
llama-cli -m model.gguf -ngl 0
```

### split-mode
```bash
# Split layers across GPUs (default)
llama-cli -m model.gguf --split-mode layer

# Split by rows (for large models with multiple GPUs)
llama-cli -m model.gguf --split-mode row

# Single GPU only
llama-cli -m model.gguf --split-mode none
```

### tensor-split
```bash
# Split memory 60/40 between two GPUs
llama-cli -m model.gguf -ts 6,4

# Three GPUs with custom ratios
llama-cli -m model.gguf -ts 5,3,2
```

### main-gpu
```bash
# Use second GPU as main
llama-cli -m model.gguf -mg 1
```

### list-devices
```bash
# See available GPUs and their info
llama-cli --list-devices
```
