"""Independent oracle for the bounded TSVC s161 control-flow update."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 5 * MAX_N
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
    """Return final A and C vectors packed as little-endian signed i64s."""
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
    if input_is_null or values is None or not 11 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n = values[0]
    if not 2 <= n <= MAX_N or len(values) != 1 + 5 * n:
        return -1, b""
    a_start = 1
    b_start = a_start + n
    c_start = b_start + n
    d_start = c_start + n
    e_start = d_start + n
    a = list(values[a_start:b_start])
    b_values = values[b_start:c_start]
    c = list(values[c_start:d_start])
    d_values = values[d_start:e_start]
    e_values = values[e_start:]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in (*a, *b_values, *c, *d_values, *e_values)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 16 * n:
        return -2, b""

    for i in range(n - 1):
        if b_values[i] < 0:
            d = d_values[i]
            c[i + 1] = a[i] + d * d
        else:
            a[i] = c[i] + d_values[i] * e_values[i]
    result = (*a, *c)
    return 2 * n, b"".join(struct.pack("<q", value) for value in result)
