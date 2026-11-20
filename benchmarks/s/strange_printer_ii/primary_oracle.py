"""Color-rectangle precedence DAG for bounded Strange Printer II grids."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ROWS = 6
MAX_COLUMNS = 6
MAX_COLORS = 6
MAX_CELLS = MAX_ROWS * MAX_COLUMNS
MAX_VALID_INPUT_LENGTH = 2 + MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_WORKSPACE_BYTES = 392
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return None
    if len(values) != 2 + rows * columns:
        return None
    colors = tuple(values[2:])
    if any(color < 1 or color > MAX_COLORS for color in colors):
        return None
    return rows, columns, colors


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    rows, columns, grid = parsed

    first_row = [rows] * (MAX_COLORS + 1)
    last_row = [-1] * (MAX_COLORS + 1)
    first_column = [columns] * (MAX_COLORS + 1)
    last_column = [-1] * (MAX_COLORS + 1)
    for row in range(rows):
        for column in range(columns):
            color = grid[row * columns + column]
            first_row[color] = min(first_row[color], row)
            last_row[color] = max(last_row[color], row)
            first_column[color] = min(first_column[color], column)
            last_column[color] = max(last_column[color], column)

    outgoing = [0] * (MAX_COLORS + 1)
    indegree = [0] * (MAX_COLORS + 1)
    present_count = 0
    for color in range(1, MAX_COLORS + 1):
        if last_row[color] < 0:
            continue
        present_count += 1
        for row in range(first_row[color], last_row[color] + 1):
            for column in range(first_column[color], last_column[color] + 1):
                covered = grid[row * columns + column]
                bit = 1 << covered
                if covered != color and not outgoing[color] & bit:
                    outgoing[color] |= bit
                    indegree[covered] += 1

    queue = [color for color in range(1, MAX_COLORS + 1)
             if last_row[color] >= 0 and indegree[color] == 0]
    processed = 0
    for color in queue:
        processed += 1
        for later in range(1, MAX_COLORS + 1):
            if outgoing[color] & (1 << later):
                indegree[later] -= 1
                if indegree[later] == 0:
                    queue.append(later)
    return int(processed == present_count)
