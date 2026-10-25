"""Independent oracle for the bounded TSVC s152 three-factor update."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_PASSES = 32
MAX_INPUT_LENGTH = 2 + 4 * MAX_N
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
    """Return the final A vector as little-endian signed i64 values."""
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
    if input_is_null or values is None or not 6 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n, passes = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= passes <= MAX_PASSES or len(values) != 2 + 4 * n:
        return -1, b""
    a_start = 2
    c_start = a_start + n
    d_start = c_start + n
    e_start = d_start + n
    a = list(values[a_start:c_start])
    c_values = values[c_start:d_start]
    d_values = values[d_start:e_start]
    e_values = values[e_start:]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in (*a, *c_values, *d_values, *e_values)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""

    for _ in range(passes):
        for i in range(n):
            temporary = d_values[i] * e_values[i]
            a[i] += temporary * c_values[i]
    return n, b"".join(struct.pack("<q", value) for value in a)
