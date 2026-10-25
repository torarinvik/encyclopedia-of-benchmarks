"""Independent oracle for the bounded McCat 09-vor hull-contraction core."""

from __future__ import annotations

import math
from collections.abc import Sequence

MIN_SITES = 3
MAX_SITES = 8
COORD_LIMIT = 4
MAX_INPUT_LENGTH = 17
CENTER_OFFSET = 1024
CENTER_WIDTH = 2049
RADIUS_RADIX = 200_000
INVALID_RESULT = -1


def _cross(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> int:
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])


def _circumcenter(a: tuple[int, int], b: tuple[int, int], c: tuple[int, int]) -> tuple[float, float]:
    # Solve the equal-distance linear equations directly, independently of the
    # source's intersection-of-bisectors construction.
    bx, by = b[0] - a[0], b[1] - a[1]
    cx, cy = c[0] - a[0], c[1] - a[1]
    rhs_b = (b[0] * b[0] + b[1] * b[1] - a[0] * a[0] - a[1] * a[1]) / 2.0
    rhs_c = (c[0] * c[0] + c[1] * c[1] - a[0] * a[0] - a[1] * a[1]) / 2.0
    determinant = bx * cy - by * cx
    return ((rhs_b * cy - by * rhs_c) / determinant,
            (bx * rhs_c - rhs_b * cx) / determinant)


def _hull(points: list[tuple[int, int]]) -> list[tuple[int, int]]:
    ordered = sorted(points)
    lower: list[tuple[int, int]] = []
    for point in ordered:
        while len(lower) >= 2 and _cross(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    upper: list[tuple[int, int]] = []
    for point in reversed(ordered):
        while len(upper) >= 2 and _cross(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    return lower[:-1] + upper[:-1]


def _priority(hull: list[tuple[int, int]], index: int) -> tuple[float, float]:
    previous = hull[(index - 1) % len(hull)]
    current = hull[index]
    following = hull[(index + 1) % len(hull)]
    center = _circumcenter(previous, current, following)
    dx, dy = current[0] - center[0], current[1] - center[1]
    ax, ay = previous[0] - current[0], previous[1] - current[1]
    bx, by = following[0] - current[0], following[1] - current[1]
    dot = ax * bx + ay * by
    cosine2 = (dot * dot) / ((ax * ax + ay * ay) * (bx * bx + by * by))
    return dx * dx + dy * dy, -cosine2 if dot < 0 else cosine2


def _circle(final_triangle: list[tuple[int, int]]) -> tuple[int, int, int]:
    a, b, c = final_triangle
    sides = [((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2, 0, 1),
             ((b[0] - c[0]) ** 2 + (b[1] - c[1]) ** 2, 1, 2),
             ((a[0] - c[0]) ** 2 + (a[1] - c[1]) ** 2, 0, 2)]
    longest, first, second = max(sides, key=lambda item: item[0])
    opposite = ({0, 1, 2} - {first, second}).pop()
    triangle = [a, b, c]
    u, v, vertex = triangle[first], triangle[second], triangle[opposite]
    dot = ((u[0] - vertex[0]) * (v[0] - vertex[0])
           + (u[1] - vertex[1]) * (v[1] - vertex[1]))
    if dot < 0:
        center = ((u[0] + v[0]) / 2.0, (u[1] + v[1]) / 2.0)
        radius = math.sqrt(longest) / 2.0
    else:
        center = _circumcenter(a, b, c)
        radius = math.hypot(a[0] - center[0], a[1] - center[1])
    return math.trunc(center[0]), math.trunc(center[1]), math.floor(radius * 100.0 + 0.5)


def _decode(values: Sequence[int]) -> list[tuple[int, int]] | None:
    if not 7 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    count = values[0]
    if type(count) is not int or not MIN_SITES <= count <= MAX_SITES or len(values) != 1 + 2 * count:
        return None
    points: list[tuple[int, int]] = []
    for index in range(count):
        x, y = values[1 + 2 * index:3 + 2 * index]
        if not -COORD_LIMIT <= x <= COORD_LIMIT or not -COORD_LIMIT <= y <= COORD_LIMIT:
            return None
        point = (x, y)
        if point in points:
            return None
        points.append(point)
    for i in range(count):
        for j in range(i + 1, count):
            for k in range(j + 1, count):
                if _cross(points[i], points[j], points[k]) == 0:
                    return None
    return points


def expected_output(values: Sequence[int] | None,
                    input_length: int | None = None,
                    input_is_null: bool = False) -> int:
    if type(input_is_null) is not bool:
        return INVALID_RESULT
    if (input_is_null or values is None or not isinstance(values, (list, tuple))
            or len(values) > MAX_INPUT_LENGTH
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    points = _decode(values)
    if points is None:
        return INVALID_RESULT
    hull = _hull(points)
    if len(hull) < 3:
        return INVALID_RESULT
    while len(hull) > 3:
        keys = [_priority(hull, index) for index in range(len(hull))]
        if any(keys[i] == keys[j] for i in range(len(keys)) for j in range(i)):
            return INVALID_RESULT
        best = max(range(len(hull)), key=lambda index: (keys[index][0], -keys[index][1]))
        hull.pop(best)
    cx, cy, radius_cents = _circle(hull)
    if (not -CENTER_OFFSET <= cx <= CENTER_OFFSET
            or not -CENTER_OFFSET <= cy <= CENTER_OFFSET
            or not 0 <= radius_cents < RADIUS_RADIX):
        return INVALID_RESULT
    return ((cx + CENTER_OFFSET) * CENTER_WIDTH + (cy + CENTER_OFFSET)) * RADIUS_RADIX + radius_cents
