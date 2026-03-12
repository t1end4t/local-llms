# Sampling (Generation Quality) Section Explanation

The **Sampling** section covers parameters that control output quality, randomness, and repetition.

## Parameters

| Flag                              | Description                   | Default    |
|-----------------------------------|-------------------------------|------------|
| `--temp N`                        | Temperature                   | 0.80       |
| `--top-k N`                       | Top-k sampling                | 40         |
| `--top-p N`                       | Top-p (nucleus) sampling      | 0.95       |
| `--min-p N`                       | Min-p sampling                | 0.05       |
| `--typical N`                     | Locally typical p             | 1.00       |
| `--repeat-last-n N`               | Repetition penalty window     | 64         |
| `--repeat-penalty N`              | Repeat penalty                | 1.00       |
| `--presence-penalty N`            | Presence penalty              | 0.00       |
| `--frequency-penalty N`           | Frequency penalty             | 0.00       |
| `--mirostat N`                    | Mirostat (0/1/2)              | 0          |
| `-l, --logit-bias TOKEN_ID(+/-)BIAS` | Token bias                 | -          |

## Key Concepts

**Temperature**: Controls randomness. Lower = more deterministic, higher = more creative/random.

**Top-k**: Limits to k most likely tokens. Lower = more focused, higher = more diverse.

**Top-p (nucleus)**: Dynamically selects tokens that sum to p probability. Works with top-k.

**Min-p**: Sets minimum probability threshold relative to top token. Prevents very unlikely tokens.

**Repeat penalty**: Reduces repetition of previously generated tokens.

## When to Use Each Parameter

### Temperature
```bash
# Deterministic (factual, coding)
llama-cli -m model.gguf --temp 0.1

# Balanced (default)
llama-cli -m model.gguf --temp 0.8

# Creative (storytelling, brainstorming)
llama-cli -m model.gguf --temp 1.2
```

### Top-k / Top-p
```bash
# Focus on most likely tokens (accurate)
llama-cli -m model.gguf --top-k 10 --top-p 0.9

# More diverse (creative)
llama-cli -m model.gguf --top-k 100 --top-p 1.0

# Only tokens > 10% of top token probability
llama-cli -m model.gguf --min-p 0.1
```

### Repetition Penalty
```bash
# Reduce repetition
llama-cli -m model.gguf --repeat-penalty 1.2

# Larger context window for repetition detection
llama-cli -m model.gguf --repeat-last-n 128
```

### Logit Bias
```bash
# Increase likelihood of token ID 12345
llama-cli -m model.gguf -l 12345+1.0

# Decrease likelihood of token ID 67890
llama-cli -m model.gguf -l 67890-5.0
```

### Mirostat
```bash
# Use Mirostat 2 (adaptive sampling)
llama-cli -m model.gguf --mirostat 2
```