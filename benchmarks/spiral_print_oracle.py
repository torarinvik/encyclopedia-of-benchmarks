"""Independent oracle for bounded clockwise traversal of rectangular matrices."""

from __future__ import annotations

import struct
from collections.abc import Sequence


MIN_ROWS = 1
MAX_ROWS = 16
MIN_COLUMNS = 2
MAX_COLUMNS = 16
MIN_CELL = -(1 << 31)
MAX_CELL = (1 << 31) - 1
MAX_VALID_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLUMNS
MAX_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1  # one extra packed value
MAX_OUTPUT_BYTES = 8 * MAX_ROWS * MAX_COLUMNS
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int],
    capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Validate `[rows, cols, row-major cells...]` and return spiral bytes."""
    if (not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    rows, columns = values[0], values[1]
    if (not MIN_ROWS <= rows <= MAX_ROWS
            or not MIN_COLUMNS <= columns <= MAX_COLUMNS
            or len(values) != 2 + rows * columns):
        return INVALID_RESULT, b""

    cells = values[2:]
    if any(not MIN_CELL <= value <= MAX_CELL for value in cells):
        return INVALID_RESULT, b""
    matrix = [list(cells[row * columns:(row + 1) * columns])
              for row in range(rows)]

    order: list[int] = []
    top, bottom = 0, rows - 1
    left, right = 0, columns - 1
    while top <= bottom and left <= right:
        for column in range(left, right + 1):
            order.append(matrix[top][column])
        top += 1

        for row in range(top, bottom + 1):
            order.append(matrix[row][right])
        right -= 1

        if top <= bottom:
            for column in range(right, left - 1, -1):
                order.append(matrix[bottom][column])
            bottom -= 1

        if left <= right:
            for row in range(bottom, top - 1, -1):
                order.append(matrix[row][left])
            left += 1

    output = b"".join(struct.pack("<q", value) for value in order)
    if type(output_is_null) is not bool:
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and len(output) > capacity):
        return OUTPUT_ERROR, b""
    return len(output), output
