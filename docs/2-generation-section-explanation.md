# Generation Section Explanation

The **Generation** section covers parameters that control token generation and processing behavior.

## Parameters

| Flag                      | Description                                   | Default          |
|---------------------------|-----------------------------------------------|------------------|
| `-c, --ctx-size`          | Context size in tokens                        | Model default    |
| `-n, --predict`           | Max tokens to generate (-1 = unlimited)       | -1 (infinity)    |
| `-t, --threads`           | CPU threads for inference                     | -1 (auto)        |
| `-tb, --threads-batch`    | Threads for prompt processing                 | Same as -t       |
| `-b, --batch-size`        | Logical batch size for KV cache               | 2048             |
| `-ub, --ubatch-size`      | Physical batch size for computation           | 512              |
| `--keep`                  | Tokens to keep from prompt                    | 0 (all)          |

## Key Concepts

**ctx-size** determines how much memory the model uses and how long conversations can last before hitting the context limit.

**batch-size vs ubatch-size**: The batch-size is the logical size for the KV cache (how many tokens can be processed at once), while ubatch-size is the physical compute unit. Larger batches improve throughput but use more VRAM.

**threads**: Set to your physical CPU cores for best CPU performance.

**keep**: Useful when you want to truncate a very long prompt but retain part of it in context (e.g., keeping only the last N tokens of a long system prompt).

## When to Use Each Parameter

### ctx-size
```bash
# Long conversations need larger context
llama-cli -m model.gguf -c 8192

# Short tasks can use smaller context (saves memory)
llama-cli -m model.gguf -c 2048
```

### predict
```bash
# Generate short responses
llama-cli -m model.gguf -n 100

# Generate long content (use with caution - can run forever)
llama-cli -m model.gguf -n 4096
```

### threads
```bash
# Use 8 CPU threads
llama-cli -m model.gguf -t 8

# Auto-detect optimal threads
llama-cli -m model.gguf -t -1
```

### batch-size / ubatch-size
```bash
# Higher throughput (requires more VRAM)
llama-cli -m model.gguf -b 4096 -ub 1024

# Lower memory usage
llama-cli -m model.gguf -b 512 -ub 128
```

### keep
```bash
# Keep only last 500 tokens from prompt (saves context for conversation)
llama-cli -m model.gguf --keep 500
```