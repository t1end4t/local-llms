---
name: Use uv add not uv pip install
description: User prefers uv add for adding Python dependencies in this project
type: feedback
---

Always use `uv add <package>` to add Python dependencies, not `uv pip install`.

**Why:** This project uses uv as the package manager. `uv add` updates pyproject.toml and uv.lock properly; `uv pip install` bypasses that.

**How to apply:** Any time you need to install a Python package in this project, use `uv add`.
