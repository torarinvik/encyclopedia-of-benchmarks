"""Independent exhaustive subset oracle for precedence-chain selection."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 65


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 5 or len(values) > MAX_INPUT or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 16 or len(values) != 1 + 4 * n:
        return -1, b""
    intervals = [tuple(values[1 + 4 * i:1 + 4 * (i + 1)]) for i in range(n)]
    if any(not (0 <= a < b < c < d <= 63) for a, b, c, d in intervals):
        return -1, b""

    best: tuple[int, ...] = ()
    for mask in range(1, 1 << n):
        selected = [i for i in range(n) if mask >> i & 1]
        selected.sort(key=lambda i: (intervals[i][0], intervals[i][1], intervals[i][2], intervals[i][3], i))
        valid = True
        for left, right in zip(selected, selected[1:]):
            if not (intervals[left][1] < intervals[right][0]
                    and intervals[left][3] < intervals[right][2]):
                valid = False
                break
        candidate = tuple(selected)
        if valid and (len(candidate) > len(best) or len(candidate) == len(best) and candidate < best):
            best = candidate
    fields = [len(best), *best]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
