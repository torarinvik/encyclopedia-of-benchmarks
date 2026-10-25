"""Independent oracle for the bounded TSVC s171 affine-stride accumulation."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_STRIDE = 4
MAX_INPUT_LENGTH = 159
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
MIN_VALUE = -8
MAX_VALUE = 8


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the final A vector after one affine-stride update pass."""
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
    if input_is_null or values is None or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n, stride = values[:2]
    if not 1 <= n <= MAX_N or not 1 <= stride <= MAX_STRIDE:
        return -1, b""
    a_length = 1 + (n - 1) * stride
    if len(values) != 2 + a_length + n:
        return -1, b""
    initial_a = values[2:2 + a_length]
    b = values[2 + a_length:]
    if any(not MIN_VALUE <= value <= MAX_VALUE for value in (*initial_a, *b)):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * a_length:
        return -2, b""

    result = list(initial_a)
    for i, addend in enumerate(b):
        destination = i * stride
        result[destination] += addend
    return a_length, b"".join(struct.pack("<q", value) for value in result)
