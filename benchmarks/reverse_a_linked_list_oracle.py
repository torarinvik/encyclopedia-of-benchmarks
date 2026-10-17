"""Independent array-reversal oracle for the bounded linked-list ABI."""
from __future__ import annotations

import struct

MAX_N = 128
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if not isinstance(values, (list, tuple)) or not values:
        return -1, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1, b""
    n = values[0]
    if n < 0 or n > MAX_N or len(values) != n + 1:
        return -1, b""
    if any(value < I32_MIN or value > I32_MAX for value in values[1:]):
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""

    encoded = b"".join(struct.pack("<i", value) for value in reversed(values[1:]))
    if output_is_null or (output_capacity is not None and output_capacity < len(encoded)):
        return -2, b""
    return len(encoded), encoded
