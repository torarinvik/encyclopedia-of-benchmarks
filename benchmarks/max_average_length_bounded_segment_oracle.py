"""Exact bounded interval scan for maximum-average segments."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_INPUT = 35


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
    if len(values) < 4 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n, lower, upper = values[:3]
    data = values[3:]
    if not 1 <= n <= MAX_N or not 1 <= lower <= upper <= n or len(data) != n or any(not -10000 <= x <= 10000 for x in data):
        return -1, b""

    best: tuple[int, int, int, int] | None = None
    for start in range(n):
        total = 0
        for end in range(start + 1, min(n, start + upper) + 1):
            total += data[end - 1]
            length = end - start
            if length < lower:
                continue
            candidate = (total, length, start, end)
            if (best is None or total * best[1] > best[0] * length
                    or total * best[1] == best[0] * length
                    and (length < best[1] or (length == best[1]
                         and (start < best[2] or start == best[2] and end < best[3])))):
                best = candidate
    assert best is not None
    output = b"".join(struct.pack("<q", x) for x in best)
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
