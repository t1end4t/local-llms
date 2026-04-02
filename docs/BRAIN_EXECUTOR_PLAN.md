# Brain-Executor Architecture Plan
> Claude Code as Brain · OpenCode as Executor · Local LLM as Worker

---

## Core Idea

Shift Claude Code from a "do everything" agent to a **pure reasoning brain**:

| Role | Tool | Does |
|------|------|------|
| **Brain** | Claude Code | Conversation, planning, task decomposition, routing decisions |
| **Executor** | OpenCode | File read/write/edit, bash, code changes, codebase exploration |
| **Worker** | Local LLM | Summarization, format conversion, commit messages, simple Q&A |

Claude Code **never** touches the filesystem or shell directly. It only thinks, plans, and delegates.

---

## Why This Works

- `opencode run "task"` runs OpenCode headlessly from the command line — perfect for Claude to call it as a subprocess
- OpenCode already has its own AI + tools (Edit, Read, Bash, Glob) — it's a full coding agent
- Local LLM is already integrated via `local-llm-call` skill and `local-llm` agent
- Claude Code's value is in reasoning and conversation, not in being the one to type `sed` commands

---

## What Changes

### Before
```
User → Claude Code → [Read, Edit, Write, Bash, Glob, Grep] → Result
```

### After
```
User ↔ Claude Code (Brain)
              ↓ route by task type
    ┌─────────┴────────────┐
    ▼                      ▼
OpenCode              Local LLM
(Executor)            (Worker)
File ops, bash        Simple tasks
    │                      │
    └──────────────────────┘
              ↓
         Claude Code
         (reviews result, next step)
```

---

## Components to Build

### 1. `opencode` skill  ← core piece
**File:** `.claude/skills/opencode/SKILL.md`

Wraps `opencode run "task"` as a callable skill. Claude Code calls this with a structured task prompt and gets back OpenCode's output.

```bash
# Under the hood
opencode run --dir /path/to/project "TASK: ..."
```

The skill handles:
- Formatting the task message for OpenCode
- Capturing and returning the output
- Error handling (OpenCode timeout, failure)

---

### 2. Task Protocol (Brain → Executor contract)
A standard markdown format Claude Code uses when delegating to OpenCode:

```
TASK: <one-line objective>
CONTEXT: <what I know without reading files>
FILES: <hints about relevant paths if known from prior conversation>
CONSTRAINTS: <must not break X, stay in Y directory, etc.>
RETURN: <what Claude Code needs back — summary, diff, confirmation>
```

Claude Code fills this in based on the user conversation. OpenCode executes it.

---

### 3. CLAUDE.md rules — enforce brain-only behavior
Add to `CLAUDE.md`:

```markdown
## Brain-Only Mode (ENFORCED)

Claude Code acts as the thinking brain, NOT the executor.

### YOU MUST NEVER:
- Use Read, Edit, Write, Bash, Glob, or Grep tools for execution tasks
- Directly edit files, run scripts, or explore the codebase yourself

### YOU MUST ALWAYS:
- Delegate all file operations → opencode skill
- Delegate all bash/shell work → opencode skill  
- Delegate simple/mechanical tasks → local-llm skill
- Ask OpenCode to explore/summarize before you reason about code

### Routing decision:
- Needs file changes, bash, code? → opencode skill
- Summarization, format, commit msg, quick Q&A? → local-llm skill
- Multi-step plan, architecture decision? → Reason yourself, then delegate execution
```

---

### 4. Context flow (the hard problem)

Since Claude Code won't read files, it needs a way to get project context. Protocol:

1. **At session start**: Call `opencode run "Give me a project overview: directory structure, main entry points, tech stack. Be concise."` → Claude Code gets a summary to reason from.
2. **Before delegating a task**: If Claude Code needs more context, ask OpenCode to investigate first: `"Find where X is implemented and summarize it in 3 lines."`
3. **User provides context**: The user's description IS the context. Claude Code trusts it.

This means Claude Code asks OpenCode to be its "eyes" — OpenCode reads, reports back, then executes.

---

### 5. Result loop

```
Claude Code assigns task
     ↓
OpenCode executes, prints result
     ↓
Claude Code reads output text (not files)
     ↓
Claude Code decides: done / needs iteration / escalate to user
```

Claude Code reads **OpenCode's text output** (the subprocess stdout), not the actual files. This is fine — it's reading a report, not doing execution.

---

## Implementation Phases

### Phase 1 — OpenCode skill (Day 1)
- [ ] Create `.claude/skills/opencode/SKILL.md`
- [ ] Test `opencode run` headless with a simple task
- [ ] Verify output capture works from Claude Code

### Phase 2 — CLAUDE.md brain rules (Day 1)
- [ ] Add routing rules and forbidden tools list to `CLAUDE.md`
- [ ] Define task protocol format
- [ ] Test: ask Claude Code to create a file — does it delegate?

### Phase 3 — Context bootstrap (Day 2)
- [ ] Add `/project-context` command: calls OpenCode to summarize the current project
- [ ] This command is auto-called at session start (via hook or CLAUDE.md rule)

### Phase 4 — Task decomposition (Day 2–3)
- [ ] Create `decompose` skill: takes a user request, breaks into ordered tasks with routing tags
- [ ] Each task tagged `[OPENCODE]`, `[LOCAL]`, or `[BRAIN]`
- [ ] Claude Code executes the plan task by task

### Phase 5 — Iteration loop (Day 3)
- [ ] After each OpenCode task, Claude Code reviews output
- [ ] If OpenCode failed or result is incomplete, Claude Code refines the task and retries
- [ ] Claude Code decides when the overall goal is done

---

## Open Questions to Resolve

1. **OpenCode model config**: Which model does OpenCode use? Should it use the same local LLM or a different one? We want it to be cheap since it's the executor.
2. **Session continuity**: Should Claude Code continue the same OpenCode session (`--continue`) across a multi-step plan, or start fresh each task?
3. **Failure handling**: If OpenCode makes a mistake (wrong file edited), how does Claude Code detect and recover?
4. **What Claude Code CAN still read**: Claude Code may need to read OpenCode's output files (task results, summaries it asked for) — this should be allowed as it's reading *reports*, not doing execution.

---

## Non-Goals

- Claude Code should NOT route every single message through OpenCode — simple questions stay in the brain
- We are NOT trying to prevent Claude Code from thinking/reasoning — only from doing filesystem/shell work
- We do NOT need to block Claude Code's tools at the hook level (too complex) — CLAUDE.md instructions are sufficient for behavior shaping

---

## Example: "Create a React app"

```
User: "I want a React app with auth and a dashboard"

Claude Code (Brain):
  1. Asks clarifying questions (routing? styling? backend?)
  2. Creates a phased plan:
     - Task 1 [OPENCODE]: "Scaffold React app with Vite, install react-router and auth deps"
     - Task 2 [OPENCODE]: "Create auth flow: Login, Register pages, token storage"
     - Task 3 [OPENCODE]: "Create Dashboard layout with sidebar nav"
     - Task 4 [LOCAL]: "Generate commit message for the changes"
  3. Calls opencode skill with Task 1 prompt
  4. OpenCode does the actual file creation
  5. Claude Code reads OpenCode's summary, moves to Task 2
  6. ... repeat until done
  7. Calls local-llm for commit message
  8. Reports back to user: "Done. Here's what was built: ..."
```

Claude Code never touched a file. OpenCode built the whole thing.
