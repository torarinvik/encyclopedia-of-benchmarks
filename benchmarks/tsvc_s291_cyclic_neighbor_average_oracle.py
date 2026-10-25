"""Independent oracle for a bounded TSVC s291 cyclic neighbor average."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 64
MAX_VALUE = 1_000_000
MAX_INPUT_LENGTH = 1 + MAX_N
MAX_OUTPUT_CAPACITY = 8 * MAX_N
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return twice each cyclic mean, preserving the exact half-step result."""
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

    n = values[0]
    if not 2 <= n <= MAX_N or len(values) != 1 + n:
        return -1, b""
    data = values[1:]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in data):
        return -1, b""
    required_capacity = 8 * n
    if output_is_null or output_capacity is not None and output_capacity < required_capacity:
        return -2, b""

    doubled_means = [data[i] + data[i - 1] for i in range(n)]
    return n, struct.pack("<" + "q" * n, *doubled_means)
