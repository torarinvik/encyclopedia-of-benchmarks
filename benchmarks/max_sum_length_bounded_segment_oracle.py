"""Prefix-minimum deque oracle for length-bounded maximum-sum segments."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_INPUT = 35
MAX_OUTPUT_BYTES = 24


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
    if len(values) < 4 or len(values) > MAX_INPUT or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values):
        return -1, b""
    n, lower, upper = values[:3]
    data = values[3:]
    if (not 1 <= n <= MAX_N or not 1 <= lower <= upper <= n
            or len(data) != n or any(not -10000 <= item <= 10000 for item in data)):
        return -1, b""

    prefix = [0]
    for item in data:
        prefix.append(prefix[-1] + item)
    queue: list[int] = []
    head = 0
    best_sum = 0
    best_start = 0
    best_end = 0
    have_best = False
    for end in range(lower, n + 1):
        added = end - lower
        while len(queue) > head and prefix[queue[-1]] > prefix[added]:
            queue.pop()
        queue.append(added)
        earliest = end - upper
        while head < len(queue) and queue[head] < earliest:
            head += 1
        start = queue[head]
        total = prefix[end] - prefix[start]
        if (not have_best or total > best_sum
                or total == best_sum and (start < best_start
                                         or start == best_start and end < best_end)):
            best_sum, best_start, best_end = total, start, end
            have_best = True

    output = b"".join(struct.pack("<q", item)
                      for item in (best_sum, best_start, best_end))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
