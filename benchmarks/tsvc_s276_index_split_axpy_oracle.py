"""Independent oracle for the bounded TSVC s276 index-split AXPY."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_PASSES = 8
MAX_INPUT_LENGTH = 2 + 4 * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return `(element_count, little_endian_output)` or a negative status."""
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
    if input_is_null or not 6 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""

    n, passes = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= passes <= MAX_PASSES:
        return -1, b""
    if len(values) != 2 + 4 * n or any(value < -2 or value > 2 for value in values[2:]):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""

    a_start = 2
    b_start = a_start + n
    c_start = b_start + n
    d_start = c_start + n
    mid = n // 2
    a = list(values[a_start:b_start])
    b = values[b_start:c_start]
    c = values[c_start:d_start]
    d = values[d_start:]
    for _ in range(passes):
        for i in range(n):
            coefficient = c[i] if i + 1 < mid else d[i]
            a[i] += b[i] * coefficient
    return n, b"".join(struct.pack("<q", value) for value in a)
