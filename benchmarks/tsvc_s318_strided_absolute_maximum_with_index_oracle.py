"""Independent oracle for a bounded TSVC s318 strided abs-argmax profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_STRIDE = 4
MAX_VALUE = 1_000_000
MAX_PHYSICAL_N = 1 + (MAX_N - 1) * MAX_STRIDE
MAX_INPUT_LENGTH = 2 + MAX_PHYSICAL_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return maximum sampled magnitude and its first logical sample index."""
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
    if input_is_null or values is None or not 3 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    n, stride = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= stride <= MAX_STRIDE:
        return -1, b""
    physical_n = 1 + (n - 1) * stride
    if len(values) != 2 + physical_n:
        return -1, b""
    data = values[2:]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in data):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 16:
        return -2, b""

    maximum = abs(data[0])
    maximum_index = 0
    for index in range(1, n):
        magnitude = abs(data[index * stride])
        if magnitude > maximum:
            maximum = magnitude
            maximum_index = index
    return 2, struct.pack("<qq", maximum, maximum_index)
