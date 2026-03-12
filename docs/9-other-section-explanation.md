# Other Section Explanation

The **Other** section covers miscellaneous parameters that don't fit in other categories.

## Parameters

| Flag                  | Description                | Default    |
|-----------------------|----------------------------|------------|
| `-h, --help`          | Show help                  | -          |
| `--version`           | Show version               | -          |
| `--perf`              | Show performance metrics   | false      |
| `--show-timings`      | Show timing info           | true       |
| `--log-file FNAME`    | Log to file                | -          |

## When to Use Each Parameter

### Help / Version
```bash
# Show all available options
llama-cli --help
llama-cli -h

# Show version info
llama-cli --version
```

### Performance Metrics
```bash
# Show detailed performance stats after generation
llama-cli -m model.gguf -p "Hello" --perf

# Output includes: tokens/sec, memory usage, timing
```

### Show Timings
```bash
# Show timing information (default)
llama-cli -m model.gguf --show-timings

# Hide timing info
llama-cli -m model.gguf --no-show-timings
```

### Log File
```bash
# Save output to file
llama-cli -m model.gguf -p "Hello" --log-file output.log

# Useful for saving conversations
llama-cli -m model.gguf -cnv --log-file chat.log
```