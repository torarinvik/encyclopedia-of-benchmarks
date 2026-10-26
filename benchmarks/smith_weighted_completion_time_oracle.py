"""Exact-ratio Smith-rule oracle for one-machine weighted completion time."""

from __future__ import annotations

import struct
from collections.abc import Sequence
from functools import cmp_to_key

MAX_N = 12
MAX_INPUT = 25


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
    if len(values) < 3 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    jobs = [tuple(values[1 + 2*i:3 + 2*i]) for i in range(n)] if 1 <= n <= MAX_N else []
    if not 1 <= n <= MAX_N or len(values) != 1 + 2*n or any(not 1 <= p <= 10000 or not 1 <= w <= 10000 for p, w in jobs):
        return -1, b""

    def compare(a: int, b: int) -> int:
        left = jobs[a][1] * jobs[b][0]
        right = jobs[b][1] * jobs[a][0]
        return -1 if left > right else 1 if left < right else (a > b) - (a < b)

    order = sorted(range(n), key=cmp_to_key(compare))
    elapsed = total = 0
    for job in order:
        elapsed += jobs[job][0]
        total += jobs[job][1] * elapsed
    output = b"".join(struct.pack("<q", x) for x in (total, *order))
    if output_is_null or capacity is not None and capacity < len(output):
        return -2, b""
    return len(output), output
