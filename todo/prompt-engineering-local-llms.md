# Prompt Engineering for Local LLMs

This guide covers prompt engineering techniques optimized for local LLM deployment with llama.cpp.

## Understanding Local LLM Characteristics

### Differences from Cloud APIs

| Aspect | Local LLMs | Cloud APIs (GPT-4, etc.) |
|--------|-----------|-------------------------|
| Model Size | 3B-70B | 100B+ (estimated) |
| Context Window | 4K-128K | 128K-1M+ |
| Instruction Following | Good, varies by model | Excellent |
| Temperature Sensitivity | Higher | Lower |
| System Prompt Support | Varies | Standardized |

### llama.cpp Specific Considerations

1. **Template Matters**: Each model uses a specific chat template
2. **No Built-in Safety**: Local models may have fewer guardrails
3. **Reproducibility**: Set `-s` (seed) for consistent outputs

## Chat Templates

### Llama 3.x Template

```
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

{system_message}<|eot_id|><|start_header_id|>user<|end_header_id|>

{user_message}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

{assistant_response}<|eot_id|>
```

### Mistral Template

```
<s>[INST] {system_message}

{user_message} [/INST] {assistant_response}</s>
```

### Using Templates with llama.cpp

```bash
# llama.cpp auto-detects template from GGUF metadata
./llama-cli -m model.gguf \
  --conversation \
  -p "You are a helpful assistant" \
  --temp 0.7
```

## Core Prompting Techniques

### 1. Clear Instructions

**❌ Vague:**
```
Tell me about Python.
```

**✅ Specific:**
```
Explain Python decorators to a beginner programmer. 
Include:
- What problem they solve
- Basic syntax with one example
- Common use cases
Keep it under 300 words.
```

### 2. Role Prompting

```
You are a senior software engineer with expertise in 
distributed systems and Python. Review the following 
code for:
1. Performance bottlenecks
2. Potential bugs
3. Best practices violations

Provide specific, actionable feedback.
```

### 3. Few-Shot Examples

```
Classify the sentiment of these reviews:

Review: "The product works great but setup was confusing."
Sentiment: Mixed (positive about product, negative about setup)

Review: "Absolutely love it! Best purchase this year."
Sentiment: Positive

Review: "Stopped working after 2 days. Very disappointed."
Sentiment: Negative

Review: "It's okay, nothing special but does the job."
Sentiment: 
```

### 4. Chain of Thought

```
Question: A bat and ball cost $1.10 together. The bat 
costs $1.00 more than the ball. How much does the ball cost?

Let's think step by step:
1. Define variables: ball = x, bat = x + 1.00
2. Set up equation: x + (x + 1.00) = 1.10
3. Simplify: 2x + 1.00 = 1.10
4. Solve: 2x = 0.10, x = 0.05
5. Verify: ball = $0.05, bat = $1.05, total = $1.10 ✓

Answer: The ball costs $0.05.
```

### 5. Output Formatting

```
Extract all product names and prices from this text.
Format as a JSON array of objects with "name" and "price" fields.

Text: "We have the iPhone 15 for $999, the Samsung Galaxy 
S24 for $849, and the Google Pixel 8 for $699."

Response:
```

## llama.cpp Generation Parameters

### Temperature (`--temp`)

Controls randomness in output.

```bash
# Deterministic, factual responses
--temp 0.2

# Balanced, creative but coherent
--temp 0.7

# Highly creative, unpredictable
--temp 1.2
```

### Top-P (`--top-p`)

Nucleus sampling - consider only top tokens summing to P probability.

```bash
# Focused, narrow consideration
--top-p 0.8

# Standard (recommended)
--top-p 0.9

# More diverse outputs
--top-p 0.95
```

### Repeat Penalty (`--repeat-penalty`)

Discourages repetition.

```bash
# Standard
--repeat-penalty 1.1

# Aggressive (for verbose models)
--repeat-penalty 1.5

# Lenient (for technical content)
--repeat-penalty 1.0
```

### Context Size (`-c`)

```bash
# Default
-c 512

# Medium documents
-c 4096

# Long documents
-c 16384

# Maximum (model dependent)
-c 32768
```

## Practical Prompt Patterns

### Code Generation

```
You are an expert Python developer. Write a function that:
- Takes a list of dictionaries
- Groups them by a specified key
- Returns a dictionary of lists

Requirements:
- Include type hints
- Add docstring with examples
- Handle edge cases (empty list, missing key)
- Use standard library only

Function signature:
def group_by_key(items: list[dict], key: str) -> dict[str, list]:
```

### Document Summarization

```
Summarize the following article in exactly 3 bullet points.
Each bullet should be one sentence.
Focus on the main argument and key evidence.

[Article text here]
```

### Question Answering

```
Answer the following question based ONLY on the provided context.
If the answer is not in the context, say "I don't have enough information."

Context: {paste relevant text}

Question: {your question}

Answer:
```

### Data Extraction

```
Extract structured information from this text.
Format as JSON with these fields:
- company_name (string)
- founded_year (number)
- headquarters (string)
- products (array of strings)

Text: {your text}
```

### Creative Writing

```
Write a short story (500-700 words) in the style of cyberpunk noir.

Setting: A rain-soaked megacity in 2087
Protagonist: A memory archaeologist who discovers a conspiracy
Tone: Melancholic but hopeful
Include: One plot twist, vivid sensory details

Start with: "The data-ghost appeared at 3 AM..."
```

## Common Issues and Solutions

### Issue: Model Ignores Instructions

**Solution:**
1. Move important instructions to the end
2. Use explicit formatting markers
3. Add "Think step by step"

### Issue: Verbose Outputs

**Solution:**
```
Be concise. Answer in 2-3 sentences maximum.
```

Or use `--mirostat` for automatic length control:
```bash
./llama-cli -m model.gguf --mirostat 2 --mirostat-ent 3.0
```

### Issue: Hallucinations

**Solution:**
1. Provide more context
2. Add "If unsure, say so" instruction
3. Lower temperature (`--temp 0.3`)
4. Use `--repeat-penalty 1.2`

### Issue: Inconsistent Formatting

**Solution:**
```
Respond ONLY with valid JSON. No explanations, no markdown.
Example: {"result": "value"}
```

## Advanced Techniques

### System Prompt Optimization

```bash
# Set a strong system prompt
./llama-cli -m model.gguf \
  --system-prompt "You are a precise, factual assistant. 
  Always cite sources when available. Admit uncertainty."
```

### Multi-Turn Conversations

Maintain context across turns:
```bash
./llama-cli -m model.gguf \
  --conversation \
  -c 8192 \
  --temp 0.7
```

### Constrained Generation

```bash
# Stop at specific tokens
./llama-cli -m model.gguf \
  --stop "###" \
  --stop "User:" \
  --stop "</s>"

# Limit output length
./llama-cli -m model.gguf \
  -n 256  # Max 256 tokens
```

## Testing and Iteration

### A/B Test Prompts

```bash
# Test prompt A
./llama-cli -m model.gguf -p "Prompt A..." -s 42 > output_a.txt

# Test prompt B
./llama-cli -m model.gguf -p "Prompt B..." -s 42 > output_b.txt

# Compare
diff output_a.txt output_b.txt
```

### Parameter Sweeps

```bash
# Test different temperatures
for temp in 0.3 0.5 0.7 0.9; do
  ./llama-cli -m model.gguf --temp $temp -p "Your prompt" \
    > output_t${temp}.txt
done
```

## Quick Reference Card

```
┌─────────────────────────────────────────────────────┐
│ Prompt Engineering Quick Reference                  │
├─────────────────────────────────────────────────────┤
│ Be specific and explicit                            │
│ Use examples (few-shot)                             │
│ Chain of thought for reasoning                      │
│ Define output format                                │
│ Set appropriate temperature                         │
│ Use system prompts for persona                      │
│ Add constraints (length, style, format)             │
│ Test and iterate                                    │
└─────────────────────────────────────────────────────┘
```

## Related Documentation

- [Model Selection](./3-model-selection-tradeoffs.md) - Choose the right model
- [OpenAI API Setup](./5-openai-compatible-api.md) - Integrate with tools
