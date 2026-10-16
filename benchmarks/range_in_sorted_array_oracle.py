"""Oracle for the pinned Java sorted-range search on bounded int32 arrays."""

from __future__ import annotations

import struct

MAX_ARRAY_LENGTH = 512
MAX_INPUT_LENGTH = MAX_ARRAY_LENGTH + 2
MAX_OUTPUT_BYTES = 8
INT32_MIN = -(2**31)
INT32_MAX = 2**31 - 1


def expected_output(values: tuple[int, ...] | list[int],
                    output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    count, *items_and_key = values
    if not 0 <= count <= MAX_ARRAY_LENGTH or len(items_and_key) != count + 1:
        return -1, b""
    items, key = items_and_key[:-1], items_and_key[-1]
    if (not INT32_MIN <= key <= INT32_MAX
            or any(not INT32_MIN <= item <= INT32_MAX for item in items)
            or any(left > right for left, right in zip(items, items[1:]))):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""

    positions = [index for index, item in enumerate(items) if item == key]
    result = (positions[0], positions[-1]) if positions else (-1, -1)
    output = struct.pack("<ii", *result)
    if output_capacity is not None and output_capacity < len(output):
        return -2, b""
    return len(output), output
