"""Independent oracle for the bounded TSVC s132 shifted-row update."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 2 + 3 * MAX_N
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
    """Return the updated target row as little-endian signed i64 bytes."""
    if (
        values is not None and not isinstance(values, (list, tuple))
        or type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or output_capacity is not None
        and (type(output_capacity) is not int or output_capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or input_length < 0 or input_length > MAX_INPUT_LENGTH)
    ):
        return -1, b""
    if input_is_null or values is None or not 8 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n = values[0]
    if not 2 <= n <= MAX_N or len(values) != 2 + 3 * n:
        return -1, b""
    row_start = 1
    target_start = row_start + n
    b_start = target_start + n
    c1 = values[b_start + n]
    target = list(values[target_start:b_start])
    row = values[row_start:target_start]
    b_values = values[b_start:b_start + n]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in (*row, *target, *b_values, c1)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""

    for i in range(1, n):
        target[i] = row[i - 1] + b_values[i] * c1
    return n, b"".join(struct.pack("<q", value) for value in target)
