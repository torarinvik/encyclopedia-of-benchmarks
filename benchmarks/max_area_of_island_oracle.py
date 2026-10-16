"""Independent breadth-first oracle for the bounded island-area contract."""

from __future__ import annotations

from collections import deque

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
MAX_ROWS = 16
MAX_COLUMNS = 16
MAX_CELLS = MAX_ROWS * MAX_COLUMNS
MAX_INPUT_LENGTH = 2 + MAX_CELLS
INVALID_RESULT = -1


def expected_result(values: list[int]) -> int:
    """Return the largest four-connected land component or -1 if malformed."""
    if (not isinstance(values, list) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT
    rows, columns = values[:2]
    if not 0 <= rows <= MAX_ROWS or not 0 <= columns <= MAX_COLUMNS:
        return INVALID_RESULT
    if len(values) != 2 + rows * columns:
        return INVALID_RESULT
    cells = values[2:]
    if any(cell not in (0, 1) for cell in cells):
        return INVALID_RESULT

    visited = bytearray(len(cells))
    largest = 0
    for start, cell in enumerate(cells):
        if cell == 0 or visited[start]:
            continue
        visited[start] = 1
        queue = deque([start])
        area = 0
        while queue:
            current = queue.popleft()
            area += 1
            row, column = divmod(current, columns)
            neighbors = []
            if row > 0:
                neighbors.append(current - columns)
            if row + 1 < rows:
                neighbors.append(current + columns)
            if column > 0:
                neighbors.append(current - 1)
            if column + 1 < columns:
                neighbors.append(current + 1)
            for neighbor in neighbors:
                if cells[neighbor] == 1 and not visited[neighbor]:
                    visited[neighbor] = 1
                    queue.append(neighbor)
        largest = max(largest, area)
    return largest
