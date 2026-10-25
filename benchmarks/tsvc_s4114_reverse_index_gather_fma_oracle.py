"""Independent oracle for the bounded TSVC s4114 reverse-index gather map."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 257
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_VALUE = -2
MAX_VALUE = 2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return B[i] + C[n-1-IP[i]]*D[i] as little-endian signed i64 values."""
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
    if input_is_null or values is None or not 5 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 4 * n:
        return -1, b""
    ip = values[1:1 + n]
    b_offset = 1 + n
    c_offset = 1 + 2 * n
    d_offset = 1 + 3 * n
    b = values[b_offset:c_offset]
    c = values[c_offset:d_offset]
    d = values[d_offset:]
    if any(not 0 <= index < n for index in ip):
        return -1, b""
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in (*b, *c, *d)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""

    result = [
        b[i] + c[n - 1 - ip[i]] * d[i]
        for i in range(n)
    ]
    return n, b"".join(struct.pack("<q", value) for value in result)
