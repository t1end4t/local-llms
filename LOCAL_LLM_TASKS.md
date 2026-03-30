# Local LLM Task List

> Tasks suitable for small local LLMs (3-7B params) on RTX 3060 + llama.cpp

---

## Quick Reference

| Category | # Tasks | Difficulty |
|----------|--------:|------------|
| Document | 5 | Easy |
| Code | 10 | Easy-Medium |
| Developer Workflow | 6 | Easy |
| File Management | 4 | Easy |
| Research | 5 | Medium |
| Transformations | 5 | Easy |
| Generation | 3 | Easy |

---

## 📄 Document Tasks

| # | Task | Description |
|---|------|-------------|
| 1 | **PDF Summarization** | Extract key points from papers/docs |
| 2 | **File Content Explain** | "What does this config file do?" |
| 3 | **Markdown Formatting** | Fix headings, lists, code blocks |
| 4 | **Meeting Notes → Summary** | Bullet-point key decisions |
| 5 | **Readme Generator** | Auto-generate from code structure |

---

## 💻 Code Tasks

| # | Task | Description |
|---|------|-------------|
| 1 | **Function Explanation** | "What does this function do?" |
| 2 | **Code Comment Generation** | Add docstrings/comments |
| 3 | **Bug Explanation** | Parse error → explain in plain English |
| 4 | **Refactoring Suggestions** | "How to improve this code?" |
| 5 | **Test Generation** | Write unit tests for selected code |
| 6 | **Code Translation** | Python → TypeScript, etc. |
| 7 | **Regex Generation** | "Write regex for..." |
| 8 | **SQL Query Writing** | "Generate SQL for..." |
| 9 | **Shell Command Generation** | "Write a bash script to..." |
| 10 | **Config Validation** | JSON/YAML/TOML lint + explain errors |

---

## 🔧 Developer Workflow

| # | Task | Description |
|---|------|-------------|
| 1 | **Git Commit Message** | Auto-generate from diff |
| 2 | **PR Description** | Summarize changes |
| 3 | **Git History Q&A** | "What did commit X do?" |
| 4 | **Explain Error Logs** | Parse stack traces |
| 5 | **Dependency Explain** | "Why do we need this package?" |
| 6 | **API Docs Q&A** | Ask questions about your APIs |

---

## 🗂️ File Management

| # | Task | Description |
|---|------|-------------|
| 1 | **File Classification** | Tag/categorize by content |
| 2 | **Smart Rename** | Suggest names based on content |
| 3 | **Duplicate Detection** | "Are these files similar?" |
| 4 | **Content Search** | "Which file contains X?" |

---

## 🧪 Research Tasks

| # | Task | Description |
|---|------|-------------|
| 1 | **Paper Abstract Summary** | TL;DR for academic papers |
| 2 | **Codebase Q&A** | "Where is the auth logic?" |
| 3 | **Experiment Results Explain** | "What do these metrics mean?" |
| 4 | **Hyperparameter Tuning** | Suggest settings based on task |
| 5 | **Literature Review Helper** | Compare papers, find gaps |

---

## 🔁 Quick Transformations

| # | Task | Description |
|---|------|-------------|
| 1 | **JSON ↔ YAML** | Convert between formats |
| 2 | **CSV → JSON** | Transform data |
| 3 | **Text Case Conversion** | camelCase, snake_case, etc. |
| 4 | **URL Encoding/Decoding** | Quick transforms |
| 5 | **Base64 Encode/Decode** | Quick utils |

---

## 🎯 Simple Generation

| # | Task | Description |
|---|------|-------------|
| 1 | **Email Draft** | Short response drafts |
| 2 | **TODO from Chat** | Convert discussion to action items |
| 3 | **Slack Message** | Format long messages |

---

## Recommended Priority

For researcher + dev workflow, in order of impact:

1. **Code Explanation** — Most frequent, huge time saver
2. **Git Workflow** — Commit msgs, PR descriptions
3. **Codebase Q&A** — "Where is...?" questions
4. **Error Log Parser** — Debug faster
5. **Test Generation** — Speed up TDD
6. **PDF/Paper Summary** — If you read lots of papers
7. **Config Validation** — Catch errors early
8. **Shell Command Generation** — Learn new commands

---

## Hardware Notes

**RTX 3060 (12GB) + llama.cpp — Recommended Models:**

| Model | Params | Quantization | VRAM |
|-------|--------|---------------|------|
| Qwen2.5-Coder | 3B | Q6_K | ~3GB |
| Qwen2.5-Coder | 7B | Q4_K_M | ~5GB |
| DeepSeek-Coder | 6.7B | Q4_K_M | ~5GB |
| Phi-3-mini | 3.8B | Q6_K | ~3.5GB |
| Llama3 8B | 8B | Q4_K_M | ~6GB |

---

## When to Use Local vs Cloud

| Use Local (Small LLM) | Use Cloud (Claude/GPT) |
|-----------------------|------------------------|
| Simple code snippets | Complex debugging |
| File rename/classify | Architecting systems |
| Explain function | Writing long docs |
| Format transformations | Deep world knowledge |
| Short summarization | Large document analysis |
| Quick code review | Novel algorithm design |
| Regex/log parsing | Security-sensitive tasks |

---

*Generated for local-llms setup*
