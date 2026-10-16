"""Independent bounded oracle for saddleback search in a monotone matrix."""

from __future__ import annotations

MAX_ROWS = 32
MAX_COLUMNS = 32
MAX_INPUT_LENGTH = 3 + MAX_ROWS * MAX_COLUMNS
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Encode a found one-based matrix coordinate, return zero when absent."""
    if (not isinstance(values, (list, tuple)) or len(values) < 3
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int for value in values)):
        return INVALID_RESULT

    rows, columns, target = values[:3]
    if (not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS
            or not I32_MIN <= target <= I32_MAX
            or len(values) != 3 + rows * columns):
        return INVALID_RESULT

    matrix = values[3:]
    if any(not I32_MIN <= value <= I32_MAX for value in matrix):
        return INVALID_RESULT

    # Deliberately use a linear scan as an oracle, independent of the ports'
    # top-right staircase search and Java's bottom-left recursive search.
    for index, value in enumerate(matrix):
        if value == target:
            return index + 1
    return 0
