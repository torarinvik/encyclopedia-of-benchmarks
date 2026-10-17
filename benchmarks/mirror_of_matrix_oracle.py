"""Independent bounded oracle for horizontal matrix reflection."""

from __future__ import annotations

import struct
from collections.abc import Sequence

I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_DIMENSION = 1
MAX_DIMENSION = 16
MAX_INPUT_LENGTH = 2 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 4 * MAX_DIMENSION * MAX_DIMENSION
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (byte count, row-reversed matrix bytes), or the ABI sentinel."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 2
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT, b""

    rows, columns = values[:2]
    if not MIN_DIMENSION <= rows <= MAX_DIMENSION or not MIN_DIMENSION <= columns <= MAX_DIMENSION:
        return INVALID_RESULT, b""
    if len(values) != 2 + rows * columns:
        return INVALID_RESULT, b""

    cells = values[2:]
    if any(not I32_MIN <= cell <= I32_MAX for cell in cells):
        return INVALID_RESULT, b""
    if type(output_is_null) is not bool or type(output_capacity) is not int or output_capacity < 0:
        return INVALID_RESULT, b""
    if output_is_null:
        return OUTPUT_ERROR_RESULT, b""

    mirrored = [
        cells[row * columns + column]
        for row in range(rows)
        for column in range(columns - 1, -1, -1)
    ]
    output = b"".join(struct.pack("<i", cell) for cell in mirrored)
    if output_capacity < len(output):
        return OUTPUT_ERROR_RESULT, b""
    return len(output), output
