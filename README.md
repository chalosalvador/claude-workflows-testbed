# tasklet

A tiny task tracker. This repo exists to exercise the `gh-issue-flow` Claude Code plugin end to end.

Run the same gate CI runs:

```bash
pip install -e . ruff pytest && ruff check src/ tests/ && pytest tests/ -q
```
