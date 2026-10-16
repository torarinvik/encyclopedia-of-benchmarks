"""Independent bounded ASCII oracle for source-style string compression."""

from __future__ import annotations

MAX_INPUT_LENGTH = 64
MAX_OUTPUT_LENGTH = 64
INVALID_RESULT = -1
INSUFFICIENT_CAPACITY = -2


def expected_output(values: tuple[int, ...] | list[int],
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Encode adjacent ASCII runs as their byte plus an optional decimal count."""
    if (not isinstance(values, (tuple, list)) or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not 0 <= value <= 127 for value in values)):
        return INVALID_RESULT, b""

    output = bytearray()
    index = 0
    while index < len(values):
        end = index + 1
        while end < len(values) and values[end] == values[index]:
            end += 1
        count = end - index
        output.append(values[index])
        if count > 1:
            output.extend(str(count).encode("ascii"))
        index = end

    encoded = bytes(output)
    if capacity is not None and (type(capacity) is not int or capacity < 0):
        return INVALID_RESULT, b""
    if capacity is not None and len(encoded) > capacity:
        return INSUFFICIENT_CAPACITY, b""
    return len(encoded), encoded
