# Benchmarking Local LLM Performance

This guide covers how to benchmark and measure the performance of your local LLM setup with llama.cpp.

## Key Performance Metrics

### 1. Tokens Per Second (t/s)

**Definition**: Number of tokens generated per second.

**What it measures**: Raw generation speed.

**Good values** (for RTX 3060 12GB):
- 7B model: 40-60 t/s
- 13B model: 20-35 t/s
- 70B model: 5-10 t/s (with CPU offload)

### 2. Time to First Token (TTFT)

**Definition**: Time from request start to first token output.

**What it measures**: Initial latency, important for streaming.

**Good values**: < 500ms for small models, < 2s for large models

### 3. Context Processing Speed

**Definition**: Tokens per second when processing input (prompt evaluation).

**What it measures**: How fast the model reads your input.

**Good values**: 100-500 t/s (much faster than generation)

### 4. Memory Usage

**Definition**: VRAM and RAM consumption.

**What it measures**: Resource efficiency, headroom for context.

### 5. Quality Metrics

- Coherence and relevance
- Instruction following
- Factual accuracy
- Consistency across runs

## Built-in Benchmarking Tools

### llama-bench

llama.cpp includes a built-in benchmarking tool:

```bash
# Run comprehensive benchmark
./llama-bench -m ./models/your-model.gguf

# Quick benchmark
./llama-bench -m ./models/your-model.gguf -n 128

# Test different batch sizes
./llama-bench -m ./models/your-model.gguf -b 256,512,1024

# Full GPU offload test
./llama-bench -m ./models/your-model.gguf -ngl 99
```

**Sample Output:**
```
| Model | Size | Quant | PP (t/s) | TG (t/s) | Memory |
|-------|------|-------|----------|----------|--------|
| Llama-3.2-7B | 7B | Q4_K_M | 312.5 | 52.3 | 4.2 GB |

PP = Prompt Processing (input)
TG = Token Generation (output)
```

### llama-cli with Timing

```bash
# Enable verbose timing
./llama-cli -m model.gguf \
  -p "Write a story about a robot" \
  -n 256 \
  --temp 0.7 \
  -v

# Look for timing info in output:
# eval time:  1234.56 ms /   128 tokens =    9.65 ms/token =  103.65 t/s
# sample time:   12.34 ms /    128 runs   =    0.10 ms/run
```

## Custom Benchmarking Scripts

### Python Benchmark Script

```python
#!/usr/bin/env python3
"""
LLM Performance Benchmark
"""

import time
import statistics
from openai import OpenAI

def benchmark_llm(
    base_url="http://localhost:8080/v1",
    model="local-model",
    prompt_length=100,
    output_length=256,
    iterations=5
):
    client = OpenAI(base_url=base_url, api_key="not-needed")
    
    # Generate test prompt
    prompt = "x" * prompt_length
    
    results = {
        'ttft': [],
        'generation_speed': [],
        'total_time': []
    }
    
    for i in range(iterations):
        print(f"Iteration {i+1}/{iterations}...")
        
        start = time.time()
        first_token = False
        
        response = client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            max_tokens=output_length,
            stream=True
        )
        
        for chunk in response:
            if not first_token and chunk.choices[0].delta.content:
                ttft = time.time() - start
                results['ttft'].append(ttft)
                first_token = True
        
        total_time = time.time() - start
        results['total_time'].append(total_time)
        results['generation_speed'].append(output_length / total_time)
    
    # Print results
    print("\n" + "="*50)
    print("BENCHMARK RESULTS")
    print("="*50)
    print(f"Prompt length: {prompt_length} tokens")
    print(f"Output length: {output_length} tokens")
    print(f"Iterations: {iterations}")
    print("-"*50)
    print(f"Time to First Token: {statistics.mean(results['ttft']):.3f}s "
          f"(±{statistics.stdev(results['ttft']):.3f})")
    print(f"Generation Speed: {statistics.mean(results['generation_speed']):.2f} t/s "
          f"(±{statistics.stdev(results['generation_speed']):.2f})")
    print(f"Total Time: {statistics.mean(results['total_time']):.3f}s "
          f"(±{statistics.stdev(results['total_time']):.3f})")
    print("="*50)
    
    return results

if __name__ == "__main__":
    benchmark_llm()
```

### Batch Benchmarking

```python
#!/usr/bin/env python3
"""
Compare multiple models or configurations
"""

import subprocess
import json
from datetime import datetime

MODELS = [
    "Llama-3.2-7B-Q4_K_M.gguf",
    "Llama-3.2-7B-Q5_K_M.gguf",
    "Llama-3.1-8B-Q4_K_M.gguf",
]

def run_llama_bench(model_path):
    cmd = [
        "./llama-bench",
        "-m", model_path,
        "-n", "128",
        "-ngl", "99"
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    return parse_output(result.stdout)

def parse_output(output):
    # Parse llama-bench output
    # Extract t/s values
    for line in output.split('\n'):
        if 'tokens' in line:
            # Extract timing info
            pass
    return {}

def main():
    results = []
    
    for model in MODELS:
        print(f"Benchmarking {model}...")
        result = run_llama_bench(f"./models/{model}")
        result['model'] = model
        results.append(result)
    
    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    with open(f"benchmark_results_{timestamp}.json", 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"Results saved to benchmark_results_{timestamp}.json")

if __name__ == "__main__":
    main()
```

## System Monitoring

### GPU Monitoring

```bash
# Real-time GPU monitoring
watch -n 0.5 nvidia-smi

# Log GPU usage during benchmark
nvidia-smi --query-gpu=timestamp,name,utilization.gpu,utilization.memory,memory.used \
  --format=csv -l 1 > gpu_log.csv
```

### Memory Monitoring

```bash
# Monitor VRAM usage
nvidia-smi --query-gpu=memory.total,memory.used,memory.free \
  --format=csv -l 2

# Monitor system RAM
watch -n 1 free -h
```

### Process Monitoring

```bash
# Monitor llama-server process
htop -p $(pgrep llama-server)

# Or with ps
ps -p $(pgrep llama-server) -o %CPU,%MEM,vsz,rss,time,cmd
```

## Comparative Benchmarks

### Model Comparison Matrix

Test different models with same prompt:

```bash
# Create test prompts
echo "Explain quantum entanglement in simple terms." > prompt.txt

# Test each model
for model in models/*.gguf; do
    echo "Testing $model..."
    ./llama-cli -m "$model" \
        -f prompt.txt \
        -n 256 \
        --temp 0.7 \
        -s 42 \
        --timing-per-token \
        2>&1 | tee "benchmark_$(basename $model .gguf).txt"
done
```

### Quantization Comparison

```bash
# Compare quantization levels for same model base
models=(
    "Llama-3.2-7B-Q2_K.gguf"
    "Llama-3.2-7B-Q3_K_M.gguf"
    "Llama-3.2-7B-Q4_K_M.gguf"
    "Llama-3.2-7B-Q5_K_M.gguf"
    "Llama-3.2-7B-Q6_K.gguf"
    "Llama-3.2-7B-Q8_0.gguf"
)

for model in "${models[@]}"; do
    echo "=== $model ==="
    ./llama-bench -m "models/$model" -n 128 -ngl 99 | grep "tokens"
done
```

### Parameter Tuning

```python
#!/usr/bin/env python3
"""
Test different generation parameters
"""

from openai import OpenAI
import time

client = OpenAI(base_url="http://localhost:8080/v1", api_key="x")

params_to_test = [
    {"temp": 0.3, "top_p": 0.9},
    {"temp": 0.5, "top_p": 0.9},
    {"temp": 0.7, "top_p": 0.9},
    {"temp": 0.7, "top_p": 0.95},
    {"temp": 0.9, "top_p": 0.95},
]

prompt = "Write a haiku about programming"

for params in params_to_test:
    print(f"\nTesting: {params}")
    
    start = time.time()
    response = client.chat.completions.create(
        model="local",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=100,
        **params
    )
    
    elapsed = time.time() - start
    speed = response.usage.completion_tokens / elapsed
    
    print(f"Speed: {speed:.2f} t/s")
    print(f"Output: {response.choices[0].message.content[:100]}...")
```

## Quality Benchmarking

### Consistency Test

```python
#!/usr/bin/env python3
"""
Test output consistency across multiple runs
"""

from openai import OpenAI

client = OpenAI(base_url="http://localhost:8080/v1", api_key="x")

prompt = "What is the capital of France? Answer in one word."

responses = []
for i in range(10):
    response = client.chat.completions.create(
        model="local",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=10,
        temperature=0.1,  # Low temp for consistency
        seed=42  # Fixed seed
    )
    responses.append(response.choices[0].message.content)

print("Responses:", responses)
print(f"Unique responses: {len(set(responses))}")
print(f"Consistency: {(1 - len(set(responses))/len(responses)) * 100:.1f}%")
```

### Instruction Following Score

Create a scoring rubric and test multiple prompts:

```python
#!/usr/bin/env python3
"""
Evaluate instruction following
"""

test_cases = [
    {
        "prompt": "Answer in exactly 3 words: What is 2+2?",
        "constraint": "exactly 3 words"
    },
    {
        "prompt": "List 5 colors as JSON array",
        "constraint": "valid JSON array with 5 items"
    },
    {
        "prompt": "Write a sentence without the letter 'e'",
        "constraint": "no letter 'e'"
    },
]

# Manually score outputs or use automated checks
```

## Performance Optimization Guide

### Based on Benchmark Results

#### If Generation Speed is Low:

1. **Increase GPU offload**: `-ngl 99`
2. **Reduce context size**: `-c 4096` instead of `-c 8192`
3. **Optimize batch size**: `--batch-size 512`
4. **Use smaller quantization**: Q4_K_M instead of Q8_0

#### If TTFT is High:

1. **Reduce prompt length**
2. **Increase batch size**
3. **Use smaller model**
4. **Ensure full GPU offload**

#### If Memory Usage is High:

1. **Use more aggressive quantization**
2. **Reduce context size**
3. **Lower batch size**
4. **Use `--memory-f32 0.5`**

### Recommended Settings for RTX 3060 12GB

```bash
# Balanced (speed + quality)
./llama-server \
  -m Llama-3.2-7B-Q4_K_M.gguf \
  -ngl 99 \
  -c 8192 \
  --batch-size 512 \
  --ubatch-size 64 \
  --threads 6

# Speed-optimized
./llama-server \
  -m Llama-3.2-7B-Q3_K_M.gguf \
  -ngl 99 \
  -c 4096 \
  --batch-size 1024 \
  --temp 0.5

# Quality-optimized
./llama-server \
  -m Llama-3.1-8B-Q5_K_M.gguf \
  -ngl 99 \
  -c 8192 \
  --batch-size 256 \
  --temp 0.7
```

## Benchmark Report Template

```markdown
# LLM Benchmark Report

**Date**: YYYY-MM-DD
**Hardware**: RTX 3060 12GB, AMD Ryzen 7 5800X, 32GB RAM
**Software**: llama.cpp build #xxx, CUDA 12.x

## Model Tested
- Name: Llama-3.2-7B-Instruct
- Quantization: Q4_K_M
- File size: 4.2 GB

## Results

| Metric | Value |
|--------|-------|
| Prompt Processing | 312 t/s |
| Token Generation | 52 t/s |
| Time to First Token | 0.23s |
| VRAM Usage | 5.1 GB |
| Context Window | 8192 |

## Comparison with Previous Runs
[Insert chart or table]

## Observations
- [Observation 1]
- [Observation 2]

## Recommendations
- [Recommendation 1]
- [Recommendation 2]
```

## Related Documentation

- [Alternative Backends](./7-alternative-backends.md) - Compare with other solutions
- [Model Selection](./3-model-selection-tradeoffs.md) - Choose optimal models
