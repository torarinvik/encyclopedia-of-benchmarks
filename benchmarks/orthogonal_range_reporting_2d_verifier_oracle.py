"""Brute-force rectangle verifier for the bounded 2D range-reporting profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_POINTS = 8
MAX_QUERIES = 8
MAX_INPUT = 50


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or not 0 <= input_length <= MAX_INPUT)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        if input_is_null and values not in (None, [], ()):
            return -1, b""
        return -1, b""
    if input_length is not None and input_length != len(values):
        return -1, b""
    if not 2 <= len(values) <= MAX_INPUT or any(type(value) is not int or not -(1 << 63) <= value <= (1 << 63) - 1 for value in values):
        return -1, b""
    n, q = values[0], values[1]
    if not 1 <= n <= MAX_POINTS or not 1 <= q <= MAX_QUERIES or len(values) != 2 + 2 * n + 4 * q:
        return -1, b""
    points = [(values[2 + 2 * i], values[3 + 2 * i]) for i in range(n)]
    if any(not 0 <= x <= 15 or not 0 <= y <= 15 for x, y in points) or len(set(points)) != n:
        return -1, b""
    start = 2 + 2 * n
    queries = [tuple(values[start + 4 * i:start + 4 * i + 4]) for i in range(q)]
    if any(not 0 <= low <= high <= 15 for x0, x1, y0, y1 in queries for low, high in ((x0, x1), (y0, y1))):
        return -1, b""
    words = [q]
    for x_low, x_high, y_low, y_high in queries:
        hits = [point_id for point_id, (x, y) in enumerate(points)
                if x_low <= x <= x_high and y_low <= y <= y_high]
        words.extend((len(hits), *sorted(hits)))
    payload = struct.pack("<" + "q" * len(words), *words)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
