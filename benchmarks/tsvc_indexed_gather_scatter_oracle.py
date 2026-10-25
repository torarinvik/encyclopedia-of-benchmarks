"""Independent oracle for the bounded TSVC s491/s4113 indexed-update family."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 16
MAX_INPUT_LENGTH = 2 + 5 * MAX_N
MAX_OPERAND = 1_000_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the output count and packed final destination, or an error code."""
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
    if input_is_null or values is None:
        return -1, b""
    if not 6 <= len(values) <= MAX_INPUT_LENGTH:
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""

    mode, n = values[0], values[1]
    if mode not in (491, 4113) or not 1 <= n <= MAX_N:
        return -1, b""
    arrays_per_index = 5 if mode == 491 else 4
    if len(values) != 2 + arrays_per_index * n:
        return -1, b""

    index_start = 2
    a_start = index_start + n
    b_start = a_start + n
    c_start = b_start + n
    d_start = c_start + n
    indices = values[index_start:a_start]
    destination = list(values[a_start:b_start])
    b_values = values[b_start:c_start]
    c_values = values[c_start:d_start]
    d_values = values[d_start:d_start + n] if mode == 491 else ()
    if any(type(index) is not int or not 0 <= index < n for index in indices):
        return -1, b""
    operands = (*b_values, *c_values, *d_values)
    if any(not -MAX_OPERAND <= value <= MAX_OPERAND for value in operands):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < 8 * n:
        return -2, b""

    for i, index in enumerate(indices):
        if mode == 491:
            destination[index] = b_values[i] + c_values[i] * d_values[i]
        else:
            destination[index] = b_values[index] + c_values[i]
    return n, b"".join(struct.pack("<q", value) for value in destination)
