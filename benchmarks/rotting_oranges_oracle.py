"""Independent oracle for the bounded Java Rotting Oranges contract."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence


MAX_ROWS = 16
MAX_COLUMNS = 16
MAX_VALID_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLUMNS
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -(1 << 63)
IMPOSSIBLE_RESULT = -1


def expected_result(
    values: Sequence[int],
    input_length: int | None = None,
    input_is_null: bool = False,
) -> int:
    """Validate a packed grid and return minimum rotting minutes."""
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if input_length is None:
        input_length = len(values) if isinstance(values, (list, tuple)) else -1
    if type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if not isinstance(values, (list, tuple)):
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return INVALID_RESULT
    if input_is_null:
        return 0 if input_length == 0 and not values else INVALID_RESULT
    if input_length != len(values):
        return INVALID_RESULT
    # The scalar harness represents an empty array as a null pointer.
    if input_length == 0:
        return 0
    if input_length < 2:
        return INVALID_RESULT

    rows, columns = values[0], values[1]
    if rows == 0:
        return 0 if columns == 0 and input_length == 2 else INVALID_RESULT
    if not 1 <= rows <= MAX_ROWS or not 0 <= columns <= MAX_COLUMNS:
        return INVALID_RESULT
    if input_length != 2 + rows * columns:
        return INVALID_RESULT
    cells = values[2:]
    if any(cell not in (0, 1, 2) for cell in cells):
        return INVALID_RESULT
    if columns == 0:
        return 0

    grid = [list(cells[row * columns:(row + 1) * columns])
            for row in range(rows)]
    queue: deque[tuple[int, int, int]] = deque()
    fresh = 0
    for row in range(rows):
        for column in range(columns):
            if grid[row][column] == 2:
                queue.append((row, column, 0))
            elif grid[row][column] == 1:
                fresh += 1
    if fresh == 0:
        return 0

    rotted = 0
    minutes = 0
    directions = ((-1, 0), (0, 1), (1, 0), (0, -1))
    while queue:
        row, column, minute = queue.popleft()
        minutes = max(minutes, minute)
        for row_delta, column_delta in directions:
            next_row = row + row_delta
            next_column = column + column_delta
            if (0 <= next_row < rows and 0 <= next_column < columns
                    and grid[next_row][next_column] == 1):
                grid[next_row][next_column] = 2
                rotted += 1
                queue.append((next_row, next_column, minute + 1))
    return minutes if rotted == fresh else IMPOSSIBLE_RESULT
