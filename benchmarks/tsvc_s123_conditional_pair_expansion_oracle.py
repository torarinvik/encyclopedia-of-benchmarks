"""Independent oracle for the bounded TSVC s123 conditional expansion."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_INPUT_LENGTH = 1 + 4 * MAX_N
MAX_OUTPUT_BYTES = 16 * MAX_N
MAX_VALUE = 100
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the source-ordered one-or-two outputs per input as little-endian i64."""
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
    b = values[1:1 + n]
    c = values[1 + n:1 + 2 * n]
    d = values[1 + 2 * n:1 + 3 * n]
    e = values[1 + 3 * n:]
    if any(value < -MAX_VALUE or value > MAX_VALUE for value in (*b, *c, *d, *e)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 16 * n:
        return -2, b""

    result: list[int] = []
    for i in range(n):
        product = d[i] * e[i]
        result.append(b[i] + product)
        if c[i] > 0:
            result.append(c[i] + product)
    return len(result), b"".join(struct.pack("<q", value) for value in result)
