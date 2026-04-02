Here's the revised version using text-based tags instead:

---

# Local LLM Task List — Research Agent Focus
> Optimized for 3–7B models (RTX 3060 + llama.cpp)

## Tags: `[LOCAL]` `[HYBRID]` `[CLOUD]`

---

## 📄 Document Processing
* `[LOCAL]` Paper abstract summarization
* `[LOCAL]` Section-level summarization
* `[LOCAL]` Extract key terms / contributions
* `[LOCAL]` Markdown / note formatting
* `[HYBRID]` Multi-paper Q&A (RAG over corpus)
* `[CLOUD]` Full paper synthesis / literature review

---

## 💻 Research Code Tasks
* `[LOCAL]` Explain experiment scripts
* `[LOCAL]` Code comments / docstrings
* `[LOCAL]` SQL / data query writing
* `[LOCAL]` Config validation (JSON/YAML)
* `[HYBRID]` Codebase Q&A (RAG required)
* `[CLOUD]` Complex debugging / refactoring

---

## 🧪 Experiment Workflow
* `[LOCAL]` Summarize experiment logs
* `[LOCAL]` Error pattern detection
* `[LOCAL]` Result table formatting
* `[HYBRID]` Explain result anomalies (needs context)
* `[CLOUD]` Hyperparameter reasoning
* `[CLOUD]` Cross-run comparison at scale

---

## 🔁 Data Transformations
* `[LOCAL]` JSON ↔ YAML / CSV → JSON
* `[LOCAL]` Extract structured data from text
* `[LOCAL]` Regex for dataset cleaning
* `[LOCAL]` BibTeX / citation formatting

---

## 📝 Writing Assistance
* `[LOCAL]` TODO / action item extraction
* `[LOCAL]` Meeting / seminar notes → summary
* `[LOCAL]` Short email / message drafts
* `[CLOUD]` Long-form academic writing

---

## ⚙️ Routing Rule
| Tier | When to use |
|------|-------------|
| `[LOCAL]` | Small input, formatting, short explanation |
| `[HYBRID]` | Retrieval over a corpus (RAG) |
| `[CLOUD]` | Large context, deep reasoning, novel synthesis |

---

## ✅ Small LLMs Do Well
* Chunked summarization (abstract, section, log)
* Structured extraction (terms, tables, citations)
* Code explanation within a single file
* Data format transformations

## ❌ Avoid Locally
* Cross-paper reasoning without RAG
* Novel hypothesis generation
* Long-context understanding (>4K tokens)

---

The backtick tags render cleanly in any Markdown viewer and are easy to grep or filter programmatically if you ever want to parse the list later.
