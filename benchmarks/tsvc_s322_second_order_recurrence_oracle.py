"""Independent oracle for the bounded TSVC s322 second-order recurrence."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_N
MAX_OUTPUT_BYTES = 8 * MAX_N
MAX_VALUE = 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return final A values after one ascending in-place recurrence sweep."""
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
    if input_is_null or values is None or not 7 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n = values[0]
    if not 2 <= n <= MAX_N or len(values) != 1 + 3 * n:
        return -1, b""
    a_start = 1
    b_start = a_start + n
    c_start = b_start + n
    a = list(values[a_start:b_start])
    b = values[b_start:c_start]
    c = values[c_start:]
    if any(value not in (-1, 0, 1) for value in (*a, *b, *c)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""

    for i in range(2, n):
        a[i] += a[i - 1] * b[i] + a[i - 2] * c[i]
    return n, b"".join(struct.pack("<q", value) for value in a)
