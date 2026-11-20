"""Forward simulation with a fresh top-row flood fill after each brick hit."""

from __future__ import annotations

MAX_ROWS = 8
MAX_COLUMNS = 8
MAX_CELLS = 64
MAX_HITS = 16
MAX_PARSEABLE_INPUT_LENGTH = 100
MAX_OUTPUT_BYTES = 128
WORKSPACE_BYTES = 584


def _reachable(grid: list[int], rows: int, columns: int) -> list[bool]:
    reached = [False] * (rows * columns)
    queue: list[int] = []
    for column in range(columns):
        cell = column
        if grid[cell]:
            reached[cell] = True
            queue.append(cell)
    cursor = 0
    while cursor < len(queue):
        cell = queue[cursor]
        cursor += 1
        row, column = divmod(cell, columns)
        neighbors: list[int] = []
        if row > 0:
            neighbors.append(cell - columns)
        if row + 1 < rows:
            neighbors.append(cell + columns)
        if column > 0:
            neighbors.append(cell - 1)
        if column + 1 < columns:
            neighbors.append(cell + 1)
        for neighbor in neighbors:
            if grid[neighbor] and not reached[neighbor]:
                reached[neighbor] = True
                queue.append(neighbor)
    return reached


def _word(value: int) -> bytes:
    return value.to_bytes(8, "little", signed=True)


def expected_output(
    input_values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    length = len(input_values) if input_length is None else input_length
    if input_is_null or length != len(input_values) or not 3 <= length <= MAX_PARSEABLE_INPUT_LENGTH:
        return -1, b""
    if any(not isinstance(value, int) for value in input_values[:3]):
        return -1, b""
    rows, columns, hit_count = input_values[:3]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return -1, b""
    cells = rows * columns
    if not 0 <= hit_count <= min(MAX_HITS, cells):
        return -1, b""
    if length != 3 + cells + 2 * hit_count:
        return -1, b""
    grid = input_values[3:3 + cells].copy()
    if any(not isinstance(value, int) or value not in (0, 1) for value in grid):
        return -1, b""

    hits: list[tuple[int, int]] = []
    seen: set[int] = set()
    position = 3 + cells
    for index in range(hit_count):
        row = input_values[position + 2 * index]
        column = input_values[position + 2 * index + 1]
        if (not isinstance(row, int) or not isinstance(column, int)
                or not 0 <= row < rows or not 0 <= column < columns):
            return -1, b""
        cell = row * columns + column
        if cell in seen:
            return -1, b""
        seen.add(cell)
        hits.append((row, column))

    initially_reached = _reachable(grid, rows, columns)
    if any(occupied and not initially_reached[cell]
           for cell, occupied in enumerate(grid)):
        return -1, b""

    required = hit_count * 8
    if (output_capacity is not None and output_capacity < required) or (required and output_is_null):
        return -2, b""
    if hit_count == 0:
        return 0, b""

    answers: list[int] = []
    for row, column in hits:
        cell = row * columns + column
        if not grid[cell]:
            answers.append(0)
            continue
        grid[cell] = 0
        reached = _reachable(grid, rows, columns)
        fallen = 0
        for candidate, occupied in enumerate(grid):
            if occupied and not reached[candidate]:
                grid[candidate] = 0
                fallen += 1
        answers.append(fallen)

    output = b"".join(_word(value) for value in answers)
    return len(output), output
