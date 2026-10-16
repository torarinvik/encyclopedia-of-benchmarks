"""Bounded packed-array oracle for row-major 2D lookup."""

from __future__ import annotations

MAX_ROWS = 32
MAX_COLUMNS = 32
MAX_VALUE = 1_000_000
MAX_INPUT_LENGTH = 3 + MAX_ROWS * MAX_COLUMNS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1
    rows, columns, index = values[:3]
    if (not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS
            or len(values) != 3 + rows * columns
            or not 0 <= index < rows * columns
            or any(not 0 <= value <= MAX_VALUE for value in values[3:])):
        return -1
    return values[3 + index]
