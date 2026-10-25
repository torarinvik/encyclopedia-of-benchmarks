"""Independent oracle for the bounded TSVC s256 array-expansion profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_INPUT_LENGTH = 2 + MAX_N + 2 * MAX_N * MAX_N
MAX_OUTPUT_BYTES = 8 * (MAX_N + MAX_N * MAX_N)
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MAX_A0 = 1_000
MAX_FACTOR = 1_000
MAX_C0 = 1_000_000


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
    if input_is_null:
        return -1, b""
    if not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""

    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 2 + n + 2 * n * n:
        return -1, b""
    a0 = values[1]
    if not -MAX_A0 <= a0 <= MAX_A0:
        return -1, b""
    d_start = 2
    bb_start = d_start + n
    c_start = bb_start + n * n
    factors = values[d_start:c_start]
    c_initial = values[c_start:]
    if any(not -MAX_FACTOR <= value <= MAX_FACTOR for value in factors):
        return -1, b""
    if any(not -MAX_C0 <= value <= MAX_C0 for value in c_initial):
        return -1, b""

    required_capacity = 8 * (n + n * n)
    if output_is_null or output_capacity is not None and output_capacity < required_capacity:
        return -2, b""

    d_values = values[d_start:bb_start]
    bb_values = values[bb_start:c_start]
    a = [0] * n
    a[0] = a0
    c = list(c_initial)
    for column in range(n):
        for row in range(1, n):
            a[row] = 1 - a[row - 1]
            index = row * n + column
            c[index] = a[row] + bb_values[index] * d_values[row]

    result = a + c
    output = b"".join(struct.pack("<q", value) for value in result)
    return len(result), output
