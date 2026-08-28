"""In-memory task store."""

from dataclasses import dataclass, field


@dataclass
class Task:
    title: str
    done: bool = False
    tags: list[str] = field(default_factory=list)


class Store:
    def __init__(self) -> None:
        self._tasks: list[Task] = []

    def add(self, title: str, tags: list[str] | None = None) -> Task:
        task = Task(title=title, tags=list(tags or []))
        self._tasks.append(task)
        return task

    def complete(self, title: str) -> bool:
        for task in self._tasks:
            if task.title == title:
                task.done = True
                return True
        return False

    def pending(self) -> list[Task]:
        return [t for t in self._tasks if not t.done]
