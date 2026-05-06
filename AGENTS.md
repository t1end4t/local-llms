## 0. Never Run Downloads or Long Commands

**Never execute `huggingface-cli download`, `hf download`, `wget`, or any model/data download command.**

- Always present the model name, file size, and download command for the user to run.
- Never run commands that take minutes to hours — only fast queries (ls, grep, curl head, etc.).
- If a download is needed, show the exact command and let the user run it.

## Project context

This project has a thinking space in the second-brain vault.

- **Thinking space**: `../../second-brain/1-Projects/Local-LLM-Playground/`
- Before starting work, read `Brief.md` and `TODO.md` from there for project context, goals, and current status.
- You may also check `Experiments.md`, `Decisions.md`, and `Dead-ends.md` if they exist, to avoid repeating past work.
- **Do NOT edit any files outside this repository.** The second-brain is read-only from here.

## After completing work

When finishing a task or session, remind the user:

> Remember to update your second-brain project notes:
> - Update `TODO.md` to check off completed items
> - Log any experiments in `Experiments.md`
> - Record key decisions in `Decisions.md`
> - Note any dead ends in `Dead-ends.md`
> - Add meaningful results to `Results.md`
> - Update `Brief.md` if the project direction changed
