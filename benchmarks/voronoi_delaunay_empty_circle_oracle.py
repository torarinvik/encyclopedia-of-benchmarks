"""Exact integer empty-circle oracle for bounded Delaunay construction."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 17
MAX_OUTPUT = 296


def _orient(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _incircle(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int], d: tuple[int, int]) -> int:
    ax, ay = a[0] - d[0], a[1] - d[1]
    bx, by = b[0] - d[0], b[1] - d[1]
    cx, cy = c[0] - d[0], c[1] - d[1]
    return ((ax * ax + ay * ay) * (bx * cy - by * cx)
            - (bx * bx + by * by) * (ax * cy - ay * cx)
            + (cx * cx + cy * cy) * (ax * by - ay * bx))


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
    if len(values) < 7 or len(values) > MAX_INPUT or any(type(x) is not int or not -(1 << 63) <= x < (1 << 63) for x in values):
        return -1, b""
    n = values[0]
    if not 3 <= n <= 8 or len(values) != 1 + 2 * n:
        return -1, b""
    points = [tuple(values[1 + 2 * i:3 + 2 * i]) for i in range(n)]
    if any(not -50 <= x <= 50 or not -50 <= y <= 50 for x, y in points) or len(set(points)) != n:
        return -1, b""
    if any(_orient(points[a], points[b], points[c]) == 0
           for a in range(n) for b in range(a + 1, n) for c in range(b + 1, n)):
        return -1, b""
    if any(_incircle(points[a], points[b], points[c], points[d]) == 0
           for a in range(n) for b in range(a + 1, n) for c in range(b + 1, n) for d in range(c + 1, n)):
        return -1, b""

    edges: set[tuple[int, int]] = set()
    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                orientation = _orient(points[a], points[b], points[c])
                if all(d in (a, b, c) or
                       not ((_incircle(points[a], points[b], points[c], points[d]) > 0) == (orientation > 0))
                       for d in range(n)):
                    edges.update(((a, b), (a, c), (b, c)))
    fields = [len(edges), *(vertex for edge in sorted(edges) for vertex in edge)]
    payload = b"".join(struct.pack("<q", field) for field in fields)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
