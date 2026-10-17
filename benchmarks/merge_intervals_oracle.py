"""Independent bounded oracle for Java/Python merge-interval semantics."""

from __future__ import annotations

import struct
from typing import Sequence

MAX_INTERVALS = 256
MIN_I32 = -(2**31)
MAX_I32 = 2**31 - 1
MAX_INPUT_LENGTH = 1 + 2 * MAX_INTERVALS
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_INTERVALS


def expected_output(
    values: Sequence[int],
    output_capacity: int = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
) -> tuple[int, bytes]:
    """Return (result, output bytes) for one bounded merge-interval call.

    Connected components of the interval-overlap graph produce the same closed
    union as sorting and sweeping, while giving the oracle an independent path
    to the reference result.
    """
    if (
        not isinstance(values, (tuple, list))
        or len(values) < 1
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not -(2**63) <= value < 2**63 for value in values)
    ):
        return -1, b""

    interval_count = values[0]
    if not 0 <= interval_count <= MAX_INTERVALS or len(values) != 1 + 2 * interval_count:
        return -1, b""

    intervals: list[tuple[int, int]] = []
    for index in range(interval_count):
        start = values[1 + 2 * index]
        end = values[2 + 2 * index]
        if not MIN_I32 <= start <= MAX_I32 or not MIN_I32 <= end <= MAX_I32 or start > end:
            return -1, b""
        intervals.append((start, end))

    if type(output_is_null) is not bool:
        return -1, b""
    if type(output_capacity) is not int or output_capacity < 0:
        return -1, b""
    if output_is_null:
        return -2, b""

    parent = list(range(interval_count))

    def find(node: int) -> int:
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    for left_index in range(interval_count):
        left_start, left_end = intervals[left_index]
        for right_index in range(left_index + 1, interval_count):
            right_start, right_end = intervals[right_index]
            if left_start <= right_end and right_start <= left_end:
                left_root = find(left_index)
                right_root = find(right_index)
                if left_root != right_root:
                    parent[right_root] = left_root

    components: dict[int, list[int]] = {}
    for index, (start, end) in enumerate(intervals):
        root = find(index)
        bounds = components.get(root)
        if bounds is None:
            components[root] = [start, end]
        else:
            bounds[0] = min(bounds[0], start)
            bounds[1] = max(bounds[1], end)

    merged = sorted((bounds[0], bounds[1]) for bounds in components.values())
    output = b"".join(struct.pack("<ii", start, end) for start, end in merged)
    if output_capacity < len(output):
        return -2, b""
    return len(output), output
