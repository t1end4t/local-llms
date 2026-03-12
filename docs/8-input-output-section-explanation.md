# Input/Output Section Explanation

The **Input/Output** section covers parameters for how prompts are read and output is displayed.

## Parameters

| Flag                  | Description                | Default    |
|-----------------------|----------------------------|------------|
| `-p, --prompt PROMPT` | Input prompt               | -          |
| `-f, --file FNAME`    | Prompt from file           | -          |
| `-e, --escape`        | Process escape sequences   | true       |
| `--color`             | Colorize output            | auto       |
| `--verbose-prompt`    | Print verbose prompt       | false      |

## Key Concepts

**Prompt**: The input text to the model. Can be passed directly or from a file.

**Escape sequences**: Process `\n`, `\t`, etc. in prompts.

**Verbose prompt**: Shows how the prompt is formatted after applying chat template.

## When to Use Each Parameter

### Prompt
```bash
# Simple completion
llama-cli -m model.gguf -p "Write a poem about AI"

# Interactive mode (no prompt = interactive chat)
llama-cli -m model.gguf
```

### File Input
```bash
# Read prompt from file
llama-cli -m model.gguf -f prompt.txt

# Useful for long prompts
llama-cli -m model.gguf -f long-prompt.txt
```

### Escape
```bash
# Process escape sequences (default)
llama-cli -m model.gguf -e

# Don't process escape sequences
llama-cli -m model.gguf --no-escape
```

### Color
```bash
# Auto-detect color support
llama-cli -m model.gguf --color auto

# Force color output
llama-cli -m model.gguf --color

# Disable color
llama-cli -m model.gguf --color false
```

### Verbose Prompt
```bash
# Show formatted prompt (useful for debugging)
llama-cli -m model.gguf --verbose-prompt -p "Hello"
```