"""Bounded oracle for the pinned Java MatrixTranspose.transpose operation."""
from __future__ import annotations

MAX_ROWS = 32
MAX_COLS = 32
MAX_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLS
MAX_PARSEABLE_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (2 + MAX_ROWS * MAX_COLS)
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int], capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, list) or not 2 <= len(values) <= MAX_PARSEABLE_LENGTH
            or any(type(x) is not int or not I64_MIN <= x <= I64_MAX for x in values)):
        return -1, b""
    rows, cols = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= cols <= MAX_COLS or len(values) != 2 + rows * cols:
        return -1, b""
    cells = values[2:]
    if any(x < I32_MIN or x > I32_MAX for x in cells):
        return -1, b""
    output_values = [cols, rows]
    for c in range(cols):
        for r in range(rows):
            output_values.append(cells[r * cols + c])
    output = b"".join(x.to_bytes(8, "little", signed=True) for x in output_values)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return -1, b""
    if capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
