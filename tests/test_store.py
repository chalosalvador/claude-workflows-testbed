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


def test_remove_deletes_the_task_and_reports_it():
    store = Store()
    store.add("ship it")
    assert store.remove("ship it") is True
    assert store.pending() == []
    assert store.remove("ship it") is False


def test_remove_returns_false_for_an_unknown_task():
    store = Store()
    assert store.remove("nope") is False


def test_remove_takes_only_the_first_match():
    store = Store()
    store.add("dup", tags=["first"])
    store.add("dup", tags=["second"])
    assert store.remove("dup") is True
    assert [t.tags for t in store.pending()] == [["second"]]
