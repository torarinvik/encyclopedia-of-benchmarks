"""Oracle for the pinned Python grid greedy best-first search."""

from __future__ import annotations

MAX_ROWS = 3
MAX_COLUMNS = 3
MAX_CELLS = MAX_ROWS * MAX_COLUMNS
MAX_INPUT_LENGTH = 6 + MAX_ROWS
PATH_LENGTH_SHIFT = 36


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 7 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    rows, columns, start_row, start_column, goal_row, goal_column = values[:6]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS or len(values) != 6 + rows:
        return -1
    if (not 0 <= start_row < rows or not 0 <= goal_row < rows
            or not 0 <= start_column < columns or not 0 <= goal_column < columns):
        return -1
    masks = values[6:]
    if any(mask < 0 or mask >= 1 << columns for mask in masks):
        return -1

    start = start_row * columns + start_column
    goal = goal_row * columns + goal_column

    def blocked(cell: int) -> bool:
        row, column = divmod(cell, columns)
        return bool(masks[row] & (1 << column))

    if blocked(start) or blocked(goal):
        return -1

    def heuristic(cell: int) -> int:
        row, column = divmod(cell, columns)
        return abs(row - goal_row) + abs(column - goal_column)

    opened = [start]
    open_set = {start}
    closed: set[int] = set()
    parent: list[int | None] = [None] * (rows * columns)
    found = False
    while opened:
        opened.sort(key=heuristic)  # Python's stable sort preserves successor insertion order on ties.
        current = opened.pop(0)
        open_set.remove(current)
        if current == goal:
            found = True
            break
        closed.add(current)
        row, column = divmod(current, columns)
        for next_row, next_column in ((row - 1, column), (row, column - 1),
                                      (row + 1, column), (row, column + 1)):
            if not (0 <= next_row < rows and 0 <= next_column < columns):
                continue
            child = next_row * columns + next_column
            if blocked(child) or child in closed or child in open_set:
                continue
            parent[child] = current
            opened.append(child)
            open_set.add(child)

    path = [start]
    if found:
        path = []
        current: int | None = goal
        while current is not None:
            path.append(current)
            current = parent[current]
        path.reverse()

    packed = sum((cell + 1) << (4 * offset) for offset, cell in enumerate(path))
    return (len(path) << PATH_LENGTH_SHIFT) | packed
