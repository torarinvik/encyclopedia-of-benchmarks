"""Independent oracle for three strictly increasing signed-i32 arrays."""

from __future__ import annotations

import struct

ARRAY_COUNT = 3
MAX_ARRAY_LENGTH = 64
MAX_INPUT_LENGTH = ARRAY_COUNT * (MAX_ARRAY_LENGTH + 1)
MAX_OUTPUT_BYTES = MAX_ARRAY_LENGTH * 4
I64_MIN, I64_MAX = -(2**63), 2**63 - 1
I32_MIN, I32_MAX = -(2**31), 2**31 - 1
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2


def expected_output(values: tuple[int, ...] | list[int],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Return ascending common values, or the contract sentinel and no bytes."""
    if (not isinstance(values, (tuple, list)) or not ARRAY_COUNT <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""

    arrays: list[tuple[int, ...]] = []
    position = 0
    for _ in range(ARRAY_COUNT):
        if position >= len(values) or not 0 <= values[position] <= MAX_ARRAY_LENGTH:
            return INVALID_RESULT, b""
        length = values[position]
        position += 1
        if length > len(values) - position:
            return INVALID_RESULT, b""
        array = tuple(values[position:position + length])
        if (any(value < I32_MIN or value > I32_MAX for value in array)
                or any(left >= right for left, right in zip(array, array[1:]))):
            return INVALID_RESULT, b""
        arrays.append(array)
        position += length
    if position != len(values):
        return INVALID_RESULT, b""
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""

    common = set(arrays[0]).intersection(arrays[1], arrays[2])
    maximum_output_bytes = min(map(len, arrays)) * 4
    if capacity is not None and capacity < maximum_output_bytes:
        return INSUFFICIENT_CAPACITY, b""
    output = b"".join(struct.pack("<i", value) for value in sorted(common))
    return len(common), output
