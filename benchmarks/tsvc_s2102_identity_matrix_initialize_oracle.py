"""Independent oracle for the bounded TSVC s2102 identity initialization."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_SIDE = 8
MAX_PASSES = 8
MAX_CELLS = MAX_SIDE * MAX_SIDE
MAX_INPUT_LENGTH = 2
MAX_OUTPUT_BYTES = 8 * MAX_CELLS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return (matrix element count, little-endian identity matrix), or status."""
    if (
        not isinstance(values, (list, tuple))
        or type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or input_length < 0 or input_length > MAX_INPUT_LENGTH)
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1, b""
    if input_is_null or len(values) != 2:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""

    side, passes = values
    if not 1 <= side <= MAX_SIDE or not 1 <= passes <= MAX_PASSES:
        return -1, b""
    cells = side * side
    if output_is_null or output_capacity is not None and output_capacity < 8 * cells:
        return -2, b""

    matrix = [[0 for _ in range(side)] for _ in range(side)]
    for _ in range(passes):
        for col in range(side):
            for row in range(side):
                matrix[row][col] = 0
            matrix[col][col] = 1
    flattened = [value for row in matrix for value in row]
    return cells, b"".join(struct.pack("<q", value) for value in flattened)
