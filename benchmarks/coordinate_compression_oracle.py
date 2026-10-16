"""Independent bounded oracle for coordinate compression output bytes."""

from __future__ import annotations

import struct

I64_MIN = -(2**63)
I64_MAX = 2**63 - 1
I32_MIN = -(2**31)
I32_MAX = 2**31 - 1
MAX_N = 128
MAX_INPUT_LENGTH = MAX_N + 1
MAX_OUTPUT_LENGTH = MAX_N * 8
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2


def expected_output(values: tuple[int, ...] | list[int],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Return little-endian ranks in original order for a valid packed array."""
    if (not isinstance(values, (tuple, list)) or not values
            or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""

    n = values[0]
    if n < 0 or n > MAX_N or len(values) != n + 1:
        return INVALID_RESULT, b""

    original = values[1:]
    if any(value < I32_MIN or value > I32_MAX for value in original):
        return INVALID_RESULT, b""

    distinct_values = sorted(set(original))
    rank = {value: index for index, value in enumerate(distinct_values)}
    output = b"".join(struct.pack("<q", rank[value]) for value in original)
    if capacity is not None:
        if type(capacity) is not int or capacity < 0:
            return INVALID_RESULT, b""
        if len(output) > capacity:
            return INSUFFICIENT_CAPACITY, b""
    return len(output), output
