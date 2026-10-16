"""Reference model for the bounded integer Jarvis scan benchmark."""

from __future__ import annotations

import struct

INVALID_RESULT = -1
MAX_POINTS = 64
MIN_COORDINATE = -10_000
MAX_COORDINATE = 10_000
MAX_INPUT_LENGTH = 1 + 2 * MAX_POINTS
MAX_OUTPUT_BYTES = 16 * MAX_POINTS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def _orientation(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def expected_output(values: list[int] | tuple[int, ...]) -> tuple[int, bytes]:
    """Return a CCW hull vector, empty bytes for fewer than three points, or -1."""
    if (not isinstance(values, (list, tuple)) or not values
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)):
        return INVALID_RESULT, b""
    point_count = values[0]
    if (not 0 <= point_count <= MAX_POINTS
            or len(values) != 1 + 2 * point_count):
        return INVALID_RESULT, b""
    points = [(values[1 + 2 * index], values[2 + 2 * index])
              for index in range(point_count)]
    if any(not MIN_COORDINATE <= coordinate <= MAX_COORDINATE
           for point in points for coordinate in point):
        return INVALID_RESULT, b""
    if point_count <= 2:
        return 0, b""
    if len(set(points)) != point_count:
        return INVALID_RESULT, b""
    for first in range(point_count - 2):
        for second in range(first + 1, point_count - 1):
            for third in range(second + 1, point_count):
                if _orientation(points[first], points[second], points[third]) == 0:
                    return INVALID_RESULT, b""

    start = min(range(point_count), key=lambda index: (points[index][0], points[index][1]))
    hull: list[int] = []
    current = start
    while True:
        hull.append(current)
        candidate = (current + 1) % point_count
        for index in range(point_count):
            if _orientation(points[current], points[index], points[candidate]) > 0:
                candidate = index
        if candidate == start:
            break
        current = candidate
        if len(hull) >= point_count:
            return INVALID_RESULT, b""

    output = b"".join(struct.pack("<qq", *points[index]) for index in hull)
    return len(output), output
