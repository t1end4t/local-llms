# Chat/Conversation Section Explanation

The **Chat/Conversation** section covers parameters for interactive chat and conversation handling.

## Parameters

| Flag                           | Description                  | Default           |
|--------------------------------|------------------------------|-------------------|
| `-sys, --system-prompt PROMPT` | System message               | -                 |
| `--chat-template TEMPLATE`     | Chat template                | Model default     |
| `--reasoning-format FORMAT`    | Reasoning output             | auto              |
| `--reasoning-budget N`         | Thinking budget              | -1                |
| `-cnv, --conversation`         | Conversation mode            | auto              |
| `-sp, --special`               | Enable special tokens        | false             |

## Key Concepts

**System prompt**: Sets AI personality/behavior. Applied before conversation.

**Chat template**: Converts conversation to model format. Different models use different templates.

**Reasoning format**: Controls how reasoning models (like Qwen3.5 with thinking) display output.

## When to Use Each Parameter

### System Prompt
```bash
# Set AI personality
llama-cli -m model.gguf -sys "You are a helpful coding assistant."

# Set detailed instructions
llama-cli -m model.gguf --system-prompt "You are an expert in Python. Write clear, well-documented code."
```

### Chat Template
```bash
# Use specific template (e.g., chatml, llama3, etc.)
llama-cli -m model.gguf --chat-template chatml

# Auto-detect (default)
llama-cli -m model.gguf --chat-template auto
```

### Conversation Mode
```bash
# Enable multi-turn conversation (keeps history)
llama-cli -m model.gguf -cnv

# Single prompt only (no history)
llama-cli -m model.gguf
```

### Reasoning Format
```bash
# Show thinking process (for reasoning models)
llama-cli -m model.gguf --reasoning-format think

# Hide thinking, show only final answer
llama-cli -m model.gguf --reasoning-format hidden

# Auto-detect
llama-cli -m model.gguf --reasoning-format auto
```

### Reasoning Budget
```bash
# Limit thinking tokens (e.g., 512 tokens)
llama-cli -m model.gguf --reasoning-budget 512

# Unlimited thinking
llama-cli -m model.gguf --reasoning-budget -1
```

### Special Tokens
```bash
# Enable special tokens manually
llama-cli -m model.gguf -sp
```