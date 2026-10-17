"""Oracle for the bounded two-dimensional segment-tree workload."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ROWS = 16
MAX_COLUMNS = 16
MAX_OPERATIONS = 256
MIN_CELL_VALUE = -1_000
MAX_CELL_VALUE = 1_000
MAX_RECTANGLE_SUM = MAX_ROWS * MAX_COLUMNS * MAX_CELL_VALUE
CHECKSUM_OFFSET = MAX_RECTANGLE_SUM + 1
MAX_VALID_INPUT_VALUES = 1_283
MAX_PARSEABLE_INPUT_VALUES = 1_284
INVALID_RESULT = -1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the operation checksum, or -1 for malformed input."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_VALUES
        or len(values) < 3
        or any(
            type(value) is not int or not I64_MIN <= value <= I64_MAX
            for value in values
        )
    ):
        return INVALID_RESULT

    rows, columns, operation_count = values[:3]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return INVALID_RESULT
    if not 0 <= operation_count <= MAX_OPERATIONS:
        return INVALID_RESULT
    cursor = 3
    if cursor + 5 * operation_count > len(values):
        return INVALID_RESULT

    matrix = [[0] * columns for _ in range(rows)]
    checksum = 0
    for operation_index in range(operation_count):
        opcode, first, second, third, fourth = values[cursor : cursor + 5]
        cursor += 5
        if opcode == 0:
            row, column, value, reserved = first, second, third, fourth
            if (
                not 0 <= row < rows
                or not 0 <= column < columns
                or not MIN_CELL_VALUE <= value <= MAX_CELL_VALUE
                or reserved != 0
            ):
                return INVALID_RESULT
            matrix[row][column] = value
        elif opcode == 1:
            top, bottom, left, right = first, second, third, fourth
            if not 0 <= top <= bottom <= rows or not 0 <= left <= right <= columns:
                return INVALID_RESULT
            result = sum(
                matrix[row][column]
                for row in range(top, bottom)
                for column in range(left, right)
            )
            checksum += (operation_index + 1) * (result + CHECKSUM_OFFSET)
        else:
            return INVALID_RESULT

    if cursor != len(values):
        return INVALID_RESULT
    return checksum
