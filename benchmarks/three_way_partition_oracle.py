"""Oracle for bounded Dutch national flag partitioning."""

from __future__ import annotations

import struct

MAX_COUNT = 256
MAX_INPUT_LENGTH = MAX_COUNT + 2
MAX_OUTPUT_BYTES = 4 * (MAX_COUNT + 2)
I32_MIN = -(2**31)
I32_MAX = 2**31 - 1


def expected_output(values: list[int] | tuple[int, ...], output_capacity: int | None = None) -> tuple[int, bytes]:
    if (not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)):
        return -1, b""
    count, pivot = values[:2]
    items = values[2:]
    if (not 0 <= count <= MAX_COUNT or len(items) != count
            or not I32_MIN <= pivot <= I32_MAX
            or any(not I32_MIN <= item <= I32_MAX for item in items)):
        return -1, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    partitioned = [*items]
    low = mid = 0
    high = count
    while mid < high:
        if partitioned[mid] < pivot:
            partitioned[low], partitioned[mid] = partitioned[mid], partitioned[low]
            low += 1
            mid += 1
        elif partitioned[mid] > pivot:
            high -= 1
            partitioned[mid], partitioned[high] = partitioned[high], partitioned[mid]
        else:
            mid += 1
    encoded = b"".join(struct.pack("<i", item) for item in partitioned + [low, high])
    if output_capacity is not None and output_capacity < len(encoded):
        return -2, b""
    return count + 2, encoded
