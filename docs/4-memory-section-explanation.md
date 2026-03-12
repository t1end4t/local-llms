# Memory Section Explanation

The **Memory** section covers parameters that control how the model is loaded into memory.

## Parameters

| Flag              | Description                | Default    |
|-------------------|----------------------------|------------|
| `--mlock`         | Lock model in RAM          | -          |
| `--mmap`          | Memory-map model           | enabled    |
| `--no-mmap`       | Disable memory-mapping     | -          |
| `--numa TYPE`     | NUMA optimization          | -          |

## Key Concepts

**mmap** (memory-mapping): Loads model on-demand rather than all at once. Default is enabled - good for large models with limited RAM.

**mlock**: Forces model to stay in RAM, preventing swapping to disk. Useful when you have enough RAM.

**numa**: Optimizes memory access on multi-socket systems (servers with 2+ CPUs).

## When to Use Each Parameter

### mmap / no-mmap
```bash
# Default: use memory mapping (saves RAM)
llama-cli -m model.gguf --mmap

# Disable memory mapping (load everything into RAM)
llama-cli -m model.gguf --no-mmap

# Better for systems with plenty of RAM
llama-cli -m model.gguf --no-mmap --mlock
```

### mlock
```bash
# Lock model in RAM (prevent swapping - useful with enough RAM)
llama-cli -m model.gguf --mlock
```

### numa
```bash
# Distribute memory across NUMA nodes (for multi-CPU servers)
llama-cli -m model.gguf --numa distribute

# Enable NUMA with binding
llama-cli -m model.gguf --numa enable

# Test NUMA performance
llama-cli -m model.gguf --numa analyze
```