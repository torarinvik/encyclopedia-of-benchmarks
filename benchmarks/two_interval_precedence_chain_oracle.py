"""Primary exact-output oracle for the precedence-only 2-interval model."""

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
    if len(values) < 5 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    if not 1 <= n <= 16 or len(values) != 1 + 4 * n:
        return -1, b""
    items = [tuple(values[1 + 4 * i:1 + 4 * (i + 1)]) for i in range(n)]
    if any(not (0 <= a < b < c < d <= 63) for a, b, c, d in items):
        return -1, b""

    order = sorted(range(n), key=lambda i: (*items[i], i))
    paths: list[tuple[int, ...]] = []
    for position, item in enumerate(order):
        best = (item,)
        a1, b1, a2, b2 = items[item]
        for earlier in range(position):
            prev = order[earlier]
            pa1, pb1, pa2, pb2 = items[prev]
            if pb1 < a1 and pb2 < a2:
                candidate = paths[earlier] + (item,)
                if len(candidate) > len(best) or len(candidate) == len(best) and candidate < best:
                    best = candidate
        paths.append(best)
    answer = min((path for path in paths if len(path) == max(map(len, paths))), default=(order[0],))
    fields = [len(answer), *answer]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
