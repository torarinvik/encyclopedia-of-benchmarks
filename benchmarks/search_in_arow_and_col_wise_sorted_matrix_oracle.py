"""Bounded reference oracle for the pinned Java staircase matrix search."""

from __future__ import annotations

import struct

MAX_DIMENSION = 63
MAX_INPUT_VALUES = 2 + MAX_DIMENSION * MAX_DIMENSION
INT32_MIN = -(1 << 31)
INT32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int = 8,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return the found flag and the packed coordinate pair for one search."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 2
        or len(values) > MAX_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1, b""

    n, target = values[0], values[1]
    if not 1 <= n <= MAX_DIMENSION or not INT32_MIN <= target <= INT32_MAX:
        return -1, b""
    if len(values) != 2 + n * n:
        return -1, b""

    cells = values[2:]
    if any(value < INT32_MIN or value > INT32_MAX for value in cells):
        return -1, b""
    target_count = 0
    for row in range(n):
        for column in range(n):
            index = row * n + column
            value = cells[index]
            if column > 0 and value < cells[index - 1]:
                return -1, b""
            if row > 0 and value < cells[index - n]:
                return -1, b""
            if value == target:
                target_count += 1
                if target_count > 1:
                    return -1, b""

    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null or output_capacity < 8:
        return -2, b""

    row = 0
    column = n - 1
    result_row = -1
    result_column = -1
    found = False
    while row < n and column >= 0:
        value = cells[row * n + column]
        if value == target:
            result_row, result_column = row, column
            found = True
            break
        if target > value:
            row += 1
        else:
            column -= 1

    return (1 if found else 0), struct.pack("<ii", result_row, result_column)
