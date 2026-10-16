"""Independent oracle for bounded batched difference-array range updates."""

from __future__ import annotations

import struct


MAX_LENGTH = 64
MAX_UPDATES = 64
MAX_INPUT_LENGTH = 2 + MAX_LENGTH + 3 * MAX_UPDATES
MAX_OUTPUT_BYTES = MAX_LENGTH * 8


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    """Return status and the final array as little-endian signed 64-bit values."""
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    length, update_count = values[:2]
    if not 1 <= length <= MAX_LENGTH or not 0 <= update_count <= MAX_UPDATES:
        return -1, b""
    if len(values) != 2 + length + 3 * update_count:
        return -1, b""
    result = list(values[2:2 + length])
    if any(not -1_000_000 <= item <= 1_000_000 for item in result):
        return -1, b""
    offset = 2 + length
    for index in range(update_count):
        left, right, delta = values[offset + 3 * index:offset + 3 * index + 3]
        if not 0 <= left <= right < length or not -1_000_000 <= delta <= 1_000_000:
            return -1, b""
        for position in range(left, right + 1):
            result[position] += delta

    if output_capacity is not None:
        if type(output_capacity) is not int or output_capacity < 0:
            return -1, b""
        if output_capacity < length * 8:
            return -2, b""
    output = b"".join(struct.pack("<q", value) for value in result)
    return len(output), output
