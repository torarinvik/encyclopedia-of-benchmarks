"""Melkman deque reference on promised simple general-position chains."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence
import struct


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (tuple, list))
            or not 7 <= len(values) <= 66
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(x) is not int or x < -(1 << 63) or x >= (1 << 63) for x in values)):
        return -1, b""
    n = values[0]
    if not 3 <= n <= 32 or len(values) != 1 + 2 * n:
        return -1, b""
    if any(not -1000 <= v <= 1000 for v in values[1:]):
        return -1, b""
    points = [(values[1 + 2 * i], values[2 + 2 * i]) for i in range(n)]

    def cross(a: int, b: int, c: int) -> int:
        return ((points[b][0] - points[a][0]) * (points[c][1] - points[a][1])
                - (points[b][1] - points[a][1]) * (points[c][0] - points[a][0]))

    initial_turn = cross(0, 1, 2)
    if initial_turn == 0:
        return -1, b""
    hull = deque((2, 0, 1, 2) if initial_turn > 0 else (2, 1, 0, 2))
    for i in range(3, n):
        if cross(hull[0], hull[1], i) > 0 and cross(hull[-2], hull[-1], i) > 0:
            continue
        while len(hull) >= 2 and cross(hull[0], hull[1], i) <= 0:
            hull.popleft()
        if len(hull) < 2:
            return -1, b""
        hull.appendleft(i)
        while len(hull) >= 2 and cross(hull[-2], hull[-1], i) <= 0:
            hull.pop()
        if len(hull) < 2:
            return -1, b""
        hull.append(i)
    vertices = list(hull)[:-1]
    first = min(range(len(vertices)), key=lambda i: points[vertices[i]])
    vertices = vertices[first:] + vertices[:first]
    payload = struct.pack("<" + "q" * len(vertices), *vertices)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
