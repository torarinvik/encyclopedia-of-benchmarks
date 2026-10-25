"""Independent oracle for the bounded TSVC s319 coupled reductions."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_N
MAX_VALUE = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return A, B, and the combined sum as little-endian i64 values."""
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
    if input_is_null or values is None or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 3 * n:
        return -1, b""
    c_start = 1
    d_start = c_start + n
    e_start = d_start + n
    c = values[c_start:d_start]
    d = values[d_start:e_start]
    e = values[e_start:]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in (*c, *d, *e)):
        return -1, b""
    value_count = 2 * n + 1
    if output_is_null or output_capacity is not None and output_capacity < 8 * value_count:
        return -2, b""

    a = [c[i] + d[i] for i in range(n)]
    b = [c[i] + e[i] for i in range(n)]
    total = sum(a) + sum(b)
    output_values = (*a, *b, total)
    return value_count, b"".join(struct.pack("<q", value) for value in output_values)
