"""Independent bounded oracle for the Java two-heap MedianFinder."""

from __future__ import annotations

import struct

MAX_COUNT = 64
MIN_VALUE = -1_000_000
MAX_VALUE = 1_000_000
MAX_INPUT_LENGTH = MAX_COUNT + 1
MAX_OUTPUT_BYTES = MAX_COUNT * 8
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY_RESULT = -2
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_output(values: list[int] | tuple[int, ...],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return every prefix median as little-endian binary64 bytes, or an ABI status."""
    if (not isinstance(values, (list, tuple)) or len(values) < 2
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return INVALID_RESULT, b""

    count = values[0]
    if (not 1 <= count <= MAX_COUNT or len(values) != count + 1
            or any(value < MIN_VALUE or value > MAX_VALUE for value in values[1:])):
        return INVALID_RESULT, b""

    required = count * 8
    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return INVALID_RESULT, b""
        if output_capacity < required:
            return INSUFFICIENT_CAPACITY_RESULT, b""

    prefix: list[int] = []
    output = bytearray()
    for value in values[1:]:
        prefix.append(value)
        ordered = sorted(prefix)
        middle = len(ordered) // 2
        if len(ordered) % 2:
            median = float(ordered[middle])
        else:
            median = (ordered[middle - 1] + ordered[middle]) / 2.0
        output.extend(struct.pack("<d", median))
    return len(output), bytes(output)
