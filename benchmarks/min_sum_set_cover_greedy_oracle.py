"""Greedy largest-uncovered-set-count oracle for min-sum set cover."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 12
MAX_M = 16
MAX_INPUT = 18
MAX_OUTPUT_BYTES = 8 * (MAX_N + 1)


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and
            (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 3 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values):
        return -1, b""
    n, set_count = values[:2]
    masks = values[2:]
    if (not 1 <= n <= MAX_N or not 1 <= set_count <= MAX_M
            or len(masks) != set_count or any(not 0 < mask < (1 << n) for mask in masks)):
        return -1, b""

    covered = [False] * set_count
    used = [False] * n
    order: list[int] = []
    total_time = 0
    for time in range(1, n + 1):
        chosen = -1
        best_count = -1
        for element in range(n):
            if used[element]:
                continue
            count = sum(not covered[index] and (mask >> element) & 1
                        for index, mask in enumerate(masks))
            if count > best_count:
                chosen, best_count = element, count
        used[chosen] = True
        order.append(chosen)
        for index, mask in enumerate(masks):
            if not covered[index] and (mask >> chosen) & 1:
                covered[index] = True
                total_time += time
    output = b"".join(struct.pack("<q", item) for item in (total_time, *order))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
