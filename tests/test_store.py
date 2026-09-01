from tasklet.store import Store


def test_add_returns_the_task():
    store = Store()
    task = store.add("write the docs", tags=["docs"])
    assert task.title == "write the docs"
    assert task.tags == ["docs"]
    assert task.done is False


def test_complete_marks_done_and_reports_it():
    store = Store()
    store.add("ship it")
    assert store.complete("ship it") is True
    assert store.pending() == []


def test_complete_returns_false_for_an_unknown_task():
    store = Store()
    assert store.complete("nope") is False


def test_by_tag_returns_pending_tasks_carrying_the_tag():
    store = Store()
    store.add("write the docs", tags=["docs"])
    store.add("fix the parser", tags=["core"])
    store.add("untagged")
    assert [t.title for t in store.by_tag("docs")] == ["write the docs"]


def test_by_tag_excludes_a_completed_task_that_carries_the_tag():
    store = Store()
    store.add("write the docs", tags=["docs"])
    store.complete("write the docs")
    assert store.by_tag("docs") == []


def test_by_tag_returns_empty_for_an_unknown_tag():
    store = Store()
    store.add("write the docs", tags=["docs"])
    assert store.by_tag("nope") == []
