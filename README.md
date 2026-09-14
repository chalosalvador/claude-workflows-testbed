# tasklet

A tiny task tracker. This repo exists to exercise the `gh-issue-flow` Claude Code plugin end to end.

Run the same gate CI runs:

```bash
pip install -e . ruff pytest && ruff check src/ tests/ && pytest tests/ -q
```

---

## About this repo

A testbed for the [`gh-issue-flow`](https://github.com/chalosalvador/claude-workflows)
Claude Code plugin. The six open issues are deliberately varied — a real bug, an easy
feature, a docs fix, an open product question, a migration, and one more feature — so
that `triage` has something to actually judge and its `agent-ready` gate has to reject
some of them.

**The install line above is the fixture.** `scripts/reset.sh` puts it back to
`pip install -e . && pytest tests/ -q`, which installs neither `ruff` nor `pytest`, so a
fresh clone of the reset repo cannot run the gate as documented.

To run the plugin against it again from a clean slate:

```bash
scripts/reset.sh --dry-run   # print every mutation, change nothing
scripts/reset.sh             # reopen issues, strip triage verdicts, clear the
                             # board, delete stale branches, restore this fixture
```

Env overrides: `TESTBED_REPO`, `TESTBED_OWNER`, `TESTBED_BOARD` (default board `1`).
