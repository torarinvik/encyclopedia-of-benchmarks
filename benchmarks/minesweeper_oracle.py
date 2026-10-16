"""Independent bounded oracle for rectangular Minesweeper neighbor counts."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MIN_DIMENSION = 1
MAX_DIMENSION = 32
MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION
MAX_INPUT_LENGTH = 2 + MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH
MAX_OUTPUT_BYTES = 8 + 8 * MAX_CELLS
INVALID_RESULT = -1
CAPACITY_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    rows, cols = values[:2]
    if not MIN_DIMENSION <= rows <= MAX_DIMENSION or not MIN_DIMENSION <= cols <= MAX_DIMENSION:
        return INVALID_RESULT, b""
    if len(values) != 2 + rows * cols:
        return INVALID_RESULT, b""
    cells = list(values[2:])
    if any(cell not in (0, 1) for cell in cells):
        return INVALID_RESULT, b""
    result = [0] * (rows * cols)
    for row in range(rows):
        for col in range(cols):
            count = 0
            for neighbor_row in range(max(0, row - 1), min(rows, row + 2)):
                for neighbor_col in range(max(0, col - 1), min(cols, col + 2)):
                    if (neighbor_row != row or neighbor_col != col) and cells[neighbor_row * cols + neighbor_col] == 1:
                        count += 1
            result[row * cols + col] = count
    output = struct.pack("<q", rows * cols) + b"".join(struct.pack("<q", value) for value in result)
    if capacity is not None and (type(capacity) is not int or capacity < len(output)):
        return CAPACITY_ERROR, b""
    return len(output), output


def expected_result(values: Sequence[int], capacity: int | None = None) -> tuple[int, bytes]:
    return expected_output(values, capacity)
