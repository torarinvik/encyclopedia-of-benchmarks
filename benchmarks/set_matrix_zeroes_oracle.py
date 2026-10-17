"""Oracle for TheAlgorithms/Python's bounded set-matrix-zeroes routine."""

from __future__ import annotations

import struct

MAX_ROWS = 8
MAX_COLUMNS = 8
MAX_VALID_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLUMNS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_ROWS * MAX_COLUMNS * 8
MIN_CELL = -1_000_000
MAX_CELL = 1_000_000
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return bytes written and the transformed row-major i64 matrix."""
    if (not isinstance(values, (tuple, list))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63
                   for value in values)):
        return INVALID_RESULT, b""

    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return INVALID_RESULT, b""
    if len(values) != 2 + rows * columns:
        return INVALID_RESULT, b""

    cells = list(values[2:])
    if any(not MIN_CELL <= value <= MAX_CELL for value in cells):
        return INVALID_RESULT, b""

    matrix = [cells[row * columns:(row + 1) * columns] for row in range(rows)]
    first_column_zero = False
    for row in range(rows):
        if matrix[row][0] == 0:
            first_column_zero = True
        for column in range(1, columns):
            if matrix[row][column] == 0:
                matrix[row][0] = 0
                matrix[0][column] = 0

    for row in range(1, rows):
        for column in range(1, columns):
            if matrix[row][0] == 0 or matrix[0][column] == 0:
                matrix[row][column] = 0

    if matrix[0][0] == 0:
        for column in range(columns):
            matrix[0][column] = 0
    if first_column_zero:
        for row in range(rows):
            matrix[row][0] = 0

    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < rows * columns * 8:
            return OUTPUT_ERROR, b""

    output = b"".join(struct.pack("<q", value) for row in matrix for value in row)
    return len(output), output
