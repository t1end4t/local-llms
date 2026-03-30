# TODO — Local LLM on RTX 3060

> Goal: Run local LLM to handle simple tasks, route complex ones to Claude.
> Hardware: RTX 3060 12GB | Stack: llama.cpp + OpenAI-compatible API

---

## Phase 1 — Hardware & Runtime Setup

- [x] Verify CUDA toolkit version matches driver (`nvidia-smi`, `nvcc --version`)
- [x] Install / build llama.cpp with CUDA support (`GGML_CUDA=1 make`)
- [x] Smoke test: run a small model fully on GPU, confirm `n_gpu_layers` offloads all layers
- [x] Benchmark GPU utilization (`nvtop` or `nvidia-smi dmon`) during inference
- [x] Note max stable VRAM headroom (12GB minus OS/display usage ~= usable budget) -> should around 10GB model

---

## Phase 2 — Model Selection & Download

> All from [unsloth Dynamic 2.0 Quants](https://huggingface.co/collections/unsloth/unsloth-dynamic-20-quants) collection.
> Recommended quant: `Q4_K_M` — Q2_K is too aggressive (noticeably degraded code/reasoning quality), Q6_K+ is overkill given 10GB budget.

### Two models, two roles

| Role | Model | Size | Quant | Est. VRAM | Why |
|------|-------|------|-------|-----------|-----|
| **Primary** — code + explanations + dev workflow | `Qwen3.5-9B-GGUF` | 9B | Q4_K_M | ~6GB | Code-tuned, 1.49M DLs, 4GB headroom for context |
| **Quality tier** — long summaries + doc tasks | `Gemma-3-12b-it-GGUF` | 12B | Q4_K_M | ~8GB | Best instruction-tuning in budget, 2GB headroom |

**Why not the others:**
- **Q2_K 24–31B models** (Devstral, Qwen3-Coder-30B, Mistral-Small-24B) — 2-bit compression destroys code quality; a well-quantized 9B beats a Q2_K 30B
- **Reasoning/thinking models** (DeepSeek-R1, Qwen3-Thinking) — overkill; no task in LOCAL_LLM_TASKS requires multi-step reasoning
- **Sub-4B models** — too small for coherent code generation or explanation; useful only as routers, which is Phase 4+ complexity
- **Multiple size variants** — adds download cost and swap overhead with marginal gain

### Steps

- [x] Download `Qwen3.5-9B Q4_K_M` (primary) — handles ~90% of tasks in LOCAL_LLM_TASKS
- [ ] Test against the 8 priority tasks from LOCAL_LLM_TASKS (`code explain`, `git commit`, `codebase Q&A`, `error log`, `test gen`, `PDF summary`, `config validate`, `shell cmd`)
- [ ] If output quality on explanation/summary tasks is insufficient, download `Gemma-3-12b-it Q4_K_M` as quality-tier swap
- [ ] Decide: keep one model loaded always, or hot-swap based on task type?

---

## Phase 3 — Local Server Setup

- [ ] Start `llama-server` with OpenAI-compatible API (`--port 8080 --ctx-size 4096`)
- [ ] Verify `/v1/chat/completions` endpoint responds correctly
- [ ] Test with `curl` — basic prompt in, coherent response out
- [ ] Configure `--n-predict`, `--temp`, `--ctx-size` for task types:
  - Short generation tasks: low temp (0.1–0.3), limited tokens
  - Explanation tasks: moderate temp (0.5), more tokens
- [ ] Set up as a systemd service or `tmux` session for persistent availability
- [ ] (Optional) Add basic auth or bind to localhost only for security

---

## Phase 4 — Routing Layer Design

- [ ] Define routing rules: what goes local vs Claude
  - Local: explain function, commit msg, regex, format conversion, short summary
  - Claude: multi-file edits, architecture, debugging complex issues, long doc gen
- [ ] Decide routing trigger mechanism:
  - [ ] Option A: Claude Code hook that intercepts certain prompt patterns
  - [ ] Option B: A wrapper CLI script (`ask.sh local|auto "prompt"`)
  - [ ] Option C: Claude Code subagent that calls local LLM via HTTP
- [ ] Implement chosen mechanism (start simple — wrapper script is fastest)
- [ ] Test routing: confirm simple tasks hit local, complex tasks escalate

---

## Phase 5 — Claude Code Integration

- [ ] Create a Claude Code agent (`.claude/agents/local-llm.md`) that calls local server
- [ ] Add a slash command (`.claude/commands/local.md`) for manual local routing
- [ ] (Optional) Add a hook to auto-route commit message generation to local LLM
- [ ] Verify agent can reach `localhost:8080` from within Claude Code sessions
- [ ] Test end-to-end: user asks for commit msg → local agent responds → no Claude tokens used

---

## Phase 6 — Evaluation & Cost Tracking

- [ ] Log which tasks go local vs cloud (simple counter/logfile is fine)
- [ ] Compare local output quality vs Claude on same 10 prompts
- [ ] Estimate monthly Claude token savings from routing
- [ ] Identify tasks where local output is "good enough" vs where Claude wins clearly
- [ ] Tune routing rules based on findings

---

## Phase 7 — Stretch Goals

- [ ] Explore `llama.cpp` speculative decoding to speed up local inference
- [ ] Try a larger model (13B Q4) if VRAM allows with no display load
- [ ] Add a second model slot for general tasks vs code tasks (2-model routing)
- [ ] Integrate with `opencode` or other local AI tools using same server endpoint
- [ ] Experiment with function calling / tool use support in local model

---

## Reference

- Task categories and routing guidelines: [`LOCAL_LLM_TASKS.md`](./LOCAL_LLM_TASKS.md)
- llama.cpp docs: https://github.com/ggml-org/llama.cpp
- GGUF model hub: https://huggingface.co/models?library=gguf

---

*Start with Phase 1–3 to get the stack running, then Phase 4 for the routing logic.*
