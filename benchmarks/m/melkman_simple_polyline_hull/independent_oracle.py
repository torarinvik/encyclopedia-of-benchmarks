"""Sorted hull reference for the promised general-position polyline."""

from __future__ import annotations

from collections.abc import Sequence
import struct


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(input_is_null) is not bool or type(output_is_null) is not bool
            or input_is_null or not isinstance(values, (list, tuple))
            or not 7 <= len(values) <= 66
            or input_length is not None and (type(input_length) is not int or input_length != len(values))
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or any(type(v) is not int or v < -(1 << 63) or v >= (1 << 63) for v in values)):
        return -1, b""
    n = values[0]
    if not 3 <= n <= 32 or len(values) != 1 + 2 * n:
        return -1, b""
    if any(not -1000 <= x <= 1000 for x in values[1:]):
        return -1, b""
    points = [(values[1 + 2*i], values[2 + 2*i], i) for i in range(n)]
    if ((points[1][0] - points[0][0]) * (points[2][1] - points[0][1])
            == (points[1][1] - points[0][1]) * (points[2][0] - points[0][0])):
        return -1, b""
    points.sort()

    def cross(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

    lower, upper = [], []
    for point in points:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    for point in reversed(points):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    indices = [point[2] for point in lower[:-1] + upper[:-1]]
    payload = struct.pack("<" + "q" * len(indices), *indices)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
