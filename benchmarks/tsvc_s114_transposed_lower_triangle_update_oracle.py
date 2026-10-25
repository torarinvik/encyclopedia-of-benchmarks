"""Independent oracle for the bounded TSVC s114 triangular update."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_INPUT_LENGTH = 1 + 2 * MAX_N * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N * MAX_N
MAX_VALUE = 1_000_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return updated row-major A as little-endian i64 values."""
    if (
        values is not None and not isinstance(values, (list, tuple))
        or type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT_LENGTH)
    ):
        return -1, b""
    if input_is_null or values is None or not 9 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n = values[0]
    if not 2 <= n <= MAX_N:
        return -1, b""
    cells = n * n
    if len(values) != 1 + 2 * cells:
        return -1, b""
    a = list(values[1:1 + cells])
    b = values[1 + cells:]
    if any(value < -MAX_VALUE or value > MAX_VALUE for value in (*a, *b)):
        return -1, b""
    output_bytes = 8 * cells
    if output_is_null or output_capacity is not None and output_capacity < output_bytes:
        return -2, b""

    # This is a separate row-major oracle for the transposed source read.
    for row in range(n):
        for column in range(row):
            target = row * n + column
            transpose_source = column * n + row
            a[target] = a[transpose_source] + b[target]
    return cells, b"".join(struct.pack("<q", value) for value in a)
