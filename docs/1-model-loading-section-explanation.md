# Model Loading Section Explanation

The **Model Loading** section covers parameters for specifying which model to use and how to load it.

## Parameters

| Flag                                    | Description             | Default   |
|-----------------------------------------|-------------------------|-----------|
| `-m, --model FNAME`                     | Path to model file      | Required  |
| `-mu, --model-url URL`                  | Download model from URL | -         |
| `-hf, --hf-repo <user>/<model>[:quant]` | HuggingFace repo        | -         |
| `--lora FNAME`                          | LoRA adapter path       | -         |
| `--lora-scaled FNAME:SCALE`             | LoRA with scaling       | -         |
| `--mmproj FILE`                         | Multimodal projector    | -         |

## Key Concepts

**Model**: The main GGUF file to load. Can be local path or downloaded.

**LoRA**: Lightweight adapters that modify model behavior without changing the base model.

**mmproj**: Multimodal projector - needed for vision models (like LLaVA).

## When to Use Each Parameter

### Model Loading
```bash
# Basic usage (local file)
llama-cli -m models/qwen/Qwen3.5-0.8B-Q5_K_M.gguf

# Download from URL
llama-cli -m model.gguf -mu https://example.com/model.gguf

# Download from HuggingFace
llama-cli -m model.gguf -hf user/model-name:Q5_K_M
```

### LoRA Adapters
```bash
# Apply LoRA adapter
llama-cli -m model.gguf --lora adapter-lora.gguf

# Apply LoRA with custom scaling
llama-cli -m model.gguf --lora-scaled adapter-lora.gguf:1.5
```

### Multimodal (Vision)
```bash
# Load vision model with projector
llama-cli -m model.gguf --mmproj mmproj.bin
```