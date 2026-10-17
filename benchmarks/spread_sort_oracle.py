"""Independent sorted-array oracle for the bounded Integer SpreadSort adapter."""
from __future__ import annotations

import struct

MAX_LENGTH = 128
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def expected_output(
    values: list[int] | tuple[int, ...],
    output_capacity: int | None = None,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or any(value < I32_MIN or value > I32_MAX for value in values)
    ):
        return -1, b""
    if type(output_is_null) is not bool:
        return -1, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return -1, b""

    ordered = sorted(values)
    encoded = b"".join(struct.pack("<i", value) for value in ordered)
    if output_is_null:
        return (0, b"") if not encoded else (-2, b"")
    if output_capacity is not None and output_capacity < len(encoded):
        return -2, b""
    return len(encoded), encoded
