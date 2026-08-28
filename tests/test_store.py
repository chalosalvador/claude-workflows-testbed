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
