"""Oracle for the bounded adjacent-run compression benchmark."""

from __future__ import annotations

import struct

MAX_LENGTH = 64
MAX_INPUT_LENGTH = MAX_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_LENGTH * 4
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 1 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return -1, b""
    count = values[0]
    if not 0 <= count <= MAX_LENGTH or len(values) != count + 1:
        return -1, b""
    source = values[1:]
    if any(value < I32_MIN or value > I32_MAX for value in source):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""

    compressed: list[int] = []
    for value in source:
        if not compressed or value != compressed[-1]:
            compressed.append(value)
    encoded = b"".join(struct.pack("<i", value) for value in compressed)
    if output_capacity is not None and output_capacity < count * 4:
        return -2, b""
    return len(compressed), encoded
